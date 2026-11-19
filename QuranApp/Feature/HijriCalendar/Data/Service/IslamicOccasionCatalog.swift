//
//  IslamicOccasionCatalog.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct IslamicOccasionCatalog {

    static let shared = IslamicOccasionCatalog()

    enum HijriMonth: Int {
        case muharram = 1
        case safar = 2
        case rabiAlAwwal = 3
        case rabiAlThani = 4
        case jumadaAlAwwal = 5
        case jumadaAlThani = 6
        case rajab = 7
        case shaban = 8
        case ramadan = 9
        case shawwal = 10
        case dhulQadah = 11
        case dhulHijjah = 12
    }

    enum Weekday: Int {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
    }

    private struct DatedOccasion {
        let month: HijriMonth
        let dayRange: ClosedRange<Int>
        let occasion: IslamicOccasion
    }

    private struct MonthlyOccasion {
        let dayRange: ClosedRange<Int>
        let occasion: IslamicOccasion
    }

    private struct WeekdayOccasion {
        let weekdays: Set<Int>
        let occasion: IslamicOccasion
    }

    private static let monthsWithoutWhiteDays: Set<Int> = [HijriMonth.ramadan.rawValue,
                                                           HijriMonth.dhulHijjah.rawValue]

    private let datedOccasions: [DatedOccasion] = [
        DatedOccasion(month: .muharram,
                      dayRange: 1...1,
                      occasion: IslamicOccasion(id: "hijri-new-year",
                                                titleKey: .hijriOccasionNewYear,
                                                kind: .sacred)),
        DatedOccasion(month: .muharram,
                      dayRange: 9...9,
                      occasion: IslamicOccasion(id: "tasua",
                                                titleKey: .hijriOccasionTasua,
                                                kind: .fasting)),
        DatedOccasion(month: .muharram,
                      dayRange: 10...10,
                      occasion: IslamicOccasion(id: "ashura",
                                                titleKey: .hijriOccasionAshura,
                                                kind: .fasting)),
        DatedOccasion(month: .ramadan,
                      dayRange: 1...1,
                      occasion: IslamicOccasion(id: "ramadan-start",
                                                titleKey: .hijriOccasionRamadanStart,
                                                kind: .sacred)),
        DatedOccasion(month: .ramadan,
                      dayRange: 21...30,
                      occasion: IslamicOccasion(id: "ramadan-last-ten",
                                                titleKey: .hijriOccasionLastTenNights,
                                                kind: .sacred)),
        DatedOccasion(month: .shawwal,
                      dayRange: 1...1,
                      occasion: IslamicOccasion(id: "eid-al-fitr",
                                                titleKey: .hijriOccasionEidAlFitr,
                                                kind: .celebration)),
        DatedOccasion(month: .dhulHijjah,
                      dayRange: 1...10,
                      occasion: IslamicOccasion(id: "dhul-hijjah-first-ten",
                                                titleKey: .hijriOccasionFirstTenDhulHijjah,
                                                kind: .sacred)),
        DatedOccasion(month: .dhulHijjah,
                      dayRange: 9...9,
                      occasion: IslamicOccasion(id: "day-of-arafah",
                                                titleKey: .hijriOccasionDayOfArafah,
                                                kind: .fasting)),
        DatedOccasion(month: .dhulHijjah,
                      dayRange: 10...10,
                      occasion: IslamicOccasion(id: "eid-al-adha",
                                                titleKey: .hijriOccasionEidAlAdha,
                                                kind: .celebration)),
        DatedOccasion(month: .dhulHijjah,
                      dayRange: 11...13,
                      occasion: IslamicOccasion(id: "days-of-tashriq",
                                                titleKey: .hijriOccasionDaysOfTashriq,
                                                kind: .sacred))
    ]

    private let monthlyOccasions: [MonthlyOccasion] = [
        MonthlyOccasion(dayRange: 13...15,
                        occasion: IslamicOccasion(id: "white-days",
                                                  titleKey: .hijriOccasionWhiteDays,
                                                  kind: .fasting))
    ]

    private let weekdayOccasions: [WeekdayOccasion] = [
        WeekdayOccasion(weekdays: [Weekday.monday.rawValue, Weekday.thursday.rawValue],
                        occasion: IslamicOccasion(id: "voluntary-fast-day",
                                                  titleKey: .hijriOccasionVoluntaryFastDay,
                                                  kind: .fasting)),
        WeekdayOccasion(weekdays: [Weekday.friday.rawValue],
                        occasion: IslamicOccasion(id: "friday-surah-al-kahf",
                                                  titleKey: .hijriOccasionFridaySurahAlKahf,
                                                  kind: .remembrance))
    ]

    // MARK: - Lookup

    func occasions(hijriMonth: Int, hijriDay: Int, weekday: Int) -> [IslamicOccasion] {
        var result: [IslamicOccasion] = []

        for entry in datedOccasions
        where entry.month.rawValue == hijriMonth && entry.dayRange.contains(hijriDay) {
            result.append(entry.occasion)
        }

        if !Self.monthsWithoutWhiteDays.contains(hijriMonth) {
            for entry in monthlyOccasions where entry.dayRange.contains(hijriDay) {
                result.append(entry.occasion)
            }
        }

        let isFastingForbidden = Self.isVoluntaryFastingForbidden(hijriMonth: hijriMonth,
                                                                  hijriDay: hijriDay)
        for entry in weekdayOccasions where entry.weekdays.contains(weekday) {
            if entry.occasion.kind == .fasting && isFastingForbidden { continue }
            result.append(entry.occasion)
        }

        return result
    }

    static func isVoluntaryFastingForbidden(hijriMonth: Int, hijriDay: Int) -> Bool {
        if hijriMonth == HijriMonth.ramadan.rawValue { return true }
        if hijriMonth == HijriMonth.shawwal.rawValue && hijriDay == 1 { return true }
        if hijriMonth == HijriMonth.dhulHijjah.rawValue && (10...13).contains(hijriDay) { return true }
        return false
    }
}
