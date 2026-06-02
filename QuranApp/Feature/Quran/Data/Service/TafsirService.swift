//
//  TafsirService.swift
//  QuranApp
//

import Foundation
import Core

final class TafsirService {

    static let shared = TafsirService()

    // NSCache for per-verse lookups (all sources) — NSCache is thread-safe
    private let cache = NSCache<NSString, NSString>()

    // User-downloaded book data (loaded lazily from Documents)
    // Key: bookId → {"surah_verse": "text"}
    // Protected by dataLock — Swift Dictionary is NOT thread-safe
    private let dataLock = NSLock()
    private var downloadedData: [String: [String: String]] = [:]

    private let quranComDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private init() {
        cache.countLimit = 600
    }

    // MARK: - Public

    /// Returns tafsir text for a verse.
    /// - Bundled books (ar-mokhtasar) → instant, from app bundle.
    /// - Downloaded books → instant, from Documents.
    /// - Everything else → live API call (can throw on failure).
    func fetch(bookId: String, surah: Int, verse: Int) async throws -> String {
        // 1. Bundle — bundled books are always available
        if let dict = loadFromBundle(bookId: bookId) {
            return lookup(dict: dict, bookId: bookId, surah: surah, verse: verse)
        }

        // 2. Hot cache — copy out under lock, then release before any await
        let hotDict: [String: String]? = { dataLock.lock(); defer { dataLock.unlock() }
            return downloadedData[bookId]
        }()
        if let dict = hotDict {
            return lookup(dict: dict, bookId: bookId, surah: surah, verse: verse)
        }

        // 3. Cold disk — I/O runs unlocked; only the resulting write is locked
        if let dict = loadFromDisk(bookId: bookId) {
            return lookup(dict: dict, bookId: bookId, surah: surah, verse: verse)
        }

        // 4. Live API (translations only — other books require pre-download)
        return try await fetchRemote(bookId: bookId, surah: surah, verse: verse)
    }

    /// Synchronous lookup for bundled or already-downloaded books.
    /// Returns nil if the book needs a network call.
    func fetchSync(bookId: String, surah: Int, verse: Int) -> String? {
        if let dict = loadFromBundle(bookId: bookId) {
            return lookup(dict: dict, bookId: bookId, surah: surah, verse: verse)
        }
        let hotDict: [String: String]? = { dataLock.lock(); defer { dataLock.unlock() }
            return downloadedData[bookId]
        }()
        if let dict = hotDict {
            return lookup(dict: dict, bookId: bookId, surah: surah, verse: verse)
        }
        if let dict = loadFromDisk(bookId: bookId) {
            return lookup(dict: dict, bookId: bookId, surah: surah, verse: verse)
        }
        return nil
    }

    /// Called by TafsirDownloadManager once a download is complete.
    func loadDownloaded(bookId: String, dict: [String: String]) {
        dataLock.lock()
        downloadedData[bookId] = dict
        dataLock.unlock()
    }

    /// Called by TafsirDownloadManager when a book is deleted.
    func evict(bookId: String) {
        dataLock.lock()
        downloadedData.removeValue(forKey: bookId)
        dataLock.unlock()
        cache.removeAllObjects()
    }

    func invalidateCache() {
        cache.removeAllObjects()
    }

    // MARK: - Private

    private func lookup(dict: [String: String], bookId: String, surah: Int, verse: Int) -> String {
        let cacheKey = "\(bookId)/\(surah):\(verse)" as NSString
        if let hit = cache.object(forKey: cacheKey) { return hit as String }
        let text = dict["\(surah)_\(verse)"] ?? ""
        cache.setObject(text as NSString, forKey: cacheKey)
        return text
    }

