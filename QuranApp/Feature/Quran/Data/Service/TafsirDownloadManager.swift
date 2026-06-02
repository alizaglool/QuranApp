//
//  TafsirDownloadManager.swift
//  QuranApp
//

import Foundation
import Core

// MARK: - Download State

enum TafsirDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)   // 0.0 – 1.0
    case downloaded
    case failed(String)
}

// MARK: - Manager

final class TafsirDownloadManager: NSObject, ObservableObject {

    static let shared = TafsirDownloadManager()

    @Published var states: [String: TafsirDownloadState] = [:]

    let booksDir: URL

    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )
    private var activeTasks: [String: URLSessionDownloadTask] = [:]

    private override init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        booksDir = docs.appendingPathComponent("tafsir_books", isDirectory: true)
        try? FileManager.default.createDirectory(at: booksDir, withIntermediateDirectories: true)
        super.init()
    }

    // MARK: - Public API

    func jsonURL(for bookId: String) -> URL {
        booksDir.appendingPathComponent("\(bookId).json")
    }

    func isDownloaded(_ bookId: String) -> Bool {
        // Bundled books are always "downloaded"
        if TafsirBook.find(id: bookId)?.isBundle == true { return true }
        return FileManager.default.fileExists(atPath: jsonURL(for: bookId).path)
    }

    func state(for bookId: String) -> TafsirDownloadState {
        if TafsirBook.find(id: bookId)?.isBundle == true { return .downloaded }
        return states[bookId] ?? (isDownloaded(bookId) ? .downloaded : .notDownloaded)
    }

    /// Downloads the pre-built JSON from GitHub. Only works for books with a non-empty downloadURL.
    func download(bookId: String) {
        guard let book = TafsirBook.find(id: bookId), book.canDownload else { return }
        guard !isDownloaded(bookId) else {
            DispatchQueue.main.async { self.states[bookId] = .downloaded }
            return
        }
        guard activeTasks[bookId] == nil else { return }
        guard let url = URL(string: book.downloadURL) else { return }

        DispatchQueue.main.async { self.states[bookId] = .downloading(progress: 0) }

        let task = session.downloadTask(with: url)
        task.taskDescription = bookId
        activeTasks[bookId] = task
        task.resume()
    }

    func cancel(bookId: String) {
        activeTasks[bookId]?.cancel()
        activeTasks[bookId] = nil
        DispatchQueue.main.async { self.states[bookId] = .notDownloaded }
    }

    func delete(bookId: String) {
        activeTasks[bookId]?.cancel()
        activeTasks[bookId] = nil
        try? FileManager.default.removeItem(at: jsonURL(for: bookId))
        TafsirService.shared.evict(bookId: bookId)
        DispatchQueue.main.async { self.states[bookId] = .notDownloaded }
    }
}

// MARK: - URLSessionDownloadDelegate

extension TafsirDownloadManager: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let bookId = downloadTask.taskDescription else { return }
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0
        DispatchQueue.main.async { self.states[bookId] = .downloading(progress: progress) }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let bookId = downloadTask.taskDescription else { return }
        let dest = jsonURL(for: bookId)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
            // Parse and hot-load into TafsirService memory
            if let raw  = try? Data(contentsOf: dest),
               let dict = try? JSONDecoder().decode([String: String].self, from: raw) {
                TafsirService.shared.loadDownloaded(bookId: bookId, dict: dict)
            }
            DispatchQueue.main.async {
                self.activeTasks[bookId] = nil
                self.states[bookId] = .downloaded
            }
        } catch {
            DispatchQueue.main.async {
                self.activeTasks[bookId] = nil
                self.states[bookId] = .failed(error.localizedDescription)
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error,
              (error as NSError).code != NSURLErrorCancelled,
              let bookId = task.taskDescription else { return }
        DispatchQueue.main.async {
            self.activeTasks[bookId] = nil
            self.states[bookId] = .failed(error.localizedDescription)
        }
    }
}
