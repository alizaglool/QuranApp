//
//  AdhkarModels.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation

struct DhikrCategory: Codable, Identifiable, Hashable {
    let id: String
    let titleAr: String
    let titleEn: String
    let icon: String
    let adhkar: [Dhikr]
    let condition: String?
    let section: String?

    init(id: String, titleAr: String, titleEn: String, icon: String,
         adhkar: [Dhikr], condition: String? = nil, section: String? = nil) {
        self.id = id
        self.titleAr = titleAr
        self.titleEn = titleEn
        self.icon = icon
        self.adhkar = adhkar
        self.condition = condition
        self.section = section
    }
}

struct Dhikr: Codable, Identifiable, Hashable {
    let id: String
    let textAr: String
    let description: String?
    let title: String?
    let count: Int
    let audio: String?
    let segments: [DhikrSegment]?
    let repeatLabel: String?
}

/// One styled run inside a dhikr. A dhikr that ships `segments` is rendered
/// piece by piece; one that does not falls back to `textAr` + `description`.
struct DhikrSegment: Codable, Hashable {
    enum Kind: String, Codable {
        case intro        // basmala / isti'adha  -> accent colour, medium size
        case quran        // Quranic text         -> Hafs font, primary colour
        case text         // plain dhikr body     -> primary colour, body font
        case note         // fadl / narration / source reference -> accent colour, small
        case noteAlways   // same as note, exempt from a future hide-explanations toggle
        case rule         // horizontal divider, no text
    }
    let kind: Kind
    let text: String?
}

extension DhikrSegment {

    private enum CodingKeys: String, CodingKey {
        case kind
        case text
    }

    /// A `kind` the app does not know yet must never cost us the whole file,
    /// so anything unreadable degrades to `.text` instead of throwing.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawKind = try? container.decode(String.self, forKey: .kind)
        self.kind = Kind(rawValue: rawKind ?? "") ?? .text
        self.text = try? container.decode(String.self, forKey: .text)
    }
}

struct AllahName: Codable, Identifiable, Hashable {
    let id: Int
    let nameAr: String
    let transliteration: String
    let meaning: String?
    let descriptionAr: String?
}

enum DhikrSection: String {
    case daily = "daily"
    case special = "special"
    case more = "more"
}
