//
//  AthkarAudioDownloadManager.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Combine
import Core

// MARK: - Failure

enum AthkarAudioFailure: Equatable {
    case unavailable
    case noSpace
    case corrupt
    case transfer
}

// MARK: - State

enum AthkarAudioState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case installing
    case downloaded
    case failed(AthkarAudioFailure)

    var isBusy: Bool {
        switch self {
        case .downloading, .installing: return true
        default:                        return false
        }
    }
}

// MARK: - Manager

final class AthkarAudioDownloadManager: NSObject, ObservableObject {

    static let shared = AthkarAudioDownloadManager()

    @Published var states: [String: AthkarAudioState] = [:]

    private static let transferShare = 0.9
    private static let spaceMargin: Int64 = 32 * 1024 * 1024
    private static let audioPrefix = "audio/"

    private let fileManager: FileManager
    private let audioRoot: URL
    private let stagingRoot: URL

    private let installQueue = DispatchQueue(label: "com.quranapp.athkar.audio.install", qos: .utility)
    private let lock = NSLock()
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var pendingPacks: [String: AthkarPack] = [:]
    private var cancelledInstalls: Set<String> = []

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = 600
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.audioRoot = documents.appendingPathComponent("athkar_audio", isDirectory: true)
        self.stagingRoot = documents.appendingPathComponent("athkar_audio_staging", isDirectory: true)
        super.init()
        try? fileManager.createDirectory(at: audioRoot, withIntermediateDirectories: true)
        clearStaging()
    }

    // MARK: - Paths

    func directory(forKey key: String) -> URL {
        audioRoot.appendingPathComponent(key, isDirectory: true)
    }

    func localURL(for item: AthkarItem, inPack key: String) -> URL? {
        guard item.hasAudio else { return nil }
        let name = (item.audio as NSString).lastPathComponent
        let url = directory(forKey: key).appendingPathComponent(name)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Status

    func isDownloaded(_ key: String) -> Bool {
        let directory = directory(forKey: key)
        guard let contents = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return false }
        return contents.contains { $0.hasSuffix(".m4a") }
    }

    func state(for pack: AthkarPack) -> AthkarAudioState {
        if let live = states[pack.key], live.isBusy { return live }
        if isDownloaded(pack.key) { return .downloaded }
        if let known = states[pack.key] { return known }
        return .notDownloaded
    }

    func installedSize(of key: String) -> Int64 {
        let directory = directory(forKey: key)
        guard let contents = try? fileManager.contentsOfDirectory(at: directory,
                                                                 includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return contents.reduce(Int64(0)) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }

    // MARK: - Transfer

    func download(pack: AthkarPack) {
        guard pack.hasAudio, let remote = pack.archiveRemoteURL else {
            report(.failed(.unavailable), for: pack.key)
            return
        }
        guard !isDownloaded(pack.key) else {
            report(.downloaded, for: pack.key)
            return
        }

        lock.lock()
        let alreadyRunning = activeTasks[pack.key] != nil
        if !alreadyRunning {
            cancelledInstalls.remove(pack.key)
            pendingPacks[pack.key] = pack
        }
        lock.unlock()

        guard !alreadyRunning else { return }

        guard hasRoom(for: pack) else {
            report(.failed(.noSpace), for: pack.key)
            return
        }

        report(.downloading(progress: 0), for: pack.key)

        let task = session.downloadTask(with: remote)
        task.taskDescription = pack.key

        lock.lock()
        activeTasks[pack.key] = task
        lock.unlock()

        task.resume()
    }

    func cancel(key: String) {
        lock.lock()
        let task = activeTasks.removeValue(forKey: key)
        pendingPacks.removeValue(forKey: key)
        cancelledInstalls.insert(key)
        lock.unlock()

        task?.cancel()
        clearStaging(for: key)
        report(.notDownloaded, for: key)
    }

    func delete(key: String) {
        cancel(key: key)
        try? fileManager.removeItem(at: directory(forKey: key))
        report(.notDownloaded, for: key)
    }

    // MARK: - Install

    private func install(pack: AthkarPack, from archive: URL) {
        report(.installing, for: pack.key)

        installQueue.async { [weak self] in
            guard let self else { return }
            let outcome = self.performInstall(pack: pack, from: archive)
            self.settle(pack.key, as: outcome)
        }
    }

    private func performInstall(pack: AthkarPack, from archive: URL) -> AthkarAudioState {
        defer { clearStaging(for: pack.key) }

        do {
            try throwIfCancelled(pack.key)
            let digest = try AthkarArchive.sha256(ofFileAt: archive)
            try AthkarArchive.verify(digest: digest, matches: pack.archiveSha256)

            try throwIfCancelled(pack.key)

            let destination = directory(forKey: pack.key)
            let staging = stagingRoot.appendingPathComponent(pack.key, isDirectory: true)
            try? fileManager.removeItem(at: staging)

            let written = try AthkarArchive.extract(archiveAt: archive, to: staging) { entry in
                entry.path.hasPrefix(Self.audioPrefix) && entry.path.hasSuffix(".m4a")
            }

            guard !written.isEmpty else {
                return .failed(.unavailable)
            }

            try throwIfCancelled(pack.key)

            try? fileManager.removeItem(at: destination)
            try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)

            for file in written {
                let target = destination.appendingPathComponent(file.lastPathComponent)
                try? fileManager.removeItem(at: target)
                try fileManager.moveItem(at: file, to: target)
            }

            return .downloaded
        } catch is CancellationError {
            return .notDownloaded
        } catch let error as AthkarDataError {
            switch error {
            case .checksumMismatch, .corruptArchive:
                return .failed(.corrupt)
            case .insufficientSpace:
                return .failed(.noSpace)
            default:
                return .failed(.transfer)
            }
        } catch {
            return .failed(.transfer)
        }
    }

    // MARK: - Bookkeeping

    private func settle(_ key: String, as state: AthkarAudioState) {
        lock.lock()
        activeTasks.removeValue(forKey: key)
        pendingPacks.removeValue(forKey: key)
        cancelledInstalls.remove(key)
        lock.unlock()

        report(state, for: key)
    }

    private func report(_ state: AthkarAudioState, for key: String) {
        DispatchQueue.main.async { [weak self] in
            self?.states[key] = state
        }
    }

    private func isCancelled(_ key: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelledInstalls.contains(key)
    }

    private func throwIfCancelled(_ key: String) throws {
        if isCancelled(key) { throw CancellationError() }
    }

    private func pack(of task: URLSessionTask) -> AthkarPack? {
        guard let key = task.taskDescription else { return nil }
        lock.lock(); defer { lock.unlock() }
        return pendingPacks[key]
    }

    private func clearStaging(for key: String) {
        try? fileManager.removeItem(at: stagingRoot.appendingPathComponent(key, isDirectory: true))
    }

    private func clearStaging() {
        try? fileManager.removeItem(at: stagingRoot)
        try? fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)
    }

    private func hasRoom(for pack: AthkarPack) -> Bool {
        let needed = Int64(pack.archiveSizeBytes) * 2 + Self.spaceMargin
        guard let values = try? audioRoot.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let available = values.volumeAvailableCapacityForImportantUsage else { return true }
        return available > needed
    }
}

// MARK: - URLSessionDownloadDelegate

extension AthkarAudioDownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let key = downloadTask.taskDescription, totalBytesExpectedToWrite > 0 else { return }
        let ratio = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        report(.downloading(progress: ratio * Self.transferShare), for: key)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let pack = pack(of: downloadTask) else { return }

        let staging = stagingRoot.appendingPathComponent(pack.key, isDirectory: true)
        try? fileManager.createDirectory(at: staging, withIntermediateDirectories: true)

        let archive = staging.appendingPathComponent("\(pack.key).zip")
        try? fileManager.removeItem(at: archive)

        do {
            try fileManager.moveItem(at: location, to: archive)
        } catch {
            settle(pack.key, as: .failed(.transfer))
            return
        }

        install(pack: pack, from: archive)
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let key = task.taskDescription else { return }
        guard let error else { return }

        if (error as NSError).code == NSURLErrorCancelled {
            settle(key, as: .notDownloaded)
            return
        }
        settle(key, as: .failed(.transfer))
    }
}
