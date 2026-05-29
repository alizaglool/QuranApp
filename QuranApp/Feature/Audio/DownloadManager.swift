//
//  DownloadManager.swift
//  QuranApp
//

import Foundation
import UIKit

// MARK: - DownloadProgress

struct DownloadProgress {
    let reciterSlug: String
    var completedVerses: Int
    var totalVerses: Int
    var isCancelled: Bool = false

    var fractionCompleted: Double {
        totalVerses > 0 ? Double(completedVerses) / Double(totalVerses) : 0
    }
}

// MARK: - DownloadManager

@MainActor
final class DownloadManager: NSObject, ObservableObject {

    static let shared = DownloadManager()

    @Published var activeDownloads: [String: DownloadProgress] = [:]
    @Published var completedReciters: Set<String> = []

    private var backgroundSession: URLSession!
    private var taskToReciter: [Int: String] = [:]        // taskIdentifier → reciterSlug
    private var taskToLocalURL: [Int: URL] = [:]          // taskIdentifier → destination
    private var downloadQueues: [String: [URL]] = [:]     // reciterSlug → pending URLs
    private var activeTaskCount: [String: Int] = [:]      // reciterSlug → running task count
    private let maxConcurrent = 4
    private let storage = StorageManager.shared

    private static let sessionIdentifier = "com.quranapp.audio.download"
    private static let audioDir: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Audio")
    }()

    override private init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        loadCompletedReciters()
    }

    // MARK: - Public API

    func downloadAllSurahs(for reciter: ReciterInfo) {
        guard activeDownloads[reciter.id] == nil else { return }

        storage.upsertDownloadedReciter(slug: reciter.id, name: reciter.englishName, arabicName: reciter.arabicName)

        let totalVerses = ReciterLibrary.verseCounts.values.reduce(0, +)
        activeDownloads[reciter.id] = DownloadProgress(
            reciterSlug: reciter.id,
            completedVerses: 0,
            totalVerses: totalVerses
        )

        var urls: [URL] = []
        for surah in 1...114 {
            let count = ReciterLibrary.verseCounts[surah] ?? 0
            for verse in 1...max(1, count) {
                let dest = localURL(reciterSlug: reciter.id, surahNumber: surah, verseNumber: verse)!
                if !FileManager.default.fileExists(atPath: dest.path) {
                    urls.append(ReciterLibrary.everyAyahURL(reciter: reciter.id, surah: surah, verse: verse))
                } else {
                    activeDownloads[reciter.id]?.completedVerses += 1
                }
            }
        }

        downloadQueues[reciter.id] = urls
        activeTaskCount[reciter.id] = 0
        drainQueue(for: reciter.id)
    }

    func cancelDownload(for reciterSlug: String) {
        downloadQueues[reciterSlug] = []
        activeDownloads[reciterSlug]?.isCancelled = true
        backgroundSession.getAllTasks { tasks in
            Task { @MainActor in
                let slugTasks = tasks.filter { self.taskToReciter[$0.taskIdentifier] == reciterSlug }
                slugTasks.forEach { $0.cancel() }
                self.activeDownloads.removeValue(forKey: reciterSlug)
                self.activeTaskCount.removeValue(forKey: reciterSlug)
            }
        }
    }

    func deleteReciter(_ reciterSlug: String) {
        cancelDownload(for: reciterSlug)
        let dir = Self.audioDir.appendingPathComponent(reciterSlug)
        try? FileManager.default.removeItem(at: dir)
        storage.deleteDownloadedReciter(slug: reciterSlug)
        completedReciters.remove(reciterSlug)
    }

    func downloadSurah(for reciter: ReciterInfo, surahNumber: Int) {
        guard !isSurahFullyDownloaded(reciterSlug: reciter.id, surahNumber: surahNumber) else { return }

        storage.upsertDownloadedReciter(slug: reciter.id, name: reciter.englishName, arabicName: reciter.arabicName)

        let count = ReciterLibrary.verseCounts[surahNumber] ?? 0
        var urls: [URL] = []
        for verse in 1...max(1, count) {
            let dest = localURL(reciterSlug: reciter.id, surahNumber: surahNumber, verseNumber: verse)!
            if !FileManager.default.fileExists(atPath: dest.path) {
                urls.append(ReciterLibrary.everyAyahURL(reciter: reciter.id, surah: surahNumber, verse: verse))
            }
        }
        guard !urls.isEmpty else { return }

        if activeDownloads[reciter.id] == nil {
            activeDownloads[reciter.id] = DownloadProgress(
                reciterSlug: reciter.id,
                completedVerses: 0,
                totalVerses: urls.count
            )
            downloadQueues[reciter.id] = []
            activeTaskCount[reciter.id] = 0
        } else {
            activeDownloads[reciter.id]?.totalVerses += urls.count
        }

        downloadQueues[reciter.id, default: []] += urls
        drainQueue(for: reciter.id)
    }

    func isSurahFullyDownloaded(reciterSlug: String, surahNumber: Int) -> Bool {
        let count = ReciterLibrary.verseCounts[surahNumber] ?? 0
        return (1...max(1, count)).allSatisfy {
            isAvailable(reciterSlug: reciterSlug, surahNumber: surahNumber, verseNumber: $0)
        }
    }

    func isSurahDownloading(reciterSlug: String, surahNumber: Int) -> Bool {
        guard activeDownloads[reciterSlug] != nil else { return false }
        let prefix = String(format: "%03d", surahNumber)
        let inQueue = downloadQueues[reciterSlug]?.contains {
            $0.lastPathComponent.hasPrefix(prefix)
        } ?? false
        let inFlight = taskToLocalURL.values.contains {
            $0.deletingLastPathComponent().lastPathComponent == reciterSlug &&
            $0.lastPathComponent.hasPrefix(prefix)
        }
        return inQueue || inFlight
    }

    func isAvailable(reciterSlug: String, surahNumber: Int, verseNumber: Int) -> Bool {
        guard let url = localURL(reciterSlug: reciterSlug, surahNumber: surahNumber, verseNumber: verseNumber)
        else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    func localURL(reciterSlug: String, surahNumber: Int, verseNumber: Int) -> URL? {
        let s = String(format: "%03d", surahNumber)
        let v = String(format: "%03d", verseNumber)
        return Self.audioDir
            .appendingPathComponent(reciterSlug)
            .appendingPathComponent("\(s)\(v).mp3")
    }

    func totalStorageUsedMB() -> Double {
        let all = storage.getAllDownloadedReciters()
        let totalBytes = all.reduce(Int64(0)) { $0 + $1.totalSizeBytes }
        return Double(totalBytes) / 1_048_576
    }

    // MARK: - Queue management

    private func drainQueue(for slug: String) {
        guard var queue = downloadQueues[slug], !queue.isEmpty else {
            checkCompletion(for: slug)
            return
        }
        let running = activeTaskCount[slug] ?? 0
        let slots = maxConcurrent - running
        guard slots > 0 else { return }

        let batch = queue.prefix(slots)
        queue.removeFirst(min(slots, queue.count))
        downloadQueues[slug] = queue

        for remoteURL in batch {
            scheduleDownload(remoteURL: remoteURL, reciterSlug: slug)
        }
    }

    private func scheduleDownload(remoteURL: URL, reciterSlug: String) {
        // Derive local path from URL filename
        let filename = remoteURL.lastPathComponent
        let dest = Self.audioDir
            .appendingPathComponent(reciterSlug)
            .appendingPathComponent(filename)

        try? FileManager.default.createDirectory(
            at: dest.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let request = URLRequest(url: remoteURL)
        let task = backgroundSession.downloadTask(with: request)
        taskToReciter[task.taskIdentifier] = reciterSlug
        taskToLocalURL[task.taskIdentifier] = dest
        activeTaskCount[reciterSlug, default: 0] += 1
        task.resume()
    }

    private func checkCompletion(for slug: String) {
        let running = activeTaskCount[slug] ?? 0
        let queued  = downloadQueues[slug]?.count ?? 0
        guard running == 0, queued == 0 else { return }

        activeDownloads.removeValue(forKey: slug)
        completedReciters.insert(slug)

        // Notify AppDelegate the background session events are done
        if let handler = (UIApplication.shared.delegate as? AppDelegate)?.backgroundSessionCompletionHandler {
            (UIApplication.shared.delegate as? AppDelegate)?.backgroundSessionCompletionHandler = nil
            DispatchQueue.main.async { handler() }
        }
    }

    // MARK: - Completed state

    private func loadCompletedReciters() {
        for reciter in storage.getAllDownloadedReciters() {
            if reciter.downloadedSurahNumbers.count == 114 {
                completedReciters.insert(reciter.slug)
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let taskId = downloadTask.taskIdentifier
        Task { @MainActor in
            guard let dest = self.taskToLocalURL[taskId],
                  let slug = self.taskToReciter[taskId]
            else { return }

            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.moveItem(at: location, to: dest)

                let size = (try? FileManager.default.attributesOfItem(atPath: dest.path)[.size] as? Int64) ?? 0

                // Extract surah number from filename (e.g. 002001.mp3 → surah 2)
                let filename = dest.deletingPathExtension().lastPathComponent
                let surahStr = String(filename.prefix(3))
                if let surahNum = Int(surahStr) {
                    self.storage.addDownloadedSurah(reciterSlug: slug, surahNumber: surahNum, sizeBytes: size)
                }

                self.activeDownloads[slug]?.completedVerses += 1
            } catch {}

            self.taskToReciter.removeValue(forKey: taskId)
            self.taskToLocalURL.removeValue(forKey: taskId)
            self.activeTaskCount[slug, default: 1] -= 1
            self.drainQueue(for: slug)
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        let taskId = task.taskIdentifier
        let cancelled = (error as? URLError)?.code == .cancelled
        Task { @MainActor in
            guard let slug = self.taskToReciter[taskId] else { return }
            self.taskToReciter.removeValue(forKey: taskId)
            self.taskToLocalURL.removeValue(forKey: taskId)
            self.activeTaskCount[slug, default: 1] -= 1
            if !cancelled {
                // Re-enqueue failed URL
                if let url = task.originalRequest?.url {
                    self.downloadQueues[slug, default: []].insert(url, at: 0)
                }
                self.drainQueue(for: slug)
            } else {
                self.drainQueue(for: slug)
            }
        }
    }

    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        Task { @MainActor in
            if let handler = (UIApplication.shared.delegate as? AppDelegate)?.backgroundSessionCompletionHandler {
                (UIApplication.shared.delegate as? AppDelegate)?.backgroundSessionCompletionHandler = nil
                handler()
            }
        }
    }
}
