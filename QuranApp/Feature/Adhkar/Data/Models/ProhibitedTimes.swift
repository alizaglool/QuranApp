//
//  ProhibitedTimes.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation

/// Contents of `prohibited_times.json` — the four windows in which voluntary
/// prayer is not offered, plus the hadith and exemptions shown with them.
struct ProhibitedTimesContent: Codable {
    let titleAr: String
    let introAr: String
    let hadithAr: String
    let hadithSourceAr: String
    let exemptionsTitleAr: String
    let exemptions: [String]
    let windows: [ProhibitedWindow]
}

extension ProhibitedTimesContent {

    /// Decoded once and shared. The categories screen needs the card title and
    /// the windows, the detail screen needs the whole document, and two
    /// independent decodes of one bundled file can only drift apart.
    static let bundled: ProhibitedTimesContent? = {
        guard let url = Bundle.main.url(forResource: "prohibited_times", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ProhibitedTimesContent.self, from: data)
    }()
}

struct ProhibitedWindow: Codable, Identifiable, Hashable {
    let id: String
    let titleAr: String
    let subtitleAr: String
    /// Shown on the Adhkar card while this window is the active one, so the
    /// card always names the window the user is actually in.
    let cardSubtitleAr: String
    let bullets: [String]
    let hadithAr: String?
    let hadithSourceAr: String?
    let start: WindowBound
    let end: WindowBound
}

/// A window edge, expressed as a prayer anchor plus a signed minute offset, so
/// the ruling lives in data instead of in Swift.
struct WindowBound: Codable, Hashable {

    enum Anchor: String, Codable {
        case fajr
        case sunrise
        case dhuhr
        case asr
        case sunset
        case maghrib
        case isha

        func minutes(in times: DayPrayerTimes) -> Int {
            switch self {
            case .fajr:    return times.fajr
            case .sunrise: return times.sunrise
            case .dhuhr:   return times.dhuhr
            case .asr:     return times.asr
            case .sunset:  return times.sunset
            case .maghrib: return times.maghrib
            case .isha:    return times.isha
            }
        }
    }

    let anchor: Anchor
    let offsetMinutes: Int

    func minutes(in times: DayPrayerTimes) -> Int {
        anchor.minutes(in: times) + offsetMinutes
    }
}
