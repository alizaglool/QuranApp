//
//  AppSettings.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-02.
//


import Foundation
import SwiftData

@Model
final class AppSettings {
    var selectedLanguage: String
    var selectedReciterId: String
    var selectedReciterName: String
    var fontSize: Double
    var themeMode: String
    var isOnboardingCompleted: Bool
    var createdAt: Date
    /// "mushaf" | "text" | tafsir-book-id (e.g. "ar-saadi")
    var mushafType: String
    /// Raw storage — use `scrollDirection` computed property instead
    var scrollDirectionRaw: String
    /// Raw storage — use `selectedTheme` computed property instead
    var selectedThemeRaw: String

    /// Computed — not persisted directly; backed by `scrollDirectionRaw`
    var scrollDirection: ScrollDirection {
        get { ScrollDirection(rawValue: scrollDirectionRaw) ?? .horizontal }
        set { scrollDirectionRaw = newValue.rawValue }
    }

    /// Computed — not persisted directly; backed by `selectedThemeRaw`
    var selectedTheme: Theme {
        get { Theme(rawValue: selectedThemeRaw) ?? .classic }
        set { selectedThemeRaw = newValue.rawValue }
    }

    /// Computed — not persisted directly; backed by `mushafType`
    var mushafDisplayType: MushafType {
        get { MushafType(rawValue: mushafType) }
        set { mushafType = newValue.rawValue }
    }

    init(
        selectedLanguage: String = "ar",
        selectedReciterId: String = "afasy",
        selectedReciterName: String = "مشاري العفاسي",
        fontSize: Double = 1.0,
        themeMode: String = "system",
        isOnboardingCompleted: Bool = false,
        mushafType: String = "mushaf",
        scrollDirection: ScrollDirection = .horizontal,
        selectedTheme: Theme = .classic
    ) {
        self.selectedLanguage = selectedLanguage
        self.selectedReciterId = selectedReciterId
        self.selectedReciterName = selectedReciterName
        self.fontSize = fontSize
        self.themeMode = themeMode
        self.isOnboardingCompleted = isOnboardingCompleted
        self.createdAt = Date()
        self.mushafType = mushafType
        self.scrollDirectionRaw = scrollDirection.rawValue
        self.selectedThemeRaw = selectedTheme.rawValue
    }
}

enum Theme: String, CaseIterable, Codable {
    case classic, tinted
}

enum ScrollDirection: String, CaseIterable, Codable {
    case horizontal, vertical
}

enum MushafType: Equatable {
    case mushaf
    case text
    case tafsir(id: String)

    var rawValue: String {
        switch self {
        case .mushaf:           return "mushaf"
        case .text:             return "text"
        case .tafsir(let id):   return id
        }
    }

    init(rawValue: String) {
        switch rawValue {
        case "mushaf": self = .mushaf
        case "text":   self = .text
        default:       self = .tafsir(id: rawValue)
        }
    }

    var isSkeuomorphic: Bool { self == .mushaf }
}
