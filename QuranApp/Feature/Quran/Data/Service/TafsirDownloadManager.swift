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

final class TafsirDownloadManager: ObservableObject {

    static let shared = TafsirDownloadManager()

    @Published var states: [String: TafsirDownloadState] = [:]

    let booksDir: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        booksDir = docs.appendingPathComponent("tafsir_books", isDirectory: true)
        try? FileManager.default.createDirectory(at: booksDir, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    func jsonURL(for bookId: String) -> URL {
        booksDir.appendingPathComponent("\(bookId).json")
    }

    func isDownloaded(_ bookId: String) -> Bool {
        FileManager.default.fileExists(atPath: jsonURL(for: bookId).path)
    }

    func state(for bookId: String) -> TafsirDownloadState {
        states[bookId] ?? (isDownloaded(bookId) ? .downloaded : .notDownloaded)
    }

    /// Downloads the complete tafsir for a book (all 114 chapters).
    /// Only works for books where canDownload == true. Translations are per-verse only.
    func download(bookId: String) {
        guard let book = TafsirBook.find(id: bookId), book.canDownload else { return }

        guard !isDownloaded(bookId) else {
            DispatchQueue.main.async { self.states[bookId] = .downloaded }
            return
        }
        guard states[bookId] == nil || states[bookId] == .notDownloaded else { return }

        DispatchQueue.main.async { self.states[bookId] = .downloading(progress: 0) }

        Task.detached(priority: .userInitiated) { [weak self] in
            await self?.downloadAllChapters(bookId: bookId, source: book.source)
        }
    }

    func cancel(bookId: String) {
        DispatchQueue.main.async { self.states[bookId] = .notDownloaded }
    }

    func delete(bookId: String) {
        try? FileManager.default.removeItem(at: jsonURL(for: bookId))
        TafsirService.shared.evict(bookId: bookId)
        DispatchQueue.main.async { self.states[bookId] = .notDownloaded }
    }

    // MARK: - Private

    private func downloadAllChapters(bookId: String, source: TafsirSource) async {
        var combined: [String: String] = [:]
        let total = 114
        let batchSize = 10

        for batchStart in stride(from: 1, through: total, by: batchSize) {
            let batchEnd = min(batchStart + batchSize - 1, total)

            await withTaskGroup(of: [String: String].self) { group in
                for chapter in batchStart...batchEnd {
                    group.addTask {
                        switch source {
                        case .quranEnc(let slug):
                            return await Self.fetchQuranEncChapter(slug: slug, chapter: chapter)
                        case .quranCom(let id):
                            return await Self.fetchQuranComChapter(tafsirId: id, chapter: chapter)
                        case .translation:
                            return [:]
                        }
                    }
                }

                for await verses in group {
                    combined.merge(verses) { _, new in new }
                }
            }

            let progress = Double(batchEnd) / Double(total)
            await MainActor.run { self.states[bookId] = .downloading(progress: progress) }
        }

        do {
            let data = try JSONEncoder().encode(combined)
            try data.write(to: jsonURL(for: bookId), options: .atomic)
            TafsirService.shared.loadDownloaded(bookId: bookId, dict: combined)
            await MainActor.run { self.states[bookId] = .downloaded }
        } catch {
            await MainActor.run { self.states[bookId] = .failed(error.localizedDescription) }
        }
    }

    // quranenc.com — /translation/sura/{slug}/{chapter} → plain text
    private static func fetchQuranEncChapter(slug: String, chapter: Int) async -> [String: String] {
        let urlStr = "https://quranenc.com/api/v1/translation/sura/\(slug)/\(chapter)"
        guard let url = URL(string: urlStr),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response  = try? JSONDecoder().decode(QuranEncSuraResponse.self, from: data)
        else { return [:] }

        var verses: [String: String] = [:]
        for entry in response.result {
            guard let s = Int(entry.sura), let v = Int(entry.aya) else { continue }
            verses["\(s)_\(v)"] = entry.translation
        }
        return verses
    }

    // api.quran.com — /tafsirs/{id}/by_chapter/{chapter} → HTML, needs stripping
    private static func fetchQuranComChapter(tafsirId: Int, chapter: Int) async -> [String: String] {
        let urlStr = "https://api.quran.com/api/v4/tafsirs/\(tafsirId)/by_chapter/\(chapter)"
        guard let url = URL(string: urlStr),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let response  = try? quranComDecoder.decode(ChapterTafsirResponse.self, from: data)
        else { return [:] }

        var verses: [String: String] = [:]
        for entry in response.tafsirs {
            let parts = entry.verseKey.split(separator: ":")
            guard parts.count == 2,
                  let s = Int(parts[0]),
                  let v = Int(parts[1]) else { continue }
            verses["\(s)_\(v)"] = entry.text.strippingHTML()
        }
        return verses
    }

    private static let quranComDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
}

// MARK: - DTOs

private struct QuranEncSuraResponse: Codable {
    let result: [QuranEncEntry]
}

private struct ChapterTafsirResponse: Codable {
    let tafsirs: [VerseTafsirEntry]
}

private struct VerseTafsirEntry: Codable {
    let verseKey: String   // verse_key → verseKey via convertFromSnakeCase
    let text: String
}
