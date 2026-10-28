//
//  WorshipAct.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import Foundation
import Core

enum WorshipCategory: String, Codable, CaseIterable {
    case prayers
    case athkar
    case quran
}

enum WorshipAct: String, Codable, CaseIterable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha
    case morningAthkar
    case eveningAthkar
    case tasbih
    case quranReading
}

// MARK: - Grouping

extension WorshipAct {

    var category: WorshipCategory {
        switch self {
        case .fajr, .dhuhr, .asr, .maghrib, .isha:
            return .prayers
        case .morningAthkar, .eveningAthkar, .tasbih:
            return .athkar
        case .quranReading:
            return .quran
        }
    }

    var prayerIndex: Int? {
        switch self {
        case .fajr: return 0
        case .dhuhr: return 1
        case .asr: return 2
        case .maghrib: return 3
        case .isha: return 4
        default: return nil
        }
    }

    var openingCondition: DhikrCondition? {
        switch self {
        case .morningAthkar: return .morning
        case .eveningAthkar: return .evening
        default: return nil
        }
    }

    init?(adhkarCategoryIdentifier: String) {
        switch adhkarCategoryIdentifier {
        case "morning": self = .morningAthkar
        case "evening": self = .eveningAthkar
        case "tasbih", "tasbih_extra": self = .tasbih
        default: return nil
        }
    }

    static func act(forPrayerIndex index: Int) -> WorshipAct? {
        allCases.first { $0.prayerIndex == index }
    }
}

// MARK: - Presentation

extension WorshipAct {

    var titleKey: AppLocalizedKeys {
        switch self {
        case .fajr: return .fajr
        case .dhuhr: return .dhuhr
        case .asr: return .asr
        case .maghrib: return .maghrib
        case .isha: return .isha
        case .morningAthkar: return .athkarMorningTitle
        case .eveningAthkar: return .athkarEveningTitle
        case .tasbih: return .worshipTasbih
        case .quranReading: return .worshipQuranReading
        }
    }

    var iconName: String {
        switch self {
        case .fajr: return "sunrise"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.haze"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        case .morningAthkar: return "sun.horizon"
        case .eveningAthkar: return "moon"
        case .tasbih: return "circle.hexagongrid"
        case .quranReading: return "book"
        }
    }
}

extension WorshipCategory {

    var acts: [WorshipAct] {
        WorshipAct.allCases.filter { $0.category == self }
    }

    var titleKey: AppLocalizedKeys {
        switch self {
        case .prayers: return .worshipPrayers
        case .athkar: return .worshipAthkar
        case .quran: return .worshipQuran
        }
    }

    var accent: ColorStyle {
        switch self {
        case .prayers: return .primary
        case .athkar: return .quickAccentAdhkar
        case .quran: return .secondary
        }
    }
}
