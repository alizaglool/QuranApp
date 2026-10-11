//
//  HadithSearchQuery.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation
import SwiftUI
import Core

// MARK: - Folding

enum HadithSearchFolding {

    enum FoldedCharacter {
        case letters(String)
        case separator
        case dropped

        var letters: String? {
            if case .letters(let value) = self { return value }
            return nil
        }

        var isSeparator: Bool {
            if case .separator = self { return true }
            return false
        }
    }

    private static let letterFolds: [Character: Character] = [
        "أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا",
        "ؤ": "ء", "ئ": "ء",
        "ى": "ي",
        "ة": "ه"
    ]

    private static let strippedScalars: ClosedRange<UInt32> = 0x064B...0x065F
    private static let daggerAlif: UInt32 = 0x0670
    private static let tatweel: UInt32 = 0x0640

    static func fold(_ character: Character) -> FoldedCharacter {
        if let folded = letterFolds[character] { return .letters(String(folded)) }

        var letters = String.UnicodeScalarView()
        var sawSeparator = false

        for scalar in character.unicodeScalars {
            if strippedScalars.contains(scalar.value)
                || scalar.value == daggerAlif
                || scalar.value == tatweel { continue }

            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                sawSeparator = true
                continue
            }
            if CharacterSet.punctuationCharacters.contains(scalar)
                || CharacterSet.symbols.contains(scalar) { continue }

            letters.append(scalar)
        }

        if !letters.isEmpty { return .letters(String(letters).lowercased()) }
        return sawSeparator ? .separator : .dropped
    }

    static func normalize(_ raw: String) -> String {
        var folded = String()
        folded.reserveCapacity(raw.count)
        var lastWasSpace = true

        for character in raw {
            switch fold(character) {
            case .letters(let value):
                folded.append(value)
                lastWasSpace = false
            case .separator:
                if !lastWasSpace { folded.append(" ") }
                lastWasSpace = true
            case .dropped:
                continue
            }
        }
        return folded.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Query

struct HadithSearchTerm: Equatable, Hashable {
    let folded: String
    let latin: String
}

struct HadithSearchQuery: Equatable, Hashable {

    static let minimumFoldedLength = 2

    let raw: String
    let terms: [HadithSearchTerm]

    init?(_ raw: String) {
        var terms: [HadithSearchTerm] = []

        for word in raw.split(whereSeparator: { $0.isWhitespace }) {
            let folded = HadithSearchFolding.normalize(String(word))
            guard !folded.isEmpty else { continue }
            terms.append(HadithSearchTerm(folded: folded, latin: String(word).lowercased()))
        }

        let length = terms.reduce(0) { $0 + $1.folded.count }
        guard !terms.isEmpty, length >= Self.minimumFoldedLength else { return nil }

        self.raw = raw
        self.terms = terms
    }

    static func likePattern(_ term: String) -> String {
        var escaped = term.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "%", with: "\\%")
        escaped = escaped.replacingOccurrences(of: "_", with: "\\_")
        return "%\(escaped)%"
    }
}

// MARK: - Highlighting

enum HadithHighlighter {

    static func ranges(of query: HadithSearchQuery, in text: String) -> [Range<String.Index>] {
        guard !text.isEmpty else { return [] }

        let found = query.terms
            .flatMap { ranges(ofTerm: $0.folded, in: text) }
            .sorted { $0.lowerBound < $1.lowerBound }

        return merged(found)
    }

    private static func ranges(ofTerm term: String, in text: String) -> [Range<String.Index>] {
        let needle = Array(term)
        guard !needle.isEmpty else { return [] }

        var found: [Range<String.Index>] = []
        var start = text.startIndex

        while start < text.endIndex {
            if let end = matchEnd(needle, in: text, from: start) {
                found.append(start..<end)
                start = end
            } else {
                start = text.index(after: start)
            }
        }
        return found
    }

    private static func matchEnd(_ needle: [Character],
                                 in text: String,
                                 from start: String.Index) -> String.Index? {
        var cursor = start
        var matched = 0
        var end = start

        while matched < needle.count, cursor < text.endIndex {
            let folded = HadithSearchFolding.fold(text[cursor])
            let next = text.index(after: cursor)

            guard let letters = folded.letters else {
                if matched == 0 || folded.isSeparator { return nil }
                cursor = next
                continue
            }
            for letter in letters {
                guard matched < needle.count, letter == needle[matched] else { return nil }
                matched += 1
            }
            cursor = next
            end = next
        }
        return matched == needle.count ? end : nil
    }

    private static func merged(_ ranges: [Range<String.Index>]) -> [Range<String.Index>] {
        var result: [Range<String.Index>] = []
        for range in ranges {
            guard let last = result.last, range.lowerBound <= last.upperBound else {
                result.append(range)
                continue
            }
            result[result.count - 1] = last.lowerBound..<Swift.max(last.upperBound, range.upperBound)
        }
        return result
    }
}

// MARK: - Highlighted text

enum HadithHighlightedText {

    static func make(_ text: String, matching query: HadithSearchQuery?) -> AttributedString {
        var attributed = AttributedString(text)
        guard let query else { return attributed }

        for range in HadithHighlighter.ranges(of: query, in: text) {
            guard let lower = AttributedString.Index(range.lowerBound, within: attributed),
                  let upper = AttributedString.Index(range.upperBound, within: attributed) else { continue }
            attributed[lower..<upper].backgroundColor = Color.hadithGold.opacity(0.3)
        }
        return attributed
    }
}

// MARK: - Snippet

enum HadithSnippet {

    static let lead = 40
    static let length = 200

    static func around(_ query: HadithSearchQuery?, in text: String) -> String {
        guard let query,
              let match = HadithHighlighter.ranges(of: query, in: text).first else {
            return clipped(text, from: text.startIndex)
        }
        let start = wordStart(before: match.lowerBound, in: text)
        return clipped(text, from: start)
    }

    private static func clipped(_ text: String, from start: String.Index) -> String {
        let end = wordEnd(after: start, in: text)
        var snippet = String(text[start..<end])
        if start > text.startIndex { snippet = "… " + snippet }
        if end < text.endIndex { snippet += " …" }
        return snippet
    }

    private static func wordStart(before index: String.Index, in text: String) -> String.Index {
        guard let limit = text.index(index, offsetBy: -lead, limitedBy: text.startIndex) else {
            return text.startIndex
        }
        guard let space = text[limit...].firstIndex(where: \.isWhitespace) else { return limit }
        return text.index(after: space)
    }

    private static func wordEnd(after index: String.Index, in text: String) -> String.Index {
        guard let limit = text.index(index, offsetBy: length, limitedBy: text.endIndex) else {
            return text.endIndex
        }
        return text[limit...].firstIndex(where: \.isWhitespace) ?? text.endIndex
    }
}
