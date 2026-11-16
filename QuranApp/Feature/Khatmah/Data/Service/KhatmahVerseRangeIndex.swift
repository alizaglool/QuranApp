//
//  KhatmahVerseRangeIndex.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

// MARK: - KhatmahVerseRangeIndex

actor KhatmahVerseRangeIndex {

    static let shared = KhatmahVerseRangeIndex()

    private struct PageBounds {
        let firstSurahNumber: Int
        let firstVerseNumber: Int
        let lastSurahNumber: Int
        let lastVerseNumber: Int
    }

    private var boundsByPage: [Int: PageBounds] = [:]
    private var arabicNamesBySurah: [Int: String] = [:]
    private var englishNamesBySurah: [Int: String] = [:]
    private var isLoaded = false

    // MARK: - Lookups

    func range(fromPage firstPage: Int, toPage lastPage: Int, isArabic: Bool) -> KhatmahVerseRange? {
        loadIfNeeded()
        return makeRange(fromPage: firstPage, toPage: lastPage, isArabic: isArabic)
    }

    func ranges(forPageSpans spans: [Int: ClosedRange<Int>], isArabic: Bool) -> [Int: KhatmahVerseRange] {
        loadIfNeeded()
        var result: [Int: KhatmahVerseRange] = [:]
        for (key, span) in spans {
            guard let range = makeRange(fromPage: span.lowerBound, toPage: span.upperBound, isArabic: isArabic) else { continue }
            result[key] = range
        }
        return result
    }

    func startPoints(ofPages pages: [Int], isArabic: Bool) -> [Int: KhatmahVersePoint] {
        loadIfNeeded()
        var result: [Int: KhatmahVersePoint] = [:]
        for page in pages {
            guard let bounds = boundsByPage[page] else { continue }
            result[page] = point(surahNumber: bounds.firstSurahNumber, verseNumber: bounds.firstVerseNumber, page: page, isArabic: isArabic)
        }
        return result
    }

    // MARK: - Building

    private func makeRange(fromPage firstPage: Int, toPage lastPage: Int, isArabic: Bool) -> KhatmahVerseRange? {
        guard firstPage <= lastPage,
              let startBounds = boundsByPage[firstPage],
              let endBounds = boundsByPage[lastPage] else { return nil }

        return KhatmahVerseRange(
            start: point(surahNumber: startBounds.firstSurahNumber, verseNumber: startBounds.firstVerseNumber, page: firstPage, isArabic: isArabic),
            end: point(surahNumber: endBounds.lastSurahNumber, verseNumber: endBounds.lastVerseNumber, page: lastPage, isArabic: isArabic)
        )
    }

    private func point(surahNumber: Int, verseNumber: Int, page: Int, isArabic: Bool) -> KhatmahVersePoint {
        let names = isArabic ? arabicNamesBySurah : englishNamesBySurah
        return KhatmahVersePoint(
            surahNumber: surahNumber,
            surahName: names[surahNumber] ?? "",
            verseNumber: verseNumber,
            page: page
        )
    }

    private func loadIfNeeded() {
        guard !isLoaded else { return }
        isLoaded = true

        let database = QuranDatabase.shared

        for surah in database.getAllSurahs() {
            arabicNamesBySurah[surah.identifier] = surah.arabicTitle
            englishNamesBySurah[surah.identifier] = surah.englishTitle
        }

        let references = database.getPageVerseReferences(
            fromPage: KhatmahPageBounds.firstPage,
            toPage: KhatmahPageBounds.lastPage
        )

        for reference in references {
            if let existing = boundsByPage[reference.page] {
                boundsByPage[reference.page] = PageBounds(
                    firstSurahNumber: existing.firstSurahNumber,
                    firstVerseNumber: existing.firstVerseNumber,
                    lastSurahNumber: reference.chapterNumber,
                    lastVerseNumber: reference.verseNumber
                )
            } else {
                boundsByPage[reference.page] = PageBounds(
                    firstSurahNumber: reference.chapterNumber,
                    firstVerseNumber: reference.verseNumber,
                    lastSurahNumber: reference.chapterNumber,
                    lastVerseNumber: reference.verseNumber
                )
            }
        }
    }
}
