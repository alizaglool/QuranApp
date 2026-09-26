//
//  QuranSearchServiceTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 26/09/2026.
//

import XCTest
@testable import QuranApp

/// The contract inline search rests on: `normalizeWithMap(_:)` must produce the
/// exact same string as `normalize(_:)`, and `highlightRanges(in:query:)` must
/// return every occurrence. If the first assertion breaks, search recall changes
/// silently. If the second breaks, verses highlight the wrong glyphs.
final class QuranSearchServiceTests: XCTestCase {

    // MARK: - Corpus

    /// The shipped corpus, BOM-stripped exactly as `QuranTextService` strips it.
    private static let corpus: [String: String] = {
        guard
            let url = Bundle(for: QuranSearchServiceTests.self).url(forResource: "quran_text", withExtension: "json")
                ?? Bundle.main.url(forResource: "quran_text", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        // Verse 1:1 carries a leading U+FEFF in this JSON edition.
        return dict.mapValues { $0.hasPrefix("\u{FEFF}") ? String($0.dropFirst()) : $0 }
    }()

    func testCorpusLoaded() {
        XCTAssertEqual(Self.corpus.count, 6236, "quran_text.json must contain all 6,236 verses")
    }

    // MARK: - B.2 — normalizeWithMap is normalize

    /// The load-bearing test. `normalizeWithMap(_:)` exists only to give
    /// `highlightRanges` an index map; the moment its output diverges from
    /// `normalize(_:)` by one character, matching and highlighting disagree.
    ///
    /// This has caught a real regression: a scalar-by-scalar implementation
    /// diverged on 843 verses, because `replacingOccurrences(of: "ة", with: "ه")`
    /// matches whole grapheme clusters and skips a `ة` that still carries a
    /// surviving U+06ED waqf mark (38:23 `نَعْجَةٍۭ`).
    func testNormalizeWithMapEqualsNormalizeForEveryVerse() {
        XCTAssertFalse(Self.corpus.isEmpty, "corpus failed to load — the rest of this test is vacuous")

        var mismatches: [String] = []
        for key in Self.corpus.keys.sorted() {
            let text = Self.corpus[key]!
            let expected = QuranSearchService.normalize(text)
            let actual = QuranSearchService.normalizeWithMap(text).normalized
            if actual != expected, mismatches.count < 10 {
                mismatches.append("\(key): expected \(expected.debugDescription) got \(actual.debugDescription)")
            }
        }
        XCTAssertTrue(mismatches.isEmpty, "normalizeWithMap diverged from normalize:\n" + mismatches.joined(separator: "\n"))
    }

    func testNormalizeWithMapEqualsNormalizeAtScalarLevel() {
        for key in Self.corpus.keys.sorted() {
            let text = Self.corpus[key]!
            XCTAssertEqual(
                Array(QuranSearchService.normalizeWithMap(text).normalized.unicodeScalars),
                Array(QuranSearchService.normalize(text).unicodeScalars),
                "scalar divergence at \(key)"
            )
        }
    }

    /// The map's invariants. `highlightRanges` indexes it by normalized offset and
    /// dereferences the result against the original string, so a short, unsorted
    /// or out-of-bounds map is a crash, not a cosmetic bug.
    func testNormalizeWithMapInvariants() {
        for key in Self.corpus.keys.sorted() {
            let text = Self.corpus[key]!
            let (normalized, map) = QuranSearchService.normalizeWithMap(text)

            XCTAssertEqual(map.count, normalized.count, "map length at \(key)")

            var previous: String.Index?
            for index in map {
                XCTAssertTrue(index >= text.startIndex && index < text.endIndex, "out-of-range index at \(key)")
                if let previous {
                    XCTAssertTrue(index >= previous, "non-monotonic map at \(key)")
                }
                previous = index
            }
        }
    }

    /// 38:23 specifically — the verse that proves pass 2 must substitute whole
    /// `Character`s, not scalars.
    func testGraphemeClusterSubstitutionMatchesNormalize() {
        let verse = "إِنَّ هَٰذَآ أَخِى لَهُۥ تِسْعٌۭ وَتِسْعُونَ نَعْجَةًۭ وَلِىَ نَعْجَةٌۭ وَٰحِدَةٌۭ فَقَالَ أَكْفِلْنِيهَا وَعَزَّنِى فِى ٱلْخِطَابِ"
        XCTAssertEqual(
            QuranSearchService.normalizeWithMap(verse).normalized,
            QuranSearchService.normalize(verse)
        )
    }

    /// The BOM must not survive into either path.
    func testBOMPrefixedTextNormalizesConsistently() {
        let withBOM = "\u{FEFF}بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
        XCTAssertEqual(
            QuranSearchService.normalizeWithMap(withBOM).normalized,
            QuranSearchService.normalize(withBOM)
        )
        XCTAssertFalse(Self.corpus["1_1"]?.hasPrefix("\u{FEFF}") ?? true, "1:1 must be BOM-stripped on load")
    }

    // MARK: - B.3 — highlightRanges

    private let alFatihah1 = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"
    private let alIkhlas1 = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ قُلْ هُوَ ٱللَّهُ أَحَدٌ"

    /// G.3 — EVERY occurrence, not just the first. `range(of:)` would return one.
    func testHighlightRangesReturnsEveryOccurrence() {
        let ranges = QuranSearchService.highlightRanges(in: alIkhlas1, query: "الله")
        XCTAssertEqual(ranges.count, 2, "both ٱللَّهِ and ٱللَّهُ must be ranged")

        let slices = ranges.map { String(alIkhlas1[$0]) }
        for slice in slices {
            XCTAssertTrue(
                QuranSearchService.normalize(slice).hasPrefix("الله"),
                "range does not cover the matched word: \(slice.debugDescription)"
            )
        }
    }

    func testHighlightRangesAreAscendingAndNonOverlapping() {
        let ranges = QuranSearchService.highlightRanges(in: alIkhlas1, query: "الله")
        for (previous, next) in zip(ranges, ranges.dropFirst()) {
            XCTAssertTrue(previous.upperBound <= next.lowerBound, "ranges overlap or are unsorted")
        }
    }

    /// G.4 — the coloured run covers the word's diacritics rather than a torn
    /// subset, so the Uthmani glyphs do not split mid-word.
    func testHighlightRangeCoversDiacritics() {
        guard let range = QuranSearchService.highlightRanges(in: alFatihah1, query: "الله").first else {
            return XCTFail("الله not found in 1:1")
        }
        XCTAssertEqual(String(alFatihah1[range]), "ٱللَّهِ")
    }

    /// The Uthmani source and the matched string are different strings — a range
    /// found by searching the display text directly would be wrong or nil.
    func testQueryIsNotFindableInTheDisplayTextDirectly() {
        XCTAssertNil(alFatihah1.range(of: "الله"), "if this passes, the index map is no longer necessary")
        XCTAssertFalse(QuranSearchService.highlightRanges(in: alFatihah1, query: "الله").isEmpty)
    }

    func testHighlightRangesRejectsEmptyAndBlankQueries() {
        XCTAssertTrue(QuranSearchService.highlightRanges(in: alFatihah1, query: "").isEmpty)
        XCTAssertTrue(QuranSearchService.highlightRanges(in: alFatihah1, query: "   ").isEmpty)
    }

    func testHighlightRangesReturnsNothingForANonMatch() {
        XCTAssertTrue(QuranSearchService.highlightRanges(in: alFatihah1, query: "زززز").isEmpty)
    }

    /// The query is normalized before matching, so the user may type bare or
    /// vowelled Arabic and get the same ranges.
    func testHighlightRangesNormalizesTheQuery() {
        let bare = QuranSearchService.highlightRanges(in: alFatihah1, query: "الرحمن")
        let vowelled = QuranSearchService.highlightRanges(in: alFatihah1, query: "ٱلرَّحْمَٰنِ")
        XCTAssertEqual(bare.count, 1)
        XCTAssertEqual(bare, vowelled)
    }

    /// Every range from every verse must be usable as an `AttributedString` range,
    /// because that is the only thing the view does with them.
    func testEveryRangeInTheCorpusIsAttributedStringAddressable() {
        for key in Self.corpus.keys.sorted() {
            let text = Self.corpus[key]!
            let ranges = QuranSearchService.highlightRanges(in: text, query: "الله")
            guard !ranges.isEmpty else { continue }
            let attributed = AttributedString(text)
            for range in ranges {
                XCTAssertNotNil(AttributedString.Index(range.lowerBound, within: attributed), "lower bound at \(key)")
                XCTAssertNotNil(AttributedString.Index(range.upperBound, within: attributed), "upper bound at \(key)")
            }
        }
    }

    // MARK: - G.14 — the acceptance count

    func testSearchForWalimanReturnsFiveResults() {
        let results = QuranSearchService.shared.search("ولمن")
        XCTAssertEqual(results.count, 5, "reference count from the approved screenshot")
        XCTAssertEqual(
            results.map { "\($0.surahNumber):\($0.verseNumber)" },
            ["12:72", "42:41", "42:43", "55:46", "71:28"]
        )
    }

    func testSearchRequiresTwoCharacters() {
        XCTAssertTrue(QuranSearchService.shared.search("و").isEmpty)
        XCTAssertTrue(QuranSearchService.shared.search(" ").isEmpty)
    }

    /// D.1 — every result carries its page from the one-shot page map, so the view
    /// never triggers a per-row SQLite query.
    func testEveryResultCarriesAPage() {
        for result in QuranSearchService.shared.search("ولمن") {
            XCTAssertGreaterThan(result.page, 0, "\(result.surahNumber):\(result.verseNumber) has no page")
            XCTAssertLessThanOrEqual(result.page, 604)
        }
    }

    // MARK: - H — the documented gap

    /// NOT a bug to fix here. These queries return zero because the corpus is
    /// Uthmani and `normalize(_:)` cannot bridge Uthmani orthography to imlaei
    /// spelling. This test pins the gap so that a future imlaei column is a
    /// visible, deliberate change rather than a silent one.
    func testKnownRecallGapIsUnchanged() {
        for query in ["الصلاة", "الكتاب", "شيء", "اولئك", "موسي"] {
            XCTAssertTrue(
                QuranSearchService.shared.search(query).isEmpty,
                "\(query) now returns results — the imlaei text landed; update §H and this test"
            )
        }
    }
}
