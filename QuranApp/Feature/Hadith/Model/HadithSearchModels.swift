//
//  HadithSearchModels.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation

// MARK: - Matches in one book

struct HadithBookMatches: Identifiable {
    let book: HadithBook
    let results: [HadithSearchResult]
    let totalMatches: Int
    let isTotalApproximate: Bool

    var id: Int { book.id }
    var hasMore: Bool { results.count < totalMatches }
}

// MARK: - Outcome

struct HadithSearchOutcome {
    let query: HadithSearchQuery?
    let books: [HadithBookMatches]
    let notInstalled: [HadithBook]

    static let empty = HadithSearchOutcome(query: nil, books: [], notInstalled: [])

    var isEmpty: Bool { books.isEmpty }
    var totalMatches: Int { books.reduce(0) { $0 + $1.totalMatches } }
    var isTotalApproximate: Bool { books.contains(where: \.isTotalApproximate) }

    func replacing(_ matches: HadithBookMatches) -> HadithSearchOutcome {
        guard let index = books.firstIndex(where: { $0.id == matches.id }) else { return self }
        var updated = books
        updated[index] = matches
        return HadithSearchOutcome(query: query, books: updated, notInstalled: notInstalled)
    }
}

// MARK: - Phase

enum HadithSearchPhase: Equatable {
    case idle
    case tooShort
    case running
    case results
    case noResults
}