    private func loadFromBundle(bookId: String) -> [String: String]? {
        guard TafsirBook.find(id: bookId)?.isBundle == true else { return nil }
        // Return from hot cache if already loaded
        let hotDict: [String: String]? = { dataLock.lock(); defer { dataLock.unlock() }
            return downloadedData[bookId]
        }()
        if let dict = hotDict { return dict }
        // Load from the app bundle
        guard let url = Bundle.main.url(forResource: bookId, withExtension: "json"),
              let raw  = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: raw)
        else { return nil }
        dataLock.lock()
        downloadedData[bookId] = dict
        dataLock.unlock()
        return dict
    }

    private func loadFromDisk(bookId: String) -> [String: String]? {
        let url = TafsirDownloadManager.shared.jsonURL(for: bookId)
        // I/O runs without the lock — reading the file is thread-safe
        guard FileManager.default.fileExists(atPath: url.path),
              let raw  = try? Data(contentsOf: url),
              let dict = try? JSONDecoder().decode([String: String].self, from: raw)
        else { return nil }
        // Only the mutation is locked
        dataLock.lock()
        downloadedData[bookId] = dict
        dataLock.unlock()
        return dict
    }

    private func fetchRemote(bookId: String, surah: Int, verse: Int) async throws -> String {
        let cacheKey = "\(bookId)/\(surah):\(verse)" as NSString
        if let hit = cache.object(forKey: cacheKey) { return hit as String }

        guard let book = TafsirBook.find(id: bookId) else { throw TafsirError.bookNotFound }

        let text: String
        switch book.source {
        case .quranEnc(let slug):
            text = try await fetchQuranEnc(slug: slug, surah: surah, verse: verse)
        case .quranCom(let id):
            text = try await fetchQuranCom(tafsirId: id, surah: surah, verse: verse)
        case .translation(let id):
            text = try await fetchTranslation(translationId: id, surah: surah, verse: verse)
        }

        cache.setObject(text as NSString, forKey: cacheKey)
        return text
    }

    // quranenc.com — returns plain text, no HTML stripping needed
    private func fetchQuranEnc(slug: String, surah: Int, verse: Int) async throws -> String {
        let urlString = "https://quranenc.com/api/v1/translation/aya/\(slug)/\(surah)/\(verse)"
        guard let url = URL(string: urlString) else { throw TafsirError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response  = try JSONDecoder().decode(QuranEncAyahResponse.self, from: data)
        return response.result.translation
    }

    // api.quran.com — tafsir (Arabic) — HTML needs stripping
    private func fetchQuranCom(tafsirId: Int, surah: Int, verse: Int) async throws -> String {
        let urlString = "https://api.quran.com/api/v4/tafsirs/\(tafsirId)/by_ayah/\(surah):\(verse)"
        guard let url = URL(string: urlString) else { throw TafsirError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response  = try quranComDecoder.decode(QuranComTafsirResponse.self, from: data)
        return response.tafsir.text.strippingHTML()
    }

    // api.quran.com — translation — HTML needs stripping
    private func fetchTranslation(translationId: Int, surah: Int, verse: Int) async throws -> String {
        let urlString = "https://api.quran.com/api/v4/translations/\(translationId)/by_ayah/\(surah):\(verse)"
        guard let url = URL(string: urlString) else { throw TafsirError.invalidURL }
        let (data, _) = try await URLSession.shared.data(from: url)
        let response  = try quranComDecoder.decode(TranslationAPIResponse.self, from: data)
        return response.translations.first?.text.strippingHTML() ?? ""
    }
}

// MARK: - quranenc.com DTOs

private struct QuranEncAyahResponse: Codable {
    let result: QuranEncEntry
}

struct QuranEncEntry: Codable {
    let sura: String
    let aya: String
    let translation: String
}

private struct QuranEncSuraResponse: Codable {
    let result: [QuranEncEntry]
}

// MARK: - quran.com DTOs

private struct QuranComTafsirResponse: Codable {
    let tafsir: TafsirPayload
}

private struct TafsirPayload: Codable {
    let text: String
}

private struct TranslationAPIResponse: Codable {
    let translations: [TranslationEntry]
}

private struct TranslationEntry: Codable {
    let text: String
}

// MARK: - Error

enum TafsirError: LocalizedError {
    case invalidURL
    case noData
    case bookNotFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:   return "Invalid URL"
        case .noData:       return "No tafsir data available"
        case .bookNotFound: return "Book not found in catalogue"
        }
    }
}

// MARK: - HTML Stripping (internal so TafsirDownloadManager can use it)

extension String {
    func strippingHTML() -> String {
        var result = self
        result = result.replacingOccurrences(of: "<sup[^>]*>.*?</sup>", with: "", options: [.regularExpression, .caseInsensitive])
        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&nbsp;", " "),
            ("&laquo;", "«"), ("&raquo;", "»"),
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
