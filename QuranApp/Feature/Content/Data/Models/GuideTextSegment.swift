//
//  GuideTextSegment.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import SwiftUI

// MARK: - GuideTextSegment

enum GuideTextSegment: Hashable {
    case heading(String)
    case instruction(String)
    case supplication(String)
    case narration(String)
    case revelation(text: String, reference: String)

    var text: String {
        switch self {
        case .heading(let text):        return text
        case .instruction(let text):    return text
        case .supplication(let text):   return text
        case .narration(let text):      return text
        case .revelation(let text, _):  return text
        }
    }
}

// MARK: - GuideTextBlock

struct GuideTextBlock: Identifiable, Hashable {
    let index: Int
    let segment: GuideTextSegment

    var id: Int { index }
}

// MARK: - GuideTextParser

enum GuideTextParser {

    private enum Marker {
        static let revelationOpen = "\u{FD3F}"
        static let revelationClose = "\u{FD3E}"
        static let quoteOpen = "\u{00AB}"
        static let quoteClose = "\u{00BB}"
        static let emphasis = "**"
    }

    private enum LineKind {
        case instruction
        case supplication
        case narration
    }

    // MARK: - Blocks

    static func blocks(from text: String) -> [GuideTextBlock] {
        var blocks: [GuideTextBlock] = []
        var pendingKind: LineKind?
        var pendingLines: [String] = []

        func flush() {
            defer {
                pendingKind = nil
                pendingLines = []
            }
            guard let kind = pendingKind, !pendingLines.isEmpty else { return }
            let joined = pendingLines.joined(separator: "\n")
            let segment: GuideTextSegment
            switch kind {
            case .instruction:  segment = .instruction(joined)
            case .supplication: segment = .supplication(joined)
            case .narration:    segment = .narration(joined)
            }
            blocks.append(GuideTextBlock(index: blocks.count, segment: segment))
        }

        func append(_ kind: LineKind, _ line: String) {
            if pendingKind != kind { flush() }
            pendingKind = kind
            pendingLines.append(line)
        }

        let lines = text.components(separatedBy: "\n")

        for (offset, rawLine) in lines.enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else {
                flush()
                continue
            }

            if line.contains(Marker.revelationOpen) {
                flush()
                let (body, reference) = splitReference(from: stripEmphasis(line))
                blocks.append(GuideTextBlock(index: blocks.count,
                                             segment: .revelation(text: body, reference: reference)))
                continue
            }

            if let emphasised = emphasisBody(of: line) {
                if introducesFollowingLines(at: offset, in: lines) {
                    flush()
                    blocks.append(GuideTextBlock(index: blocks.count, segment: .heading(emphasised)))
                } else {
                    append(.supplication, emphasised)
                }
                continue
            }

            if line.hasPrefix(Marker.quoteOpen), line.hasSuffix(Marker.quoteClose) {
                append(.narration, line)
                continue
            }

            append(.instruction, line)
        }

        flush()
        return blocks
    }

    private static func introducesFollowingLines(at offset: Int, in lines: [String]) -> Bool {
        let next = offset + 1
        guard next < lines.count else { return false }
        let following = lines[next].trimmingCharacters(in: .whitespaces)
        guard !following.isEmpty else { return false }
        return emphasisBody(of: following) == nil
    }

    // MARK: - Markdown

    static func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        guard let parsed = try? AttributedString(markdown: text, options: options) else {
            return AttributedString(text)
        }
        return parsed
    }

    // MARK: - Numbering

    static func carriesOwnNumbering(_ texts: [String]) -> Bool {
        texts.contains(where: hasLeadingNumber)
    }

    private static func hasLeadingNumber(_ text: String) -> Bool {
        var sawDigit = false
        for character in text.trimmingCharacters(in: .whitespaces) {
            if character.isNumber {
                sawDigit = true
                continue
            }
            guard sawDigit else { return false }
            return character == "." || character == ")" || character == "-"
        }
        return false
    }

    // MARK: - Line helpers

    private static func stripEmphasis(_ line: String) -> String {
        line.replacingOccurrences(of: Marker.emphasis, with: "")
    }

    private static func emphasisBody(of line: String) -> String? {
        guard line.hasPrefix(Marker.emphasis), line.hasSuffix(Marker.emphasis), line.count > 4 else {
            return nil
        }
        let body = line.dropFirst(Marker.emphasis.count).dropLast(Marker.emphasis.count)
        guard !body.contains(Marker.emphasis) else { return nil }
        return String(body)
    }

    private static func splitReference(from line: String) -> (text: String, reference: String) {
        guard line.hasSuffix(Marker.quoteClose),
              let opening = line.range(of: Marker.quoteOpen, options: .backwards) else {
            return (line, "")
        }
        let reference = String(line[opening.lowerBound...])
        let body = String(line[..<opening.lowerBound]).trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty else { return (line, "") }
        return (body, reference)
    }
}
