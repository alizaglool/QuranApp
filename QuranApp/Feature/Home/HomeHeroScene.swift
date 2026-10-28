//
//  HomeHeroScene.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation

enum HomeHeroScene: String, CaseIterable {
    case lateNight
    case fajr
    case day
    case sunset
    case night
}

// MARK: - Presentation

extension HomeHeroScene {

    var assetName: String {
        switch self {
        case .lateNight:    return "homeSceneLateNight"
        case .fajr:         return "homeSceneFajr"
        case .day:          return "homeSceneDay"
        case .sunset:       return "homeSceneSunset"
        case .night:        return "homeSceneNight"
        }
    }

    var isLightScene: Bool {
        self == .fajr || self == .day
    }

    var scrimOpacity: Double {
        isLightScene ? 0.42 : 0.22
    }
}

// MARK: - Selection

extension HomeHeroScene {

    static func current(for times: DayPrayerTimes?, at date: Date) -> HomeHeroScene {
        guard let times else { return fallback(at: date) }

        let minute = times.minutes(at: date)

        if minute < times.fajr { return .lateNight }
        if minute < times.sunrise { return .fajr }
        if minute < times.sunset { return .day }
        if minute < times.isha { return .sunset }
        return .night
    }

    private static func fallback(at date: Date) -> HomeHeroScene {
        let hour = Calendar.current.component(.hour, from: date)

        switch hour {
        case ..<5:      return .lateNight
        case 5..<7:     return .fajr
        case 7..<18:    return .day
        case 18..<19:   return .sunset
        default:        return .night
        }
    }
}
