//
//  HadithReference.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation

// MARK: - Ruling

/// One scholar's verdict on a hadith, from the `Ahkam` table.
///
/// This is not the same thing as `HadithEntry.grade`: that one is al-Albani's
/// ruling, which the books carry inline in the body. These are the verdicts of
/// other scholars — al-Nawawi, Ibn Hajar — and each cites where it was written.
struct HadithRuling: Identifiable, Hashable {
    let id: Int
    let text: String
    let scholar: String
    /// The work the verdict appears in. Often empty.
    let source: String
}

// MARK: - Takhrij

/// One place the same report appears, from the `Takhrig` table.
struct HadithTakhrijEntry: Identifiable, Hashable {
    let id: Int
    /// The book it appears in, on the same numbering as `HadithBook.id`, so a
    /// reference can open that book when the reader has it installed.
    let bookId: Int
    let bookName: String
    let hadithNumber: String
    /// The corpus' own classification code. It is kept as the raw value because
    /// the corpus ships no legend for it; grouping and sorting use it, nothing
    /// is shown to the reader that claims to know what it means.
    let kind: Int
}

/// Every place one report appears in a single other book.
///
/// A hadith can carry hundreds of takhrij rows, most of them several numbers in
/// the same book, so the reading view shows one row per book rather than one
/// row per reference.
struct HadithTakhrijGroup: Identifiable, Hashable {
    let bookId: Int
    let bookName: String
    let numbers: [String]
    /// True when the reference points back into the book being read.
    let isSameBook: Bool

    var id: Int { bookId }

    var numbersLabel: String { numbers.joined(separator: "، ") }
}

// MARK: - Rare words

/// A rare word and what it means, from `ghareeb_words`.
///
/// The table stores only the meaning; the word itself comes from the markup
/// span that points at it.
struct HadithGhareebMeaning: Identifiable, Hashable {
    let id: Int
    let word: String
    let meaning: String
}

// MARK: - Narrator

/// What one scholar said about a transmitter, from `RwahAqwal`.
struct HadithNarratorVerdict: Identifiable, Hashable {
    let id: Int
    let scholar: String
    let scholarKnownAs: String
    let verdict: String

    /// The scholar's better-known name when there is one.
    var scholarLabel: String { scholarKnownAs.isEmpty ? scholar : scholarKnownAs }
}

/// A transmitter's biography, from `Rwah` and its two satellite tables.
///
/// Reached only through a `/1` or `/9` markup span — the corpus has no foreign
/// key from a hadith to its transmitters, the chain itself is the link.
struct HadithNarratorProfile: Identifiable, Hashable {
    let id: Int
    let name: String
    let shortName: String
    /// أبو فلان
    let kunya: String
    /// The lineage.
    let lineage: String
    /// The epithet.
    let epithet: String
    /// The name they are best known by.
    let knownAs: String
    /// The generation they belong to.
    let generation: String
    let country: String
    let birthYear: String
    let deathYear: String
    let birthPlace: String
    let deathPlace: String
    let notes: String
    let source: String
    /// Ibn Hajar's verdict, which the corpus singles out from the rest.
    let ibnHajarVerdict: String
    /// A prose summary of the verdicts below.
    let verdictsSummary: String
    let verdicts: [HadithNarratorVerdict]
    /// The works this biography was compiled from.
    let sources: [String]

    /// The best name to show in a title.
    var displayName: String {
        if !name.isEmpty { return name }
        if !knownAs.isEmpty { return knownAs }
        return shortName
    }

    /// Born–died, as `"١٠ هـ - ٩٣ هـ"`, or whichever half is known.
    var lifespan: String {
        switch (birthYear.isEmpty, deathYear.isEmpty) {
        case (false, false): return "\(birthYear) - \(deathYear)"
        case (false, true):  return birthYear
        case (true, false):  return deathYear
        case (true, true):   return ""
        }
    }

    var isEmpty: Bool { displayName.isEmpty }
}

// MARK: - Full detail

/// Everything the corpus holds about one hadith beyond its body.
///
/// Loaded on demand, because a hadith can carry hundreds of takhrij rows and
/// the index and chapter views need none of it.
struct HadithDetail: Hashable {
    let entry: HadithEntry
    let rulings: [HadithRuling]
    let takhrij: [HadithTakhrijGroup]
    let ghareeb: [HadithGhareebMeaning]

    static func bare(_ entry: HadithEntry) -> HadithDetail {
        HadithDetail(entry: entry, rulings: [], takhrij: [], ghareeb: [])
    }

    /// True when there is nothing to show under the body.
    var isBare: Bool { rulings.isEmpty && takhrij.isEmpty && ghareeb.isEmpty }

    /// Every reference, less the ones pointing back into the same book.
    var crossReferences: [HadithTakhrijGroup] { takhrij.filter { !$0.isSameBook } }
}
