//
//  HadithMarkupParser.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation

/// Turns a raw `Hadeths.Text` body into clean Arabic plus typed spans.
///
/// The nine core books wrap their Arabic in an inline markup:
///
///     /80 1 /80 # 1 : 33 #  /4 حَدَّثَنِي /1 L1 R6312 يَحْيَى /1 /69 /3 أَنَّ رَسُولَ اللَّهِ /3
///
/// | token                        | meaning                                              |
/// |------------------------------|------------------------------------------------------|
/// | `/80 n /80`                  | inline hadith number, repeatable                      |
/// | `# volume : page #`          | printed citation                                      |
/// | `/4` `/5` `/6`               | the chain of transmission begins                      |
/// | `/69`                        | the chain of transmission ends                        |
/// | `/3`                         | the body of the report, opening and closing           |
/// | `/1 Ln Rid name /1`          | a transmitter — `L` chain depth, `R` keys `Rwah.ID`   |
/// | `/9 Ln Rid name /9`          | a transmitter in a secondary chain, same linkage      |
/// | `/40 Rid word /40`           | a rare word — `R` keys `ghareeb_words.ID`             |
/// | `/20 { ... } /20`            | a Qur'an quotation                                    |
/// | `/66 Rid /66`                | a reference into a table the release does not ship    |
/// | `<div class='albany'>…</div>`| al-Albani's ruling                                    |
///
/// An `R` is resolved by the tag enclosing it, never globally: inside `/1` or
/// `/9` it names a transmitter, inside `/40` it names a glossary entry.
///
/// Three properties are load-bearing, because books 101–108 store plain text
/// that merely *looks* like it has tags:
///
/// - A tag is only recognised as a whole whitespace-delimited token, and its
///   digits are read to the end of the run. So `(6 /406)` is a page citation,
///   not a `/40`, and `(4/80 و 81)` is never a token at all.
/// - A token that is not in the table above is emitted verbatim. Nothing is
///   silently dropped.
/// - An unbalanced tag degrades to plain text rather than losing the body.
enum HadithMarkupParser {

    /// Parses a marked-up body. Safe on plain text, where it only collapses
    /// whitespace runs and returns no spans.
    static func parse(_ raw: String) -> HadithMarkup {
        guard !raw.isEmpty else { return .empty }
        var source = raw
        let ruling = extractRuling(from: &source)
        guard !source.isEmpty else { return HadithMarkup(text: "", spans: [], narrators: [],
                                                         ghareebWords: [], numbers: [], isnadText: "",
                                                         volume: 0, pageNo: 0, ruling: ruling) }
        var lexer = Lexer(source: Array(source))
        lexer.run()
        return lexer.result(ruling: ruling)
    }

    // MARK: - Ruling

    /// Lifts `<div class='albany'>حكم الحديث: …</div>` out of the body.
    /// Returns the ruling text and removes the whole element from `source`.
    private static func extractRuling(from source: inout String) -> String {
        var rulings: [String] = []
        // A body that gathers several numbered reports carries one div per report.
        while let ruling = extractFirstRuling(from: &source) {
            if !ruling.isEmpty { rulings.append(ruling) }
        }
        return rulings.joined(separator: "\n")
    }

    /// Removes the first albany div from `source` and returns its text.
    /// Returns `nil` once none is left.
    private static func extractFirstRuling(from source: inout String) -> String? {
        guard let marker = source.range(of: "albany"),
              let head = source.range(of: "<", options: .backwards,
                                      range: source.startIndex..<marker.lowerBound),
              let headEnd = source.range(of: ">", range: marker.upperBound..<source.endIndex)
        else { return nil }

        let closing = source.range(of: "</div>", options: .caseInsensitive,
                                   range: headEnd.upperBound..<source.endIndex)
        let body = String(source[headEnd.upperBound..<(closing?.lowerBound ?? source.endIndex)])
        source.removeSubrange(head.lowerBound..<(closing?.upperBound ?? source.endIndex))
        return rulingText(from: body)
    }

