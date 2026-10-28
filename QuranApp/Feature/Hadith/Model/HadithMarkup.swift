//
//  HadithMarkup.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation

// MARK: - Span kind

/// What a run of characters inside a hadith body means.
///
/// The nine core books do not store `Hadeths.Text` as plain text: the Arabic is
/// wrapped in an inline markup that names the chain of transmission, the rare
/// words, the Qur'an quotations and the inline hadith numbers.
/// `HadithMarkupParser` removes that markup and reports what it removed as
/// spans over the clean text, so the reading view can style or link each run
/// without ever seeing a raw tag.
enum HadithSpanKind: Hashable {

    /// A chain-of-transmission region.
    case isnad

    /// The body of the report itself.
    case matn

    /// One transmitter. `rwahID` keys `Rwah.ID`; `depth` is the link's position in the chain.
    case narrator(rwahID: Int, depth: Int)

    /// A rare word. `wordID` keys `ghareeb_words.ID`; the span's own text is the word.
    case ghareeb(wordID: Int)

    /// A Qur'an quotation, with its `{ }` delimiters already removed.
    case quranQuote

    /// An inline hadith number, marking where a sub-report begins.
    /// Always zero length — it is a position in the text, not a run of it.
    case number(Int)

    case note(noteID: Int)
}

// MARK: - Span

/// A typed run of characters inside `HadithMarkup.text`.
struct HadithSpan: Identifiable, Hashable {
    let id: Int
    let kind: HadithSpanKind
    /// Character offsets into `HadithMarkup.text`.
    let range: Range<Int>
}

// MARK: - Resolved references

/// A transmitter named in the chain, ready to look up in `Rwah`.
struct HadithNarratorRef: Identifiable, Hashable {
    let rwahID: Int
    let depth: Int
    let name: String

    var id: Int { rwahID }
}

/// A rare word named in the body, ready to look up in `ghareeb_words`.
struct HadithGhareebRef: Identifiable, Hashable {
    let wordID: Int
    let word: String

    var id: Int { wordID }
}

struct HadithNoteRef: Identifiable, Hashable {
    let noteID: Int
    let offset: Int

    var id: Int { noteID }
}

// MARK: - Parsed body

/// The result of parsing one marked-up hadith body.
///
/// `text` is always safe to show as-is. Everything else is additive: a book
/// that stores plain text yields the same `text` with no spans and no
/// references, so the reading view needs no special case for it.
struct HadithMarkup: Hashable {

    /// Clean Arabic, with every tag removed and whitespace runs collapsed.
    let text: String

    /// Typed runs over `text`, in reading order.
    let spans: [HadithSpan]

    /// Transmitters found in the chain, in reading order.
    let narrators: [HadithNarratorRef]

    /// Rare words found in the body, in reading order.
    let ghareebWords: [HadithGhareebRef]

    /// Inline hadith numbers, in reading order. A body carrying more than one
    /// is a combined entry covering several numbered reports.
    let numbers: [Int]

    let notes: [HadithNoteRef]

    /// The chain of transmission as flat text, or empty when the body has none.
    let isnadText: String

    /// Volume and page, when the body carried a `# volume : page #` citation.
    /// Both are `0` otherwise; the `FolderNum` and `PageNum` columns are the
    /// more reliable source and this is only a fallback.
    let volume: Int
    let pageNo: Int

    /// Al-Albani's ruling, lifted out of the body's trailing `<div>`.
    /// Empty when the body carried none.
    let ruling: String

    static let empty = HadithMarkup(text: "", spans: [], narrators: [], ghareebWords: [],
                                    numbers: [], notes: [], isnadText: "",
                                    volume: 0, pageNo: 0, ruling: "")

    /// A body that carried no markup at all.
    static func plain(_ text: String) -> HadithMarkup {
        HadithMarkup(text: text, spans: [], narrators: [], ghareebWords: [],
                     numbers: [], notes: [], isnadText: "",
                     volume: 0, pageNo: 0, ruling: "")
    }

    var isEmpty: Bool { text.isEmpty }

    /// True when the body was plain text to begin with — nothing to style, nothing to tap.
    var isPlain: Bool { spans.isEmpty }

    /// The characters a span covers.
    func substring(of span: HadithSpan) -> String {
        substring(in: span.range)
    }

    /// The characters an offset range covers, clamped to the text.
    func substring(in range: Range<Int>) -> String {
        guard range.lowerBound < range.upperBound else { return "" }
        guard let lower = text.index(text.startIndex, offsetBy: range.lowerBound, limitedBy: text.endIndex),
              let upper = text.index(text.startIndex, offsetBy: range.upperBound, limitedBy: text.endIndex)
        else { return "" }
        return String(text[lower..<upper])
    }
}
