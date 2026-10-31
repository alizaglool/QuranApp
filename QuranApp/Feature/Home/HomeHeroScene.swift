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
        self == .fajr || self == .day || self == .sunset
    }

    func scrimStops(isDarkAppearance: Bool) -> [Double] {
        let base = isLightScene ? HomeHeroScene.lightSceneBaseScrim : HomeHeroScene.darkSceneBaseScrim
        let boost = isDarkAppearance ? HomeHeroScene.darkAppearanceScrimBoost : 0
        return [base + HomeHeroScene.topScrimLift + boost,
                base + boost,
                base + HomeHeroScene.bottomScrimLift + boost]
    }

    private static let lightSceneBaseScrim: Double = 0.48
    private static let darkSceneBaseScrim: Double = 0.22
    private static let topScrimLift: Double = 0.10
    private static let bottomScrimLift: Double = 0.16
    private static let darkAppearanceScrimBoost: Double = 0.08
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
