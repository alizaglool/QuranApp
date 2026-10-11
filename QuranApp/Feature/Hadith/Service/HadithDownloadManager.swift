//
//  HadithDownloadManager.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-28.
//

import Foundation
import Core

// MARK: - Download state

enum HadithDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(String)
}

// MARK: - Errors

/// The one failure the archive layer has nothing to say about: there was never
/// room for the book in the first place.
enum HadithDownloadError: LocalizedError {
    case insufficientSpace

    var errorDescription: String? { "hadithDownloadStorageError".localized }
}

// MARK: - Manager

/// Brings a book onto the device and refuses to let a damaged one through.
///
/// A download is not finished when the bytes stop arriving. The archive is
/// hashed, expanded, hashed again and only then moved to where the app reads
/// from, so the library either gains a book that is provably the one the
/// release published, or gains nothing at all.
final class HadithDownloadManager: NSObject, ObservableObject {

    static let shared = HadithDownloadManager()

    @Published var states: [Int: HadithDownloadState] = [:]

    let booksDir: URL

    /// Where a book sits while it is being proved. Nothing here is ever read
    /// by the app, so a crash part-way through leaves no half-book behind that
    /// a later launch could mistake for the real thing.
    private let stagingDir: URL

    /// What the transfer is worth out of the whole job. The rest is the
    /// un-gzipping, which is the slower half on the big books.
    private static let transferShare = 0.92

    /// 64 MiB kept back, so a book that only just fits does not leave the
    /// device with no room to open it.
    private static let spaceMargin: Int64 = 64 * 1024 * 1024

