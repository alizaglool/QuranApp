//
//  AthkarItem.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Core

// MARK: - Segment kind

enum AthkarSegmentKind: String, Codable, Hashable, CaseIterable {
    case heading
    case text
    case note
    case repeatCount = "repeat"
    case quran
}

// MARK: - Segment

struct AthkarSegment: Identifiable, Hashable {
    let index: Int
    let kind: AthkarSegmentKind
    let text: String

    var id: Int { index }
}

// MARK: - Item

struct AthkarItem: Identifiable, Hashable {
    let id: Int
    let segments: [AthkarSegment]
    let count: Int
    let title: String
    let titleEn: String
    let translit: String
    let textEn: String
    let source: String
    let variant: String
    let emoji: String
    let audio: String
    let tags: [String]

    var displayTitle: String {
        guard LocalizationManager.shared.currentLanguage != .Arabic, !titleEn.isEmpty else { return title }
        return titleEn
    }

    var transliteration: String {
        translit.athkarIsArabicDominant ? "" : translit
    }

    var alternateWording: String {
        translit.athkarIsArabicDominant ? translit : ""
    }

    var repeatCount: Int { max(count, 1) }

    var showsRepeatBadge: Bool { count > 1 }

    var hasInlineBody: Bool {
        segments.contains { $0.kind == .text || $0.kind == .quran }
    }

    var arabicBody: [AthkarSegment] {
        guard hasInlineBody else { return segments.filter { $0.kind == .note } }
        return segments.filter { $0.kind == .text || $0.kind == .quran }
    }

    var notes: [AthkarSegment] {
        guard hasInlineBody else { return [] }
        return segments.filter { $0.kind == .note }
    }

    var headings: [AthkarSegment] {
        segments.filter { $0.kind == .heading }
    }

    var plainText: String {
        arabicBody.map(\.text).joined(separator: "\n")
    }

    var hasAudio: Bool { !audio.isEmpty }

    func situationTag() -> String {
        tags.first { $0.hasPrefix("situation:") }?
            .replacingOccurrences(of: "situation:", with: "") ?? ""
    }
}

// MARK: - Item · decoding

extension AthkarItem: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id, segments, count, title, titleEn, translit
        case textEn, source, variant, emoji, audio, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        count = try container.decodeIfPresent(Int.self, forKey: .count) ?? 0
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        titleEn = try container.decodeIfPresent(String.self, forKey: .titleEn) ?? ""
        translit = try container.decodeIfPresent(String.self, forKey: .translit) ?? ""
        textEn = try container.decodeIfPresent(String.self, forKey: .textEn) ?? ""
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? ""
        variant = try container.decodeIfPresent(String.self, forKey: .variant) ?? ""
        emoji = try container.decodeIfPresent(String.self, forKey: .emoji) ?? ""
        audio = try container.decodeIfPresent(String.self, forKey: .audio) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []

        let raw = try container.decodeIfPresent([AthkarRawSegment].self, forKey: .segments) ?? []
        segments = raw.enumerated().compactMap { offset, element in
            guard let kind = element.kind else { return nil }
            return AthkarSegment(index: offset, kind: kind, text: element.text)
        }
    }
}

// MARK: - Raw segment

private struct AthkarRawSegment: Decodable {
    let kind: AthkarSegmentKind?
    let text: String

    private enum CodingKeys: String, CodingKey {
        case k, t
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawKind = try container.decodeIfPresent(String.self, forKey: .k) ?? ""
        kind = AthkarSegmentKind(rawValue: rawKind)
        text = try container.decodeIfPresent(String.self, forKey: .t) ?? ""
    }
}

// MARK: - Payload

struct AthkarPackPayload: Hashable {
    let schemaVersion: Int
    let dataVersion: String
    let key: String
    let kind: AthkarPackKind
    let items: [AthkarItem]

    static let empty = AthkarPackPayload(schemaVersion: 0, dataVersion: "", key: "", kind: .list, items: [])

    var isEmpty: Bool { items.isEmpty }

    func item(id: Int) -> AthkarItem? {
        items.first { $0.id == id }
    }
}

// MARK: - Payload · decoding

extension AthkarPackPayload: Decodable {

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, dataVersion, key, kind, items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0
        dataVersion = try container.decodeIfPresent(String.self, forKey: .dataVersion) ?? ""
        key = try container.decodeIfPresent(String.self, forKey: .key) ?? ""

        let rawKind = try container.decodeIfPresent(String.self, forKey: .kind) ?? ""
        kind = AthkarPackKind(rawValue: rawKind) ?? .list

        items = try container
            .decodeIfPresent([AthkarLossyItem].self, forKey: .items)?
            .compactMap(\.item) ?? []
    }
}

// MARK: - Lossy item

private struct AthkarLossyItem: Decodable {
    let item: AthkarItem?

    init(from decoder: Decoder) throws {
        item = try? AthkarItem(from: decoder)
    }
}

// MARK: - Script

extension String {

    var athkarContainsArabic: Bool {
        unicodeScalars.contains(where: \.isArabicScript)
    }

    var athkarIsArabicDominant: Bool {
        var arabic = 0
        var latin = 0

        for scalar in unicodeScalars {
            if scalar.value >= 0xFDF0, scalar.value <= 0xFDFF { continue }
            if scalar.isArabicScript {
                arabic += 1
            } else if scalar.value < 0x0250, Character(scalar).isLetter {
                latin += 1
            }
        }

        return arabic > latin
    }
}

// MARK: - Scalar

private extension Unicode.Scalar {

    var isArabicScript: Bool {
        switch value {
        case 0x0600...0x06FF, 0x0750...0x077F, 0x08A0...0x08FF,
             0xFB50...0xFDFF, 0xFE70...0xFEFF:
            return true
        default:
            return false
        }
    }
}
