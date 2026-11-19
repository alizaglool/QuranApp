//
//  GlobalSearchService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

final class GlobalSearchService {

    static let shared = GlobalSearchService()

    static let minimumQueryLength = 2

    private enum Limit {
        static let surahs = 20
        static let verses = 60
        static let dhikr = 60
    }

    private let surahIndex: SurahNameIndex
    private let verseService: QuranSearchService
    private let narrationService: HadithDatabaseService
    private let dhikrStore: AthkarPackStore
    private let manifestService: AthkarManifestService

    init(surahIndex: SurahNameIndex = .shared,
         verseService: QuranSearchService = .shared,
         narrationService: HadithDatabaseService = .shared,
         dhikrStore: AthkarPackStore = .shared,
         manifestService: AthkarManifestService = .shared) {
        self.surahIndex = surahIndex
        self.verseService = verseService
        self.narrationService = narrationService
        self.dhikrStore = dhikrStore
        self.manifestService = manifestService
    }

    // MARK: - Query validation

    static func isQueryLongEnough(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.allSatisfy({ $0.wholeNumberValue != nil }) { return true }
        return QuranSearchService.normalize(trimmed).count >= minimumQueryLength
            || trimmed.count >= minimumQueryLength
    }

    // MARK: - Search

    func search(_ query: String, scope: GlobalSearchScope) -> GlobalSearchRawResults {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isQueryLongEnough(trimmed) else { return .empty }

        let surahs = scope.includes(.surah) ? surahIndex.search(trimmed, limit: Limit.surahs) : []
        let verses = scope.includes(.verse) ? verseService.search(trimmed, limit: Limit.verses) : []
        let narrations = scope.includes(.narration) ? searchNarrations(trimmed) : .empty
        let dhikr = scope.includes(.dhikr) ? searchDhikr(trimmed) : []

        return GlobalSearchRawResults(query: trimmed,
                                      surahs: surahs,
                                      surahMatchCount: surahs.count,
                                      verses: verses,
                                      verseMatchCount: verses.count,
                                      narrations: narrations,
                                      dhikr: dhikr,
                                      dhikrMatchCount: dhikr.count)
    }

    // MARK: - Narrations

    private func searchNarrations(_ query: String) -> HadithSearchOutcome {
        guard let narrationQuery = HadithSearchQuery(query) else { return .empty }
        return narrationService.searchAllBooks(narrationQuery)
    }

    // MARK: - Adhkar

    private func searchDhikr(_ query: String) -> [AthkarSearchHit] {
        let packs = manifestService.load().packs
            .filter { !AthkarHubCatalog.excludedKeys.contains($0.key) }
            .sorted { $0.sort < $1.sort }
        guard !packs.isEmpty else { return [] }
        return dhikrStore.search(query, in: packs, limit: Limit.dhikr)
    }
}
