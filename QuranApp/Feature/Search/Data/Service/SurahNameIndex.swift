//
//  SurahNameIndex.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct SurahNameMatch: Identifiable {

    let surah: SurahInfo

    var id: Int { surah.id }
}

final class SurahNameIndex {

    static let shared = SurahNameIndex()

    private struct Entry {
        let surah: SurahInfo
        let normalizedArabicTitle: String
        let foldedEnglishTitle: String
        let number: String
    }

    private let database: QuranDatabase
    private var entries: [Entry] = []
    private var isLoaded = false
    private let lock = NSLock()

    init(database: QuranDatabase = .shared) {
        self.database = database
    }

    // MARK: - Search

    func search(_ query: String, limit: Int = 20) -> [SurahNameMatch] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let normalizedArabic = QuranSearchService.normalize(trimmed)
        let foldedLatin = Self.fold(trimmed)
        let digits = Self.westernDigits(trimmed)
        let isNumberQuery = !digits.isEmpty && digits.count == trimmed.count

        guard isNumberQuery || normalizedArabic.count >= 2 || foldedLatin.count >= 2 else { return [] }

        var exact: [SurahNameMatch] = []
        var prefixed: [SurahNameMatch] = []
        var contained: [SurahNameMatch] = []

        for entry in loadedEntries() {
            guard let rank = Self.rank(entry,
                                       normalizedArabic: normalizedArabic,
                                       foldedLatin: foldedLatin,
                                       digits: isNumberQuery ? digits : "")
            else { continue }
            switch rank {
            case .exact: exact.append(SurahNameMatch(surah: entry.surah))
            case .prefix: prefixed.append(SurahNameMatch(surah: entry.surah))
            case .contains: contained.append(SurahNameMatch(surah: entry.surah))
            }
        }

        return Array((exact + prefixed + contained).prefix(limit))
    }

    // MARK: - Ranking

    private enum MatchRank {
        case exact
        case prefix
        case contains
    }

    private static func rank(_ entry: Entry,
                             normalizedArabic: String,
                             foldedLatin: String,
                             digits: String) -> MatchRank? {
        if !digits.isEmpty {
            if entry.number == digits { return .exact }
            if entry.number.hasPrefix(digits) { return .prefix }
        }

        var best: MatchRank?
        for candidate in [entry.normalizedArabicTitle, entry.foldedEnglishTitle] {
            guard !candidate.isEmpty else { continue }
            for needle in [normalizedArabic, foldedLatin] where needle.count >= 2 {
                if candidate == needle { return .exact }
                if candidate.hasPrefix(needle) {
                    best = .prefix
                } else if candidate.contains(needle), best == nil {
                    best = .contains
                }
            }
        }
        return best
    }

    // MARK: - Loading

    private func loadedEntries() -> [Entry] {
        lock.lock()
        defer { lock.unlock() }
        if isLoaded { return entries }
        entries = database.getAllSurahs().map { surah in
            Entry(surah: surah,
                  normalizedArabicTitle: QuranSearchService.normalize(surah.arabicTitle),
                  foldedEnglishTitle: Self.fold(surah.englishTitle),
                  number: String(surah.id))
        }
        isLoaded = true
        return entries
    }

    // MARK: - Normalization

    private static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive],
                     locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\u{2018}", with: "")
            .replacingOccurrences(of: "\u{2019}", with: "")
            .replacingOccurrences(of: "al ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func westernDigits(_ text: String) -> String {
        var digits = ""
        for character in text {
            guard let value = character.wholeNumberValue, (0...9).contains(value) else { continue }
            digits.append(String(value))
        }
        return digits
    }
}
