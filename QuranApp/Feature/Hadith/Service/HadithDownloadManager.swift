//
//  HadithDownloadManager.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-28.
//

import Foundation

// MARK: - Download state

enum HadithDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(String)
}

// MARK: - Manager

final class HadithDownloadManager: NSObject, ObservableObject {

    static let shared = HadithDownloadManager()

    @Published var states: [Int: HadithDownloadState] = [:]

    let booksDir: URL

    private lazy var session: URLSession = URLSession(
        configuration: .default,
        delegate: self,
        delegateQueue: nil
    )
    private var activeTasks: [Int: URLSessionDownloadTask] = [:]

    private override init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        booksDir = docs.appendingPathComponent("hadith_books", isDirectory: true)
        try? FileManager.default.createDirectory(at: booksDir, withIntermediateDirectories: true)
        super.init()
    }

    // MARK: - Public API

    func dbURL(for bookId: Int) -> URL {
        booksDir.appendingPathComponent("hadith_book_\(bookId).db")
    }

    func isDownloaded(_ bookId: Int) -> Bool {
        FileManager.default.fileExists(atPath: dbURL(for: bookId).path)
    }

    func state(for bookId: Int) -> HadithDownloadState {
        states[bookId] ?? (isDownloaded(bookId) ? .downloaded : .notDownloaded)
    }

    var downloadedBookIds: [Int] {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: booksDir.path)) ?? []
        return files.compactMap { name -> Int? in
            guard name.hasPrefix("hadith_book_"), name.hasSuffix(".db") else { return nil }
            return Int(name.dropFirst(12).dropLast(3))
        }.sorted()
    }

    func download(book: HadithBook) {
        guard !isDownloaded(book.id), activeTasks[book.id] == nil else { return }
        guard !book.downloadURL.isEmpty, let url = URL(string: book.downloadURL) else { return }

        DispatchQueue.main.async { self.states[book.id] = .downloading(progress: 0) }

        let task = session.downloadTask(with: url)
        task.taskDescription = "\(book.id)"
        activeTasks[book.id] = task
        task.resume()
    }

    func cancel(bookId: Int) {
        activeTasks[bookId]?.cancel()
        activeTasks[bookId] = nil
        DispatchQueue.main.async { self.states[bookId] = .notDownloaded }
    }

    func delete(bookId: Int) {
        activeTasks[bookId]?.cancel()
        activeTasks[bookId] = nil
        try? FileManager.default.removeItem(at: dbURL(for: bookId))
        HadithDatabaseService.shared.closeDB(for: bookId)
        DispatchQueue.main.async { self.states[bookId] = .notDownloaded }
    }
}

// MARK: - URLSessionDownloadDelegate

extension HadithDownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let desc = downloadTask.taskDescription, let bookId = Int(desc) else { return }
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0
        DispatchQueue.main.async { self.states[bookId] = .downloading(progress: progress) }
    }

    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let desc = downloadTask.taskDescription, let bookId = Int(desc) else { return }
        let dest = dbURL(for: bookId)
        try? FileManager.default.moveItem(at: location, to: dest)
        DispatchQueue.main.async {
            self.activeTasks[bookId] = nil
            self.states[bookId] = .downloaded
        }
    }

    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let error,
              (error as NSError).code != NSURLErrorCancelled,
              let desc = task.taskDescription,
              let bookId = Int(desc) else { return }
        DispatchQueue.main.async {
            self.activeTasks[bookId] = nil
            self.states[bookId] = .failed(error.localizedDescription)
        }
    }
}
