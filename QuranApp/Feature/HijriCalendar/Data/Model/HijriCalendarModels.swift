//
//  HijriCalendarModels.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

enum IslamicOccasionKind: String {
    case celebration
    case fasting
    case sacred
    case remembrance
}

struct IslamicOccasion: Identifiable, Hashable {
    let id: String
    let titleKey: AppLocalizedKeys
    let kind: IslamicOccasionKind
}

struct HijriCalendarDay: Identifiable, Hashable {
    let id: String
    let hijriDay: Int
    let hijriMonth: Int
    let hijriYear: Int
    let gregorianDate: Date
    let isToday: Bool
    let occasions: [IslamicOccasion]

    var hasOccasion: Bool { !occasions.isEmpty }

    var highlightKind: IslamicOccasionKind? {
        occasions.first?.kind
    }
}

struct HijriCalendarCell: Identifiable, Hashable {
    let id: String
    let day: HijriCalendarDay?

    var isBlank: Bool { day == nil }
}

struct HijriCalendarMonth {
    let hijriMonth: Int
    let hijriYear: Int
    let leadingBlankCount: Int
    let days: [HijriCalendarDay]

    static let empty = HijriCalendarMonth(hijriMonth: 0,
                                          hijriYear: 0,
                                          leadingBlankCount: 0,
                                          days: [])

    var isEmpty: Bool { days.isEmpty }

    var firstDate: Date? { days.first?.gregorianDate }

    var todayDay: HijriCalendarDay? {
        days.first { $0.isToday }
    }

    func day(numbered number: Int) -> HijriCalendarDay? {
        days.first { $0.hijriDay == number }
    }

    var cells: [HijriCalendarCell] {
        let blanks = (0 ..< leadingBlankCount).map {
            HijriCalendarCell(id: "blank-\($0)", day: nil)
        }
        return blanks + days.map { HijriCalendarCell(id: $0.id, day: $0) }
    }
}
