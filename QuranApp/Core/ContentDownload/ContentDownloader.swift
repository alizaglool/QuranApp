//
//  ContentDownloader.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation
import Combine
import UIKit
import Network

// MARK: - Failure

enum ContentDownloadFailure: Equatable {
    case unavailable
    case noSpace
    case corrupt
    case transfer
}

// MARK: - State

enum ContentDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case installing
    case downloaded
    case failed(ContentDownloadFailure)

    var isBusy: Bool {
        switch self {
        case .downloading, .installing: return true
        default:                        return false
        }
    }
}

// MARK: - Failure mapping

protocol ContentDownloadFailureConvertible: Error {
    var contentDownloadFailure: ContentDownloadFailure { get }
}

// MARK: - Transfer rejection

enum ContentTransferError: LocalizedError {
    case unexpectedStatus(Int)
    case declaredSizeMismatch(expected: Int, received: Int64)

    var errorDescription: String? {
        switch self {
        case let .unexpectedStatus(code):
            return "Content archive request answered with status \(code)"
        case let .declaredSizeMismatch(expected, received):
            return "Content archive is \(received) bytes but the catalog declares \(expected)"
        }
    }
}

extension ContentTransferError: ContentDownloadFailureConvertible {

    var contentDownloadFailure: ContentDownloadFailure {
        switch self {
        case .unexpectedStatus:     return .unavailable
        case .declaredSizeMismatch: return .corrupt
        }
    }
}

// MARK: - Request

struct ContentDownloadRequest: Equatable, Codable {
    let key: String
    let remoteURL: URL
    let archiveSizeBytes: Int
    let archiveSha256: String
}

// MARK: - Downloader

final class ContentDownloader: NSObject, ObservableObject {

    typealias StagedInstall = (ContentDownloadRequest, URL, URL) throws -> URL
    typealias CancellableStagedInstall = (ContentDownloadRequest, URL, URL, () -> Bool) throws -> URL
    typealias InstallationCheck = (URL) -> Bool
    typealias VolumeCapacityProbe = (URL) -> Int64?

    @Published private(set) var states: [String: ContentDownloadState] = [:]
    @Published private(set) var waitingKeys: Set<String> = []

    static let transferShare = 0.9
    private static let spaceMargin: Int64 = 32 * 1024 * 1024
    private static let pendingFileName = "pending_downloads.json"
    private static let receiptFileName = ".content_receipt"
    private static let retiredDirectoryName = "__retired"

    private let fileManager: FileManager
    private let contentRoot: URL
    private let stagingRoot: URL
    private let sessionIdentifier: String?
    private let stage: CancellableStagedInstall
    private let isInstalled: InstallationCheck
    private let availableCapacity: VolumeCapacityProbe

    private let installQueue: DispatchQueue
    private let lock = NSLock()
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var pendingRequests: [String: ContentDownloadRequest] = [:]
    private var cancelledInstalls: Set<String> = []
    private var rejections: [String: ContentDownloadFailure] = [:]
    private var isMonitoringPath = false
    private let pathMonitor = NWPathMonitor()

