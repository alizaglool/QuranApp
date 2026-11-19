//
//  HijriMonthGridBuilder.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct HijriMonthGridBuilder {

    static let firstWeekday = 1
    static let weekdayCount = 7

    private let calendar: Calendar
    private let catalog: IslamicOccasionCatalog

    init(timeZone: TimeZone = .current, catalog: IslamicOccasionCatalog = .shared) {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        calendar.firstWeekday = Self.firstWeekday
        self.calendar = calendar
        self.catalog = catalog
    }

    // MARK: - Month assembly

    func month(containing date: Date, today: Date) -> HijriCalendarMonth {
        let anchor = calendar.dateComponents([.year, .month], from: date)
        guard let year = anchor.year,
              let monthNumber = anchor.month,
              let firstDate = calendar.date(from: DateComponents(year: year,
                                                                  month: monthNumber,
                                                                  day: 1)),
              let dayNumbers = calendar.range(of: .day, in: .month, for: firstDate)
        else { return .empty }

        let firstWeekday = calendar.component(.weekday, from: firstDate)
        let leadingBlankCount = (firstWeekday - calendar.firstWeekday + Self.weekdayCount) % Self.weekdayCount
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)

        var days: [HijriCalendarDay] = []
        for dayNumber in dayNumbers {
            guard let dayDate = calendar.date(from: DateComponents(year: year,
                                                                   month: monthNumber,
                                                                   day: dayNumber))
            else { continue }

            let weekday = calendar.component(.weekday, from: dayDate)
            let isToday = todayComponents.year == year
                && todayComponents.month == monthNumber
                && todayComponents.day == dayNumber

            days.append(HijriCalendarDay(id: "\(year)-\(monthNumber)-\(dayNumber)",
                                         hijriDay: dayNumber,
                                         hijriMonth: monthNumber,
                                         hijriYear: year,
                                         gregorianDate: dayDate,
                                         isToday: isToday,
                                         occasions: catalog.occasions(hijriMonth: monthNumber,
                                                                      hijriDay: dayNumber,
                                                                      weekday: weekday)))
        }

        return HijriCalendarMonth(hijriMonth: monthNumber,
                                  hijriYear: year,
                                  leadingBlankCount: leadingBlankCount,
                                  days: days)
    }

    func month(offsetBy monthOffset: Int, from date: Date, today: Date) -> HijriCalendarMonth {
        let anchor = calendar.dateComponents([.year, .month], from: date)
        guard let year = anchor.year,
              let monthNumber = anchor.month,
              let firstDate = calendar.date(from: DateComponents(year: year,
                                                                  month: monthNumber,
                                                                  day: 1)),
              let shifted = calendar.date(byAdding: .month, value: monthOffset, to: firstDate)
        else { return month(containing: date, today: today) }

        return month(containing: shifted, today: today)
    }

    // MARK: - Weekday headers

    func weekdayTitles(languageCode: String) -> [String] {
        let locale = Locale(identifier: languageCode)
        var symbolCalendar = Calendar(identifier: .islamicUmmAlQura)
        symbolCalendar.locale = locale

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = symbolCalendar
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? []
        guard symbols.count == Self.weekdayCount else { return [] }

        let offset = Self.firstWeekday - 1
        return (0 ..< Self.weekdayCount).map { symbols[($0 + offset) % Self.weekdayCount] }
    }
}