    private let fileManager: FileManager
    private let manifestService: HadithManifestService

    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )

    /// Installs run one at a time: two 460 MiB expansions at once would be
    /// slower than either alone and could run the device out of space.
    private let installQueue = DispatchQueue(label: "com.quranapp.hadith.install", qos: .utility)
    private let progressQueue = DispatchQueue(label: "com.quranapp.hadith.install.progress", qos: .utility)

    private let lock = NSLock()
    private var activeTasks: [Int: URLSessionDownloadTask] = [:]
    /// The manifest entry each transfer was started from, which is where the
    /// digests to check against come from.
    private var pendingBooks: [Int: HadithBook] = [:]
    /// Books the reader stopped while they were installing.
    private var cancelledInstalls: Set<Int> = []

    private override init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        booksDir = docs.appendingPathComponent("hadith_books", isDirectory: true)
        stagingDir = booksDir.appendingPathComponent(".staging", isDirectory: true)
        fileManager = .default
        manifestService = .shared
        try? fileManager.createDirectory(at: booksDir, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        super.init()

        // Before anything else reads the directory: the old corpus named its
        // files the same way for different books, so one launch has to clear
        // them out or every query lands in the wrong collection.
        HadithCorpusMigration.runIfNeeded(booksDirectory: booksDir)
        clearStaging()
    }

    // MARK: - Public API

    func dbURL(for bookId: Int) -> URL {
        booksDir.appendingPathComponent("hadith_book_\(bookId).db")
    }

    func isDownloaded(_ bookId: Int) -> Bool {
        fileManager.fileExists(atPath: dbURL(for: bookId).path)
    }

    func state(for bookId: Int) -> HadithDownloadState {
        states[bookId] ?? (isDownloaded(bookId) ? .downloaded : .notDownloaded)
    }

    var downloadedBookIds: [Int] {
        let files = (try? fileManager.contentsOfDirectory(atPath: booksDir.path)) ?? []
        return files.compactMap { name -> Int? in
            guard name.hasPrefix("hadith_book_"), name.hasSuffix(".db") else { return nil }
            return Int(name.dropFirst(12).dropLast(3))
        }.sorted()
    }

    /// What the book actually takes up, which is what the reader is deciding
    /// about — not the figure the manifest advertised for it.
    func installedSize(of bookId: Int) -> Int {
        let values = try? dbURL(for: bookId).resourceValues(forKeys: [.fileAllocatedSizeKey, .fileSizeKey])
        return values?.fileAllocatedSize ?? values?.fileSize ?? 0
    }

    /// Total bytes every installed book is using.
    var installedSizeTotal: Int {
        downloadedBookIds.reduce(0) { $0 + installedSize(of: $1) }
    }

    func download(book: HadithBook) {
        guard !isDownloaded(book.id) else { return }
        guard !book.downloadURL.isEmpty, let url = URL(string: book.downloadURL) else { return }
        guard hasRoom(for: book) else {
            report(.failed(HadithDownloadError.insufficientSpace.localizedDescription), for: book.id)
            return
        }

        lock.lock()
        guard activeTasks[book.id] == nil else { lock.unlock(); return }
        pendingBooks[book.id] = book
        cancelledInstalls.remove(book.id)
        let task = session.downloadTask(with: url)
        task.taskDescription = "\(book.id)"
        activeTasks[book.id] = task
        lock.unlock()

        report(.downloading(progress: 0), for: book.id)
        task.resume()
    }

    func cancel(bookId: Int) {
        // A book that has already landed has nothing to stop, and saying
        // otherwise would leave a download button that does nothing.
        guard !isDownloaded(bookId) else { return }

        lock.lock()
        let task = activeTasks.removeValue(forKey: bookId)
        pendingBooks[bookId] = nil
        // An install under way cannot be stopped mid-stream, so it is marked
        // instead and throws its own work away at the next step.
        cancelledInstalls.insert(bookId)
        lock.unlock()

        task?.cancel()
        // Queued, so it never deletes a file the install is still writing.
        installQueue.async { [weak self] in self?.clearStaging(for: bookId) }
        report(.notDownloaded, for: bookId)
    }

    func delete(bookId: Int) {
        lock.lock()
        let task = activeTasks.removeValue(forKey: bookId)
        pendingBooks[bookId] = nil
        cancelledInstalls.insert(bookId)
        lock.unlock()
        task?.cancel()

        // Closed first: removing the file under an open handle leaves the
        // reader looking at a database nobody can see any more.
        HadithDatabaseService.shared.closeDB(for: bookId)
        try? fileManager.removeItem(at: dbURL(for: bookId))
        HadithInstalledVersions.forget(bookId: bookId)
        installQueue.async { [weak self] in self?.clearStaging(for: bookId) }
        report(.notDownloaded, for: bookId)
    }

    // MARK: - Installing

    /// Proves the archive, expands it, and puts the result where the app reads
    /// from.
    ///
    /// Every step has to pass before the next one runs, and the book only
    /// becomes visible to the rest of the app on the final move. A failure
    /// anywhere leaves the library exactly as it was.
    private func install(book: HadithBook, from archive: URL) {
        let timer = startInstallProgress(for: book)
        let outcome = performInstall(book: book, from: archive)
        stopInstallProgress(timer)

        clearStaging(for: book.id)
        settle(book.id, as: outcome)
    }

    private func performInstall(book: HadithBook, from archive: URL) -> HadithDownloadState {
        let bookId = book.id
        let expanded = expandedURL(for: bookId)

        do {
            try throwIfCancelled(bookId)
            try HadithArchive.verify(digest: HadithArchive.sha256(ofFileAt: archive),
                                     matches: book.gzSha256)

            try throwIfCancelled(bookId)
            // Hashed as it is written, so the 460 MiB is never read twice.
            let digest = try HadithArchive.gunzip(from: archive, to: expanded)
            try HadithArchive.verify(digest: digest, matches: book.dbSha256)

            try throwIfCancelled(bookId)
            HadithDatabaseService.shared.closeDB(for: bookId)
            let destination = dbURL(for: bookId)
            try? fileManager.removeItem(at: destination)
            try fileManager.moveItem(at: expanded, to: destination)

            // The reader can delete a book while its last bytes are landing.
            // Honouring that here is the only way it does not come straight
            // back as a file nothing in the app agreed to keep.
            if isCancelled(bookId) {
                HadithDatabaseService.shared.closeDB(for: bookId)
                try? fileManager.removeItem(at: destination)
                return .notDownloaded
            }

            HadithInstalledVersions.record(bookId: bookId,
                                           dbSha256: digest,
                                           corpusVersion: manifestService.load().corpusVersion)
            return .downloaded
        } catch is CancellationError {
            try? fileManager.removeItem(at: expanded)
            return .notDownloaded
        } catch {
            try? fileManager.removeItem(at: expanded)
            return .failed(error.localizedDescription)
        }
    }

    /// Reports the expansion as it runs, by watching the file grow.
    ///
    /// `HadithArchive` streams and has no progress of its own to hand back, so
    /// the size on disk is the honest measure — and the manifest has already
    /// said what to expect it to reach.
    private func startInstallProgress(for book: HadithBook) -> DispatchSourceTimer? {
        guard book.installedSizeBytes > 0 else { return nil }
        let expanded = expandedURL(for: book.id)
        let expected = Double(book.installedSizeBytes)

        let timer = DispatchSource.makeTimerSource(queue: progressQueue)
        timer.schedule(deadline: .now() + 0.25, repeating: 0.25)
        timer.setEventHandler { [weak self] in
            guard let self else { return }
            let written = (try? expanded.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            let fraction = min(Double(written) / expected, 1)
            let overall = Self.transferShare + fraction * (1 - Self.transferShare)
            self.report(.downloading(progress: overall), for: book.id)
        }
        timer.resume()
        return timer
    }

    /// Stops the timer and waits for a handler that is already running, so the
    /// outcome reported next is the last word rather than the second to last.
    private func stopInstallProgress(_ timer: DispatchSourceTimer?) {
        guard let timer else { return }
        timer.cancel()
        progressQueue.sync { }
    }

    // MARK: - Bookkeeping

    /// Clears the book's bookkeeping and publishes where it ended up.
    private func settle(_ bookId: Int, as state: HadithDownloadState) {
        lock.lock()
        activeTasks[bookId] = nil
        pendingBooks[bookId] = nil
        cancelledInstalls.remove(bookId)
        lock.unlock()
        report(state, for: bookId)
    }

    private func report(_ state: HadithDownloadState, for bookId: Int) {
        DispatchQueue.main.async { self.states[bookId] = state }
    }

    private func isCancelled(_ bookId: Int) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return cancelledInstalls.contains(bookId)
    }

    private func throwIfCancelled(_ bookId: Int) throws {
        guard !isCancelled(bookId) else { throw CancellationError() }
    }

    private func bookId(of task: URLSessionTask) -> Int? {
        guard let description = task.taskDescription else { return nil }
        return Int(description)
    }

    // MARK: - Staging

    private func archiveURL(for bookId: Int) -> URL {
        stagingDir.appendingPathComponent("hadith_book_\(bookId).db.gz")
    }

    private func expandedURL(for bookId: Int) -> URL {
        stagingDir.appendingPathComponent("hadith_book_\(bookId).db.part")
    }

    private func clearStaging(for bookId: Int) {
        try? fileManager.removeItem(at: archiveURL(for: bookId))
        try? fileManager.removeItem(at: expandedURL(for: bookId))
    }

    /// Throws away whatever a previous launch was part-way through.
    private func clearStaging() {
        let leftovers = (try? fileManager.contentsOfDirectory(at: stagingDir,
                                                              includingPropertiesForKeys: nil)) ?? []
        for url in leftovers { try? fileManager.removeItem(at: url) }
    }

    /// Refuses a download that cannot fit, rather than filling the disk and
    /// failing at the last step.
    ///
    /// Both halves have to fit at once, because the archive is still on disk
    /// while it is being expanded.
    private func hasRoom(for book: HadithBook) -> Bool {
        let needed = book.fileSizeBytes + book.installedSizeBytes
        // A manifest that did not say gets the benefit of the doubt: refusing
        // on a figure nobody sent would be the wrong failure.
        guard needed > 0 else { return true }
        guard let values = try? booksDir.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
              let available = values.volumeAvailableCapacityForImportantUsage else { return true }
        return available > Int64(needed) + Self.spaceMargin
    }
}