    private lazy var session: URLSession = {
        let configuration: URLSessionConfiguration
        if let sessionIdentifier {
            configuration = .background(withIdentifier: sessionIdentifier)
            configuration.isDiscretionary = false
            configuration.sessionSendsLaunchEvents = true
        } else {
            configuration = .default
            configuration.timeoutIntervalForResource = 600
        }
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    // MARK: - Life cycle

    init(contentRoot: URL,
         stagingRoot: URL,
         queueLabel: String,
         sessionIdentifier: String? = nil,
         excludedFromBackup: Bool = false,
         fileManager: FileManager = .default,
         availableCapacity: @escaping VolumeCapacityProbe = ContentDownloader.volumeCapacity,
         isInstalled: @escaping InstallationCheck,
         cancellableStage: @escaping CancellableStagedInstall) {
        self.fileManager = fileManager
        self.contentRoot = contentRoot
        self.stagingRoot = stagingRoot
        self.sessionIdentifier = sessionIdentifier
        self.installQueue = DispatchQueue(label: queueLabel, qos: .utility)
        self.availableCapacity = availableCapacity
        self.isInstalled = isInstalled
        self.stage = cancellableStage
        super.init()

        try? fileManager.createDirectory(at: contentRoot, withIntermediateDirectories: true)
        if excludedFromBackup { excludeFromBackup(contentRoot) }

        if sessionIdentifier == nil {
            clearStaging()
        } else {
            try? fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
            excludeFromBackup(stagingRoot)
            loadPending()
        }
    }

    convenience init(contentRoot: URL,
                     stagingRoot: URL,
                     queueLabel: String,
                     sessionIdentifier: String? = nil,
                     excludedFromBackup: Bool = false,
                     fileManager: FileManager = .default,
                     availableCapacity: @escaping VolumeCapacityProbe = ContentDownloader.volumeCapacity,
                     isInstalled: @escaping InstallationCheck,
                     stage: @escaping StagedInstall) {
        self.init(contentRoot: contentRoot,
                  stagingRoot: stagingRoot,
                  queueLabel: queueLabel,
                  sessionIdentifier: sessionIdentifier,
                  excludedFromBackup: excludedFromBackup,
                  fileManager: fileManager,
                  availableCapacity: availableCapacity,
                  isInstalled: isInstalled,
                  cancellableStage: { request, archive, staging, _ in
                      try stage(request, archive, staging)
                  })
    }

    // MARK: - Paths

    func directory(forKey key: String) -> URL {
        contentRoot.appendingPathComponent(key, isDirectory: true)
    }

    // MARK: - Status

    func isDownloaded(_ key: String) -> Bool {
        isInstalled(directory(forKey: key))
    }

    func installedChecksum(_ key: String) -> String? {
        guard let data = try? Data(contentsOf: receiptURL(forKey: key)),
              let value = String(data: data, encoding: .utf8) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func isCurrent(_ request: ContentDownloadRequest) -> Bool {
        guard isDownloaded(request.key),
              let installed = installedChecksum(request.key) else { return false }
        return installed.caseInsensitiveCompare(request.archiveSha256) == .orderedSame
    }

    func state(forKey key: String) -> ContentDownloadState {
        if let live = states[key], live.isBusy { return live }
        if isDownloaded(key) { return .downloaded }
        if let known = states[key] { return known }
        return .notDownloaded
    }

    func state(for request: ContentDownloadRequest) -> ContentDownloadState {
        if let live = states[request.key], live.isBusy { return live }
        if isCurrent(request) { return .downloaded }
        if let known = states[request.key], known != .downloaded { return known }
        return .notDownloaded
    }

    func markFailed(_ failure: ContentDownloadFailure, for key: String) {
        report(.failed(failure), for: key)
    }

    func isWaitingForNetwork(_ key: String) -> Bool {
        waitingKeys.contains(key)
    }

    func installedKeys() -> [String] {
        guard let names = try? fileManager.contentsOfDirectory(atPath: contentRoot.path) else { return [] }
        return names.filter { isInstalled(contentRoot.appendingPathComponent($0, isDirectory: true)) }.sorted()
    }

    func installedSize(of key: String) -> Int64 {
        size(of: directory(forKey: key))
    }

    func totalInstalledSize() -> Int64 {
        size(of: contentRoot)
    }

    // MARK: - Transfer

    func download(_ request: ContentDownloadRequest) {
        guard !isCurrent(request) else {
            report(.downloaded, for: request.key)
            return
        }

        lock.lock()
        let alreadyRunning = activeTasks[request.key] != nil
        if !alreadyRunning {
            cancelledInstalls.remove(request.key)
            pendingRequests[request.key] = request
        }
        let snapshot = pendingRequests
        lock.unlock()

        guard !alreadyRunning else { return }

        guard hasRoom(for: request) else {
            lock.lock()
            pendingRequests.removeValue(forKey: request.key)
            let remaining = pendingRequests
            lock.unlock()

            savePending(remaining)
            report(.failed(.noSpace), for: request.key)
            return
        }

        savePending(snapshot)
        report(.downloading(progress: 0), for: request.key)

        let task = session.downloadTask(with: request.remoteURL)
        task.taskDescription = request.key

        lock.lock()
        activeTasks[request.key] = task
        lock.unlock()

        task.resume()
        startPathMonitor()
        refreshWaiting()
    }

    func cancel(key: String) {
        lock.lock()
        let task = activeTasks.removeValue(forKey: key)
        pendingRequests.removeValue(forKey: key)
        rejections.removeValue(forKey: key)
        cancelledInstalls.insert(key)
        let snapshot = pendingRequests
        lock.unlock()

        task?.cancel()
        savePending(snapshot)
        clearStaging(for: key)
        clearWaiting(key)
        report(.notDownloaded, for: key)
    }

    func delete(key: String) {
        cancel(key: key)
        try? fileManager.removeItem(at: directory(forKey: key))
        report(.notDownloaded, for: key)
    }

    func deleteAll(except keptKeys: Set<String> = []) {
        for key in installedKeys() where !keptKeys.contains(key) {
            delete(key: key)
        }
    }

    func resumeInterrupted() {
        lock.lock()
        let waiting = pendingRequests.values.filter { activeTasks[$0.key] == nil }
        lock.unlock()

        session.getAllTasks { [weak self] tasks in
            guard let self else { return }
            let running = Set(tasks.compactMap(\.taskDescription))
            for request in waiting where !running.contains(request.key) {
                self.download(request)
            }
        }
    }

    // MARK: - Install

    private func install(_ request: ContentDownloadRequest, from archive: URL) {
        report(.installing, for: request.key)

        installQueue.async { [weak self] in
            guard let self else { return }
            let outcome = self.performInstall(request, from: archive)
            self.settle(request.key, as: outcome)
        }
    }

    func performInstall(_ request: ContentDownloadRequest, from archive: URL) -> ContentDownloadState {
        defer { clearStaging(for: request.key) }

        do {
            try throwIfCancelled(request.key)
            let digest = try AthkarArchive.sha256(ofFileAt: archive)
            try AthkarArchive.verify(digest: digest, matches: request.archiveSha256)

            try throwIfCancelled(request.key)

            let staged = try stage(request, archive, staging(for: request.key)) {
                self.isCancelled(request.key)
            }

            try throwIfCancelled(request.key)

            guard isInstalled(staged) else { return .failed(.unavailable) }

            try fileManager.createDirectory(at: contentRoot, withIntermediateDirectories: true)
            try swapIntoPlace(staged, forKey: request.key)
            try writeReceipt(request.archiveSha256, forKey: request.key)

            return .downloaded
        } catch is CancellationError {
            return .notDownloaded
        } catch {
            return .failed(Self.failure(for: error))
        }
    }

    private func swapIntoPlace(_ staged: URL, forKey key: String) throws {
        let destination = directory(forKey: key)
        let retired = staging(for: key).appendingPathComponent(Self.retiredDirectoryName,
                                                               isDirectory: true)

        try fileManager.createDirectory(at: staging(for: key), withIntermediateDirectories: true)
        try? fileManager.removeItem(at: retired)

        let hadPrevious = fileManager.fileExists(atPath: destination.path)
        if hadPrevious {
            try fileManager.moveItem(at: destination, to: retired)
        }

        do {
            try fileManager.moveItem(at: staged, to: destination)
        } catch {
            if hadPrevious {
                try? fileManager.removeItem(at: destination)
                try? fileManager.moveItem(at: retired, to: destination)
            }
            throw error
        }

        try? fileManager.removeItem(at: retired)
    }

    // MARK: - Receipt

    private func receiptURL(forKey key: String) -> URL {
        directory(forKey: key).appendingPathComponent(Self.receiptFileName)
    }

    private func writeReceipt(_ checksum: String, forKey key: String) throws {
        try Data(checksum.utf8).write(to: receiptURL(forKey: key), options: .atomic)
    }

    // MARK: - Bookkeeping

    private func settle(_ key: String, as state: ContentDownloadState) {
        lock.lock()
        activeTasks.removeValue(forKey: key)
        pendingRequests.removeValue(forKey: key)
        rejections.removeValue(forKey: key)
        cancelledInstalls.remove(key)
        let snapshot = pendingRequests
        lock.unlock()

        savePending(snapshot)
        clearWaiting(key)
        report(state, for: key)
    }

    private func report(_ state: ContentDownloadState, for key: String) {
        DispatchQueue.main.async { [weak self] in
            self?.states[key] = state
        }
    }

    // MARK: - Connectivity

    private func startPathMonitor() {
        lock.lock()
        let shouldStart = !isMonitoringPath
        isMonitoringPath = true
        lock.unlock()

        guard shouldStart else { return }
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?.applyConnectivity(isSatisfied: path.status == .satisfied)
        }
        pathMonitor.start(queue: installQueue)
    }

    private func refreshWaiting() {
        applyConnectivity(isSatisfied: pathMonitor.currentPath.status == .satisfied)
    }

    private func applyConnectivity(isSatisfied: Bool) {
        lock.lock()
        let stalled = isSatisfied ? [] : Set(activeTasks.keys)
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            guard let self, self.waitingKeys != stalled else { return }
            self.waitingKeys = stalled
        }
    }