    /// Strips any leftover tags and the `حكم الحديث:` label.
    private static func rulingText(from body: String) -> String {
        var text = ""
        var insideTag = false
        for character in body {
            if character == "<" { insideTag = true; continue }
            if character == ">" { insideTag = false; continue }
            if !insideTag { text.append(character) }
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let colon = text.firstIndex(of: ":"), text[text.startIndex..<colon].contains("حكم") {
            text = String(text[text.index(after: colon)...])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Tags

private enum Tag {
    static let narrator    = 1
    static let matn        = 3
    static let isnadA      = 4
    static let isnadB      = 5
    static let isnadC      = 6
    static let isnadD      = 7
    static let narratorAlt = 9
    static let quran       = 20
    /// A quotation given without `{ }`, used for a variant reading.
    static let quranPlain  = 21
    static let ghareeb     = 40
    static let reference   = 66
    static let isnadEnd    = 69
    static let number      = 80

    static let known: Set<Int> = [narrator, matn, isnadA, isnadB, isnadC, isnadD,
                                  narratorAlt, quran, quranPlain, ghareeb, reference,
                                  isnadEnd, number]

    /// Tags that wrap content and carry `L` / `R` attributes after the opening token.
    static let attributed: Set<Int> = [narrator, narratorAlt, ghareeb, reference]
}

// MARK: - Lexer

private struct Lexer {

    private struct OpenTag {
        var start: Int
        var ref: Int = 0
        var depth: Int = 0
    }

    private let src: [Character]
    private var i = 0

    private var out: [Character] = []
    private var spans: [HadithSpan] = []
    private var nextSpanID = 0

    private var open: [Int: OpenTag] = [:]
    private var isnadStart: Int?
    private var matnStart: Int?
    private var capture: [Character]?

    private var volume = 0
    private var pageNo = 0

    init(source: [Character]) {
        src = source
        out.reserveCapacity(source.count)
    }

    // MARK: Driving loop

    mutating func run() {
        while i < src.count {
            let character = src[i]

            if character == "/", atTokenBoundary() {
                let mark = i
                if let tag = readTag(), apply(tag) { continue }
                i = mark
            }
            if character == "#", atTokenBoundary(), readCitation() {
                continue
            }
            if character == "<", skipHTMLTag() {
                continue
            }
            if (character == "{" || character == "}"), open[Tag.quran] != nil {
                i += 1
                continue
            }
            emit(character)
            i += 1
        }
        finish()
    }

    func result(ruling: String) -> HadithMarkup {
        let text = String(out)
        var narrators: [HadithNarratorRef] = []
        var ghareeb: [HadithGhareebRef] = []
        var numbers: [Int] = []
        var chain: [String] = []

        let markup = HadithMarkup(text: text, spans: spans, narrators: [], ghareebWords: [],
                                  numbers: [], isnadText: "", volume: volume, pageNo: pageNo,
                                  ruling: ruling)

        for span in spans {
            switch span.kind {
            case let .narrator(rwahID, depth):
                narrators.append(HadithNarratorRef(rwahID: rwahID, depth: depth,
                                                   name: markup.substring(of: span)))
            case let .ghareeb(wordID):
                ghareeb.append(HadithGhareebRef(wordID: wordID, word: markup.substring(of: span)))
            case let .number(value):
                numbers.append(value)
            case .isnad:
                chain.append(markup.substring(of: span))
            case .matn, .quranQuote:
                break
            }
        }

        return HadithMarkup(text: text, spans: spans, narrators: narrators, ghareebWords: ghareeb,
                            numbers: numbers, isnadText: chain.joined(separator: " "),
                            volume: volume, pageNo: pageNo, ruling: ruling)
    }

    // MARK: Emitting

    /// Appends one character, collapsing runs of whitespace. A run that held a
    /// newline stays a newline, so the shape of a commentary survives.
    private mutating func emit(_ character: Character) {
        if capture != nil {
            capture?.append(character)
            return
        }
        guard !character.isWhitespace else {
            guard let last = out.last else { return }
            guard last != "\n" else { return }
            if last == " " {
                if character.isNewline { out[out.count - 1] = "\n" }
                return
            }
            out.append(character.isNewline ? "\n" : " ")
            return
        }
        out.append(character)
    }

    // MARK: Scanning

    /// True when the character before the cursor cannot be part of a word.
    ///
    /// A tag is glued to the punctuation around it as often as it is spaced
    /// (`\u{200F}أَسْلَمَ ،/69 عَنْ`), so whitespace alone is too strict. A letter or a
    /// digit before the slash does rule it out, which is what keeps the page
    /// citations in books 101-108 — `(4/80 و 81)`, `(2/80-81)` — out.
    private func atTokenBoundary() -> Bool {
        guard i > 0 else { return true }
        let previous = src[i - 1]
        return !(previous.isLetter || previous.isNumber)
    }

    private static func digit(_ character: Character) -> Int? {
        guard character.isASCII, let value = character.wholeNumberValue, (0...9).contains(value) else { return nil }
        return value
    }

    /// Reads `/` + digits as a known tag. Returns `nil` — leaving `i` untouched —
    /// for anything else, so the caller emits the slash verbatim.
    private mutating func readTag() -> Int? {
        var j = i + 1
        var value = 0
        var digits = 0
        while j < src.count, let d = Lexer.digit(src[j]) {
            value = value * 10 + d
            digits += 1
            j += 1
            if digits > 3 { return nil }
        }
        guard digits > 0, Tag.known.contains(value) else { return nil }
        guard j >= src.count || !(src[j].isLetter || src[j].isNumber) else { return nil }
        i = j
        return value
    }

    /// Reads `# volume : page #`. Returns `false` — leaving `i` untouched —
    /// for a `#` that is not a citation.
    private mutating func readCitation() -> Bool {
        var j = i + 1
        var inner: [Character] = []
        while j < src.count, src[j] != "#", inner.count < 24 {
            inner.append(src[j])
            j += 1
        }
        guard j < src.count, src[j] == "#" else { return false }
        let parts = String(inner).split(separator: ":")
        guard parts.count == 2,
              let v = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let p = Int(parts[1].trimmingCharacters(in: .whitespaces))
        else { return false }
        volume = v
        pageNo = p
        i = j + 1
        return true
    }

    /// Skips a stray HTML element. Arabic never contains `<`, so this is safe.
    private mutating func skipHTMLTag() -> Bool {
        var j = i + 1
        if j < src.count, src[j] == "/" { j += 1 }
        guard j < src.count, src[j].isASCII, src[j].isLetter else { return false }
        while j < src.count, src[j] != ">" { j += 1 }
        guard j < src.count else { return false }
        i = j + 1
        return true
    }

    /// Consumes the `L<depth>` and `R<id>` tokens that follow an opening tag.
    /// Returns `false` when there are none, which means this was never a tag.
    @discardableResult
    private mutating func readAttributes(into tag: inout OpenTag) -> Bool {
        var found = false
        while true {
            var j = i
            while j < src.count, src[j].isWhitespace { j += 1 }
            guard j < src.count, src[j] == "L" || src[j] == "R" else { return found }
            let marker = src[j]
            var k = j + 1
            var value = 0
            var digits = 0
            while k < src.count, let d = Lexer.digit(src[k]) {
                value = value * 10 + d
                digits += 1
                k += 1
            }
            guard digits > 0 else { return found }
            guard k >= src.count || !(src[k].isLetter || src[k].isNumber) else { return found }
            if marker == "L" { tag.depth = value } else { tag.ref = value }
            i = k
            found = true
        }
    }

    // MARK: Applying

    /// Acts on a recognised tag. Returns `false` when the tag turns out not to
    /// be one after all, leaving the caller to rewind and emit it as text.
    private mutating func apply(_ tag: Int) -> Bool {
        switch tag {
        case Tag.isnadA, Tag.isnadB, Tag.isnadC, Tag.isnadD:
            if isnadStart == nil { isnadStart = out.count }

        case Tag.isnadEnd:
            closeIsnad()

        case Tag.matn:
            if matnStart == nil {
                closeIsnad()
                matnStart = out.count
            } else {
                closeMatn()
            }

        case Tag.number:
            if open[tag] == nil {
                open[tag] = OpenTag(start: out.count)
                capture = []
            } else {
                closeNumber()
            }

        default:
            if let openTag = open[tag] {
                closeContent(tag, openTag)
            } else {
                var openTag = OpenTag(start: out.count)
                if Tag.attributed.contains(tag) {
                    // A real `/1`, `/9`, `/40` or `/66` always names what it points at.
                    // Without that, this is a page citation such as `(4 /40)`.
                    guard readAttributes(into: &openTag) else { return false }
                    openTag.start = out.count
                }
                open[tag] = openTag
            }
        }
        return true
    }

    private mutating func closeContent(_ tag: Int, _ openTag: OpenTag) {
        open[tag] = nil
        guard let range = tightRange(openTag.start, out.count) else { return }
        switch tag {
        case Tag.narrator, Tag.narratorAlt:
            addSpan(.narrator(rwahID: openTag.ref, depth: openTag.depth), range)
        case Tag.ghareeb:
            addSpan(.ghareeb(wordID: openTag.ref), range)
        case Tag.quran, Tag.quranPlain:
            addSpan(.quranQuote, range)
        default:
            break   // `/66` points into a table the release strips: keep the text, drop the link.
        }
    }

    private mutating func closeNumber() {
        let text = String(capture ?? []).trimmingCharacters(in: .whitespacesAndNewlines)
        capture = nil
        open[Tag.number] = nil
        guard let value = Int(text) else { return }
        addSpan(.number(value), out.count..<out.count)
    }

    private mutating func closeIsnad() {
        guard let start = isnadStart else { return }
        isnadStart = nil
        guard let range = tightRange(start, out.count) else { return }
        addSpan(.isnad, range)
    }

    private mutating func closeMatn() {
        guard let start = matnStart else { return }
        matnStart = nil
        guard let range = tightRange(start, out.count) else { return }
        addSpan(.matn, range)
    }

    // MARK: Finishing

    private mutating func finish() {
        if capture != nil { closeNumber() }

        // A tag left open was never a tag: a lone `/4` in `(2 /4-5)` opens a chain
        // that the body never ends. Dropping it is what keeps the plain-text books
        // free of spans, so nothing here is closed on the parser's own authority.
        open = [:]
        matnStart = nil
        isnadStart = nil

        while let last = out.last, last == " " || last == "\n" { out.removeLast() }

        let limit = out.count
        spans = spans.compactMap { span -> HadithSpan? in
            guard span.range.lowerBound <= limit else { return nil }
            if case .number = span.kind {
                return HadithSpan(id: span.id, kind: span.kind,
                                  range: span.range.lowerBound..<span.range.lowerBound)
            }
            let upper = min(span.range.upperBound, limit)
            guard span.range.lowerBound < upper else { return nil }
            return HadithSpan(id: span.id, kind: span.kind, range: span.range.lowerBound..<upper)
        }
        .sorted { lhs, rhs in
            if lhs.range.lowerBound != rhs.range.lowerBound { return lhs.range.lowerBound < rhs.range.lowerBound }
            if lhs.range.count != rhs.range.count { return lhs.range.count > rhs.range.count }
            return lhs.id < rhs.id
        }
    }

    // MARK: Helpers

    private func tightRange(_ lower: Int, _ upper: Int) -> Range<Int>? {
        var start = max(0, lower)
        var end = min(upper, out.count)
        while start < end, out[start] == " " || out[start] == "\n" { start += 1 }
        while end > start, out[end - 1] == " " || out[end - 1] == "\n" { end -= 1 }
        return start < end ? start..<end : nil
    }

    private mutating func addSpan(_ kind: HadithSpanKind, _ range: Range<Int>) {
        spans.append(HadithSpan(id: nextSpanID, kind: kind, range: range))
        nextSpanID += 1
    }
}