// MARK: - URLSessionDownloadDelegate

extension HadithDownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let bookId = bookId(of: downloadTask) else { return }
        let fraction = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0
        report(.downloading(progress: fraction * Self.transferShare), for: bookId)
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let bookId = bookId(of: downloadTask) else { return }

        lock.lock()
        let book = pendingBooks[bookId]
        let cancelled = cancelledInstalls.contains(bookId)
        lock.unlock()

        guard let book, !cancelled else {
            try? fileManager.removeItem(at: location)
            return
        }

        // URLSession deletes this file the moment the delegate returns, so the
        // move happens here and the slow work is handed on afterwards.
        try? fileManager.createDirectory(at: stagingDir, withIntermediateDirectories: true)
        let archive = archiveURL(for: bookId)
        try? fileManager.removeItem(at: archive)
        do {
            try fileManager.moveItem(at: location, to: archive)
        } catch {
            settle(bookId, as: .failed(HadithArchiveError.writeFailed.localizedDescription))
            return
        }

        report(.downloading(progress: Self.transferShare), for: bookId)
        installQueue.async { [weak self] in self?.install(book: book, from: archive) }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let error, let bookId = bookId(of: task) else { return }
        // A cancel has already said what the state is; repeating it here would
        // overwrite a `delete` that came in behind it.
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        settle(bookId, as: .failed(error.localizedDescription))
    }
}