    private func clearWaiting(_ key: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.waitingKeys.contains(key) else { return }
            self.waitingKeys.remove(key)
        }
    }

    var pendingKeys: Set<String> {
        lock.lock(); defer { lock.unlock() }
        return Set(pendingRequests.keys)
    }

    private func recordRejection(_ failure: ContentDownloadFailure, for key: String) {
        lock.lock(); defer { lock.unlock() }
        rejections[key] = failure
    }

    private func takeRejection(for key: String) -> ContentDownloadFailure? {
        lock.lock(); defer { lock.unlock() }
        return rejections.removeValue(forKey: key)
    }

    func hasRejection(for key: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return rejections[key] != nil
    }

    // MARK: - Transfer validation

    static func transferRejection(for response: URLResponse?,
                                  declaredBytes: Int,
                                  receivedBytes: Int64?) -> ContentTransferError? {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            return .unexpectedStatus(http.statusCode)
        }

        guard declaredBytes > 0 else { return nil }

        let advertised = response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown
        if advertised > 0, advertised != Int64(declaredBytes) {
            return .declaredSizeMismatch(expected: declaredBytes, received: advertised)
        }

        if let receivedBytes, receivedBytes != Int64(declaredBytes) {
            return .declaredSizeMismatch(expected: declaredBytes, received: receivedBytes)
        }

        return nil
    }

    static func failure(for error: Error) -> ContentDownloadFailure {
        if let convertible = error as? ContentDownloadFailureConvertible {
            return convertible.contentDownloadFailure
        }

        let wrapped = error as NSError
        if isOutOfSpace(wrapped) { return .noSpace }
        if let underlying = wrapped.userInfo[NSUnderlyingErrorKey] as? NSError, isOutOfSpace(underlying) {
            return .noSpace
        }

        return .transfer
    }

    private static func isOutOfSpace(_ error: NSError) -> Bool {
        switch error.domain {
        case NSCocoaErrorDomain: return error.code == NSFileWriteOutOfSpaceError
        case NSPOSIXErrorDomain: return error.code == Int(ENOSPC)
        default:                 return false
        }
    }

    private func isCancelled(_ key: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelledInstalls.contains(key)
    }

    private func throwIfCancelled(_ key: String) throws {
        if isCancelled(key) { throw CancellationError() }
    }

    private func request(of task: URLSessionTask) -> ContentDownloadRequest? {
        guard let key = task.taskDescription else { return nil }
        lock.lock(); defer { lock.unlock() }
        return pendingRequests[key]
    }

    // MARK: - Staging

    private func staging(for key: String) -> URL {
        stagingRoot.appendingPathComponent(key, isDirectory: true)
    }

    private func clearStaging(for key: String) {
        try? fileManager.removeItem(at: staging(for: key))
    }

    private func clearStaging() {
        try? fileManager.removeItem(at: stagingRoot)
        try? fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
        excludeFromBackup(stagingRoot)
    }

    // MARK: - Pending persistence

    private var pendingURL: URL {
        stagingRoot.appendingPathComponent(Self.pendingFileName)
    }

    private func savePending(_ snapshot: [String: ContentDownloadRequest]) {
        guard sessionIdentifier != nil else { return }
        let url = pendingURL
        installQueue.async { [weak self] in
            guard let self else { return }
            guard !snapshot.isEmpty else {
                try? self.fileManager.removeItem(at: url)
                return
            }
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private func loadPending() {
        guard let data = try? Data(contentsOf: pendingURL),
              let stored = try? JSONDecoder().decode([String: ContentDownloadRequest].self, from: data)
        else { return }
        lock.lock()
        pendingRequests = stored
        lock.unlock()
    }

    // MARK: - Disk

    private func hasRoom(for request: ContentDownloadRequest) -> Bool {
        let needed = Int64(request.archiveSizeBytes) * 2 + Self.spaceMargin
        guard let available = availableCapacity(contentRoot) else { return true }
        return available > needed
    }

    static func volumeCapacity(at url: URL) -> Int64? {
        for candidate in [url, url.deletingLastPathComponent()] {
            if let values = try? candidate.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
               let important = values.volumeAvailableCapacityForImportantUsage {
                return important
            }

            if let values = try? candidate.resourceValues(forKeys: [.volumeAvailableCapacityKey]),
               let available = values.volumeAvailableCapacity {
                return Int64(available)
            }

            if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: candidate.path),
               let free = attributes[.systemFreeSize] as? NSNumber {
                return free.int64Value
            }
        }

        return nil
    }

    private func size(of directory: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(at: directory,
                                                      includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey],
                                                      options: [.skipsHiddenFiles]) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
            total += Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        }
        return total
    }

    private func excludeFromBackup(_ url: URL) {
        var target = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? target.setResourceValues(values)
    }
}

