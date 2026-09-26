//
//  QuranSearchService.swift
//  QuranApp
//

import Foundation
import SQLite3

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
        let page: Int
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

    /// The five 1-character substitutions `normalize(_:)` applies, as a lookup.
    /// Keyed by `Character`, not `Unicode.Scalar`, because `replacingOccurrences`
    /// matches whole grapheme clusters — see `normalizeWithMap(_:)`.
    private static let substitutions: [Character: Character] = [
        "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا", "ة": "ه"
    ]

    private init() {
        buildIndex()
    }

    // MARK: - Index

    private func buildIndex() {
        let pages = Self.loadPageMap()
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
                    surahName: name,
                    page: pages[surah * 1000 + verse]
                        ?? QuranDatabase.shared.getPage(forSurah: surah, verse: verse)
                ))
            }
        }
    }

    /// Every verse's page in ONE query, keyed `surah * 1000 + verse`.
    ///
    /// `search()` used to call `QuranDatabase.getPage(forSurah:verse:)` per result
    /// row — two uncached SQLite queries each, on the same connection the main
    /// thread uses to render the mushaf, i.e. up to 160 synchronous queries per
    /// keystroke. Inline search renders over the live page, so that cost is paid
    /// once here instead. Own read-only connection, opened and closed in this
    /// scope, so the shared connection is never contended.
    private static func loadPageMap() -> [Int: Int] {
        guard let path = Bundle.main.path(forResource: "quran_positioning", ofType: "db") else {
            return [:]
        }

        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return [:]
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let query = "SELECT chapterNumber, number, page1441 FROM verse"
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [:] }

        var map: [Int: Int] = [:]
        map.reserveCapacity(6300)
        while sqlite3_step(stmt) == SQLITE_ROW {
            let surah = Int(sqlite3_column_int(stmt, 0))
            let verse = Int(sqlite3_column_int(stmt, 1))
            map[surah * 1000 + verse] = Int(sqlite3_column_int(stmt, 2))
        }
        return map
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

    /// `normalize(_:)` re-expressed so each normalized character can be traced back
    /// to the original character that produced it. Output is byte-identical to
    /// `normalize(_:)` — asserted over all 6,236 verses in `QuranSearchServiceTests`.
    ///
    /// Needed because the mushaf DISPLAYS Uthmani (`ٱلَّذِينَ`) but MATCHES on the
    /// normalized form (`الذين`). The two strings share neither length nor
    /// characters, so a range found in one is meaningless in the other and
    /// `range(of:)` cannot locate a match for highlighting.
    ///
    /// The two passes mirror `normalize(_:)` exactly, and the order matters:
    ///
    /// 1. `components(separatedBy: diacritics).joined()` deletes SCALARS.
    /// 2. The five `replacingOccurrences` calls substitute whole GRAPHEME CLUSTERS —
    ///    a single-character needle never matches the base of a cluster that carries
    ///    combining marks. That is why `نَعْجَةٍۭ` keeps its `ة`: the surviving
    ///    U+06ED waqf mark leaves `ة` inside a two-scalar cluster. 843 of the 6,236
    ///    verses depend on this; a scalar-by-scalar substitution diverges on them.
    ///
    /// - Returns: the normalized string, and a parallel array where `map[i]` is the
    ///   index in `text` of the character that produced `normalized[i]`.
    ///   `map.count == normalized.count`, and `map` is non-decreasing.
    static func normalizeWithMap(_ text: String) -> (normalized: String, map: [String.Index]) {
        // Pass 1 — delete diacritic scalars, recording which source character each
        // surviving scalar came from.
        var survivors = String.UnicodeScalarView()
        var origin: [String.Index] = []
        var cursor = text.startIndex
        while cursor < text.endIndex {
            for scalar in text[cursor].unicodeScalars where !diacritics.contains(scalar) {
                survivors.append(scalar)
                origin.append(cursor)
            }
            cursor = text.index(after: cursor)
        }
        let stripped = String(survivors)

        // Pass 2 — substitute whole clusters, one character in, one character out.
        var normalized = ""
        normalized.reserveCapacity(stripped.count)
        var map: [String.Index] = []
        map.reserveCapacity(stripped.count)
        var scalarOffset = 0
        for character in stripped {
            normalized.append(substitutions[character] ?? character)
            map.append(origin[scalarOffset])
            scalarOffset += character.unicodeScalars.count
        }
        return (normalized, map)
    }

    /// Ranges in `original` covering EVERY occurrence of `query`, ascending and
    /// non-overlapping. Empty when the query does not match.
    static func highlightRanges(in original: String, query: String) -> [Range<String.Index>] {
        let normalizedQuery = normalize(query.trimmingCharacters(in: .whitespaces))
        guard !normalizedQuery.isEmpty else { return [] }

        let (normalized, map) = normalizeWithMap(original)
        let haystack = Array(normalized)
        let needle = Array(normalizedQuery)
        guard !needle.isEmpty, haystack.count >= needle.count else { return [] }

        var ranges: [Range<String.Index>] = []
        var i = 0
        while i <= haystack.count - needle.count {
            guard Array(haystack[i ..< i + needle.count]) == needle else {
                i += 1
                continue
            }

            let lower = map[i]
            var upper = original.index(after: map[i + needle.count - 1])
            // Pull in trailing characters that normalize to nothing — a standalone
            // tatweel or mark cluster. Without this the word's own diacritics fall
            // outside the coloured run and the highlight looks torn.
            while upper < original.endIndex, normalizesToNothing(original[upper]) {
                upper = original.index(after: upper)
            }
            ranges.append(lower ..< upper)
            i += needle.count
        }
        return ranges
    }

    private static func normalizesToNothing(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { diacritics.contains($0) }
    }

    // MARK: - Search

    func search(_ query: String, limit: Int = 80) -> [QuranSearchResult] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }
        let normalizedQuery = Self.normalize(q)

        var results: [QuranSearchResult] = []
        for entry in index {
            guard entry.normalized.contains(normalizedQuery) else { continue }
            results.append(QuranSearchResult(
                id: "\(entry.surah)_\(entry.verse)",
                surahNumber: entry.surah,
                verseNumber: entry.verse,
                surahName: entry.surahName,
                page: entry.page,
                text: entry.original
            ))
            if results.count >= limit { break }
        }
        return results
    }
}
