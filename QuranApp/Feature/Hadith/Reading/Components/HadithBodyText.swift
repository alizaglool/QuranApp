//
//  HadithBodyText.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import SwiftUI
import Core

// MARK: - Link

enum HadithBodyLink: Hashable {
    case narrator(Int)
    case ghareeb(Int)
    case note(Int)

    private static let scheme = "hadith"

    private enum Host: String {
        case narrator
        case ghareeb
        case note
    }

    var url: URL? {
        let host: Host
        let id: Int

        switch self {
        case let .narrator(value): host = .narrator; id = value
        case let .ghareeb(value):  host = .ghareeb;  id = value
        case let .note(value):     host = .note;     id = value
        }
        return URL(string: "\(Self.scheme)://\(host.rawValue)/\(id)")
    }

    init?(_ url: URL) {
        guard url.scheme == Self.scheme,
              let host = url.host.flatMap(Host.init(rawValue:)),
              let id = Int(url.lastPathComponent) else { return nil }

        switch host {
        case .narrator: self = .narrator(id)
        case .ghareeb:  self = .ghareeb(id)
        case .note:     self = .note(id)
        }
    }
}

// MARK: - Body text

enum HadithBodyText {
    private static let markerStyle = AppTextStyle.kitab(size: 13, bold: true)

    static func make(_ markup: HadithMarkup,
                     fallback: String,
                     highlight: HadithSearchQuery?) -> AttributedString {
        guard !markup.isPlain else {
            return HadithHighlightedText.make(markup.isEmpty ? fallback : markup.text,
                                              matching: highlight)
        }

        var attributed = AttributedString(markup.text)
        applySpans(markup.spans, to: &attributed)
        applyHighlight(highlight, text: markup.text, to: &attributed)
        insertNoteMarkers(markup.notes, into: &attributed)
        return attributed
    }

    // MARK: Spans

    private static func applySpans(_ spans: [HadithSpan], to attributed: inout AttributedString) {
        for span in spans where !span.range.isEmpty {
            guard let range = characterRange(span.range, in: attributed) else { continue }

            switch span.kind {
            case .isnad:
                attributed[range].foregroundColor = .hadithSecondary

            case let .narrator(rwahID, _):
                attributed[range].foregroundColor = .hadithGold
                attributed[range].link = HadithBodyLink.narrator(rwahID).url

            case let .ghareeb(wordID):
                attributed[range].foregroundColor = .hadithGreen
                attributed[range].underlineStyle = .single
                attributed[range].link = HadithBodyLink.ghareeb(wordID).url

            case .quranQuote:
                attributed[range].foregroundColor = .hadithPrimary

            case .matn, .number, .note:
                break
            }
        }
    }

    // MARK: Highlight

    private static func applyHighlight(_ query: HadithSearchQuery?,
                                       text: String,
                                       to attributed: inout AttributedString) {
        guard let query else { return }

        for range in HadithHighlighter.ranges(of: query, in: text) {
            guard let lower = AttributedString.Index(range.lowerBound, within: attributed),
                  let upper = AttributedString.Index(range.upperBound, within: attributed) else { continue }
            attributed[lower..<upper].backgroundColor = Color.hadithGold.opacity(0.3)
        }
    }

    // MARK: Note markers

    private static func insertNoteMarkers(_ notes: [HadithNoteRef],
                                         into attributed: inout AttributedString) {
        guard !notes.isEmpty else { return }

        for (offset, note) in notes.enumerated().reversed() {
            guard let index = characterIndex(note.offset, in: attributed) else { continue }

            var marker = AttributedString(Self.marker(offset + 1))
            marker.font = markerStyle.directFont
            marker.foregroundColor = .hadithGold
            marker.link = HadithBodyLink.note(note.noteID).url
            attributed.insert(marker, at: index)
        }
    }

    static func marker(_ number: Int) -> String {
        let digits = String(number).compactMap { character -> Character? in
            guard let digit = character.wholeNumberValue else { return nil }
            return superscriptDigits[digit]
        }
        return "⁽\(String(digits))⁾"
    }

    private static let superscriptDigits: [Character] = ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]

    // MARK: Offsets

    private static func characterRange(_ range: Range<Int>,
                                       in attributed: AttributedString) -> Range<AttributedString.Index>? {
        guard let lower = characterIndex(range.lowerBound, in: attributed),
              let upper = characterIndex(range.upperBound, in: attributed) else { return nil }
        return lower..<upper
    }

    private static func characterIndex(_ offset: Int,
                                       in attributed: AttributedString) -> AttributedString.Index? {
        let characters = attributed.characters
        guard offset >= 0, offset <= characters.count else { return nil }
        return characters.index(characters.startIndex, offsetBy: offset)
    }
}