// MARK: - URLSessionDownloadDelegate

extension ContentDownloader: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let key = downloadTask.taskDescription else { return }

        if let request = request(of: downloadTask),
           let rejection = Self.transferRejection(for: downloadTask.response,
                                                  declaredBytes: request.archiveSizeBytes,
                                                  receivedBytes: nil) {
            abort(downloadTask, for: key, because: rejection)
            return
        }

        guard totalBytesExpectedToWrite > 0 else { return }

        let ratio = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        clearWaiting(key)
        report(.downloading(progress: ratio * Self.transferShare), for: key)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let request = request(of: downloadTask) else { return }

        let received = (try? location.resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)

        if let rejection = Self.transferRejection(for: downloadTask.response,
                                                  declaredBytes: request.archiveSizeBytes,
                                                  receivedBytes: received) {
            settle(request.key, as: .failed(rejection.contentDownloadFailure))
            return
        }

        let staging = staging(for: request.key)
        try? fileManager.createDirectory(at: staging, withIntermediateDirectories: true)

        let archive = staging.appendingPathComponent("\(request.key).zip")
        try? fileManager.removeItem(at: archive)

        do {
            try fileManager.moveItem(at: location, to: archive)
        } catch {
            settle(request.key, as: .failed(.transfer))
            return
        }

        install(request, from: archive)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let key = task.taskDescription else { return }

        if let rejection = takeRejection(for: key) {
            settle(key, as: .failed(rejection))
            return
        }

        guard let error else { return }

        if (error as NSError).code == NSURLErrorCancelled {
            settle(key, as: .notDownloaded)
            return
        }
        settle(key, as: .failed(Self.failure(for: error)))
    }

    private func abort(_ task: URLSessionTask, for key: String, because error: ContentTransferError) {
        recordRejection(error.contentDownloadFailure, for: key)
        task.cancel()
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate,
                  let handler = delegate.backgroundSessionCompletionHandler else { return }
            delegate.backgroundSessionCompletionHandler = nil
            handler()
        }
    }
}
