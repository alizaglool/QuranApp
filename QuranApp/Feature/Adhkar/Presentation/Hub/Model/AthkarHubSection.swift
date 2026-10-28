//
//  AthkarHubSection.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import Foundation
import Core

// MARK: - Section id

enum AthkarHubSectionID: String, Hashable {
    case daily
    case count
    case duaa
}

// MARK: - Layout

enum AthkarHubLayout: Hashable {
    case grid
    case list
}

// MARK: - Section

struct AthkarHubSection: Identifiable, Hashable {
    let id: AthkarHubSectionID
    let title: String
    let subtitle: String
    let layout: AthkarHubLayout
    let packs: [AthkarPack]

    var isEmpty: Bool { packs.isEmpty }

    var downloadablePacks: [AthkarPack] { packs.filter(\.hasAudio) }
}

// MARK: - Catalog

struct AthkarHubCatalog {
    let daily: [AthkarPack]
    let countable: [AthkarPack]
    let duaa: [AthkarPack]

    static let excludedKeys: Set<String> = ["names_of_allah"]

    var isEmpty: Bool { daily.isEmpty && countable.isEmpty && duaa.isEmpty }

    init(manifest: AthkarManifest) {
        let ordered = manifest.packs.sorted { $0.sort < $1.sort }
        let boundary = ordered.first { $0.group != .daily }?.sort ?? Int.max
        let readable = ordered.filter { !Self.excludedKeys.contains($0.key) }
        let isDaily: (AthkarPack) -> Bool = { $0.group == .daily && $0.sort < boundary }

        daily = readable.filter { $0.kind == .reader && isDaily($0) }
        countable = readable.filter { $0.kind == .reader && !isDaily($0) }
        duaa = readable.filter { $0.kind == .list }
    }
}

// MARK: - Icon

enum AthkarPackIcon {

    static func symbol(for key: String) -> String {
        switch key {
        case "morning":             return "sunrise.fill"
        case "evening":             return "sunset.fill"
        case "sleep":               return "moon.zzz.fill"
        case "wake_up":             return "sun.horizon.fill"
        case "after_prayer":        return "hands.sparkles.fill"
        case "tasbeeh_phrases":     return "circle.hexagongrid.fill"
        case "istighfar":           return "arrow.triangle.2.circlepath"
        case "last_two_verses":     return "book.closed.fill"
        case "ruqyah_quran":        return "heart.text.square.fill"
        case "ruqyah_sunnah":       return "cross.case.fill"
        case "kids_athkar":         return "figure.and.child.holdinghands"
        case "prayer":              return "figure.stand"
        case "quran_duaa":          return "text.book.closed.fill"
        case "prophet_duaa":        return "star.circle.fill"
        case "comprehensive_duaa":  return "square.stack.3d.up.fill"
        case "everyday_duaa":       return "calendar"
        case "praise":              return "sparkles"
        case "ease_duaa":           return "wind"
        case "qunoot":              return "moon.circle.fill"
        case "khatm_quran":         return "checkmark.seal.fill"
        default:                    return "book.fill"
        }
    }
}

// MARK: - Banner

struct AthkarHubBanner: Equatable {
    let badge: String
    let title: String
    let icon: String
    let packKey: String
}

// MARK: - Tint

enum AthkarPackTint {
    case primary
    case secondary

    static func tint(for mood: AthkarPackMood) -> AthkarPackTint {
        switch mood {
        case .evening, .sleep:   return .secondary
        case .morning, .general: return .primary
        }
    }

    var accent: ColorStyle {
        switch self {
        case .primary:   return .primary
        case .secondary: return .secondary
        }
    }

    var wash: ColorStyle {
        switch self {
        case .primary:   return .washPrimary
        case .secondary: return .washSecondary
        }
    }
}
