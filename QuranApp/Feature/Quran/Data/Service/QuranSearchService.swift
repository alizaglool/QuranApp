//
//  QuranSearchService.swift
//  QuranApp
//

import Foundation

struct QuranSearchResult: Identifiable {
    let id: String
    let surahNumber: Int
    let verseNumber: Int
    let surahName: String
    let page: Int
    let text: String
}

final class QuranSearchService {

    static let shared = QuranSearchService()

    private struct Entry {
        let surah: Int
        let verse: Int
        let normalized: String
        let original: String
        let surahName: String
    }

    private var index: [Entry] = []

    private static let diacritics: CharacterSet = {
        // Tashkeel U+064B–U+065F and tatweel U+0640 and alef-wasla superscript U+0670
        var cs = CharacterSet()
        cs.insert(charactersIn: Unicode.Scalar(0x064B)! ... Unicode.Scalar(0x065F)!)
        cs.insert(Unicode.Scalar(0x0640)!)
        cs.insert(Unicode.Scalar(0x0670)!)
        return cs
    }()

    private init() {
        buildIndex()
    }

    // MARK: - Index

    private func buildIndex() {
        for surah in 1...114 {
            let count = ReciterLibrary.verseCounts[surah] ?? 7
            let name = ReciterLibrary.surahArabicNames[surah] ?? ""
            for verse in 1...max(1, count) {
                guard let text = QuranTextService.shared.text(surah: surah, verse: verse) else { continue }
                index.append(Entry(
                    surah: surah,
                    verse: verse,
                    normalized: Self.normalize(text),
                    original: text,
                    surahName: name
                ))
            }
        }
    }

    static func normalize(_ text: String) -> String {
        var s = text.components(separatedBy: diacritics).joined()
        s = s
            .replacingOccurrences(of: "أ", with: "ا")
            .replacingOccurrences(of: "إ", with: "ا")
            .replacingOccurrences(of: "آ", with: "ا")
            .replacingOccurrences(of: "ٱ", with: "ا")
            .replacingOccurrences(of: "ة", with: "ه")
        return s
    }

    // MARK: - Search

    func search(_ query: String, limit: Int = 80) -> [QuranSearchResult] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        let normalizedQuery = Self.normalize(q)

        var results: [QuranSearchResult] = []
        for entry in index {
            guard entry.normalized.contains(normalizedQuery) else { continue }
            let page = QuranDatabase.shared.getPage(forSurah: entry.surah, verse: entry.verse)
            results.append(QuranSearchResult(
                id: "\(entry.surah)_\(entry.verse)",
                surahNumber: entry.surah,
                verseNumber: entry.verse,
                surahName: entry.surahName,
                page: page,
                text: entry.original
            ))
            if results.count >= limit { break }
        }
        return results
    }
}
