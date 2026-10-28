//
//  AthkarReaderPage.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import Foundation

// MARK: - Block

struct AthkarReaderBlock: Identifiable, Hashable {

    enum Kind: Hashable {
        case heading
        case body
        case quran
        case note
    }

    let id: Int
    let kind: Kind
    let text: String
}

// MARK: - Page

struct AthkarReaderPage: Identifiable, Hashable {

    let id: Int
    let item: AthkarItem
    let eyebrow: String
    let title: String
    let repeatBadge: String
    let situation: String
    let blocks: [AthkarReaderBlock]
    let transliteration: String
    let meaning: String
    let source: String
    let shareText: String

    var hasTitle: Bool { !title.isEmpty }

    var hasRepeatBadge: Bool { !repeatBadge.isEmpty }

    var hasSituation: Bool { !situation.isEmpty }

    var hasMeaning: Bool { !meaning.isEmpty }

    var hasTransliteration: Bool { !transliteration.isEmpty }

    var hasSource: Bool { !source.isEmpty }

    var target: Int { item.repeatCount }

    var needsCount: Bool { item.repeatCount > 1 }
}

// MARK: - Page · building

extension AthkarReaderPage {

    static func make(item: AthkarItem, eyebrow: String, repeatBadge: String) -> AthkarReaderPage {
        AthkarReaderPage(
            id: item.id,
            item: item,
            eyebrow: eyebrow,
            title: item.displayTitle,
            repeatBadge: item.showsRepeatBadge ? repeatBadge : "",
            situation: item.situationTag(),
            blocks: blocks(for: item),
            transliteration: item.transliteration,
            meaning: item.textEn,
            source: item.source,
            shareText: shareText(for: item)
        )
    }

    private static func blocks(for item: AthkarItem) -> [AthkarReaderBlock] {
        let promotesNotes = !item.hasInlineBody

        var blocks = item.segments.compactMap { segment -> AthkarReaderBlock? in
            guard !segment.text.isEmpty else { return nil }

            switch segment.kind {
            case .heading:      return AthkarReaderBlock(id: segment.index, kind: .heading, text: segment.text)
            case .quran:        return AthkarReaderBlock(id: segment.index, kind: .quran, text: segment.text)
            case .text:         return AthkarReaderBlock(id: segment.index, kind: .body, text: segment.text)
            case .note:         return AthkarReaderBlock(id: segment.index,
                                                         kind: promotesNotes ? .body : .note,
                                                         text: segment.text)
            case .repeatCount:  return nil
            }
        }

        let alternate = item.alternateWording
        if !alternate.isEmpty {
            let next = (blocks.map(\.id).max() ?? 0) + 1
            blocks.append(AthkarReaderBlock(id: next, kind: .note, text: alternate))
        }

        return blocks
    }

    private static func shareText(for item: AthkarItem) -> String {
        var parts: [String] = []
        if !item.displayTitle.isEmpty { parts.append(item.displayTitle) }
        parts.append(item.plainText)
        if !item.source.isEmpty { parts.append(item.source) }
        return parts.filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}
