//
//  GlobalSearchModels.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

// MARK: - Scope

enum GlobalSearchScope: String, CaseIterable, Identifiable {

    case all
    case surah
    case verse
    case narration
    case dhikr

    var id: String { rawValue }

    static var corpusScopes: [GlobalSearchScope] { [.surah, .verse, .narration, .dhikr] }

    var isCorpus: Bool { self != .all }

    func includes(_ scope: GlobalSearchScope) -> Bool {
        self == .all || self == scope
    }
}

// MARK: - Destination

enum GlobalSearchDestination {

    case surah(startPage: Int)
    case verse(QuranVerseReference)
    case narration(HadithSearchResult)
    case dhikr(packKey: String, itemID: Int)
}

// MARK: - Quran target

enum GlobalSearchQuranTarget {

    case page(Int)
    case verse(QuranVerseReference)
}

// MARK: - Hit

struct GlobalSearchHit: Identifiable {

    let id: String
    let scope: GlobalSearchScope
    let title: String
    let detail: String
    let snippet: String
    let isSnippetArabicScript: Bool
    let destination: GlobalSearchDestination
}

// MARK: - Section

struct GlobalSearchSection: Identifiable {

    let scope: GlobalSearchScope
    let hits: [GlobalSearchHit]
    let matchCount: Int

    var id: String { scope.rawValue }

    var isTruncated: Bool { hits.count < matchCount }
}

// MARK: - Raw corpus results

struct GlobalSearchRawResults {

    let query: String
    let surahs: [SurahNameMatch]
    let surahMatchCount: Int
    let verses: [QuranSearchResult]
    let verseMatchCount: Int
    let narrations: HadithSearchOutcome
    let dhikr: [AthkarSearchHit]
    let dhikrMatchCount: Int

    static let empty = GlobalSearchRawResults(query: "",
                                              surahs: [],
                                              surahMatchCount: 0,
                                              verses: [],
                                              verseMatchCount: 0,
                                              narrations: .empty,
                                              dhikr: [],
                                              dhikrMatchCount: 0)

    var isEmpty: Bool {
        surahs.isEmpty && verses.isEmpty && narrations.isEmpty && dhikr.isEmpty
    }
}

// MARK: - Outcome

struct GlobalSearchOutcome {

    let query: String
    let sections: [GlobalSearchSection]
    let narrationQuery: HadithSearchQuery?
    let uninstalledNarrationBooks: [HadithBook]

    static let empty = GlobalSearchOutcome(query: "",
                                           sections: [],
                                           narrationQuery: nil,
                                           uninstalledNarrationBooks: [])

    var hits: [GlobalSearchHit] { sections.flatMap(\.hits) }

    var isEmpty: Bool { hits.isEmpty }

    var matchCount: Int { sections.reduce(0) { $0 + $1.matchCount } }

    func section(_ scope: GlobalSearchScope) -> GlobalSearchSection? {
        sections.first { $0.scope == scope }
    }
}

// MARK: - Phase

enum GlobalSearchPhase: Equatable {

    case idle
    case tooShort
    case running
    case results
    case noResults
}
