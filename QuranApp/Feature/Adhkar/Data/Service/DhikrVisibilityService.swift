//
//  DhikrVisibilityService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import Foundation

/// Decides whether a conditional dhikr category is open at a given moment.
/// Hijri windows are answered from the calendar; prayer-time windows are
/// delegated to `PrayerWindowCalculator` using the day's anchors.
struct DhikrVisibilityService {

    private let hijriCalendar: Calendar
    private let prayerTimes: DayPrayerTimes?

    /// `prayerTimes` of `nil` keeps every prayer-timed condition closed, so a
    /// failed fetch hides a card rather than showing it at the wrong hour.
    init(prayerTimes: DayPrayerTimes? = nil) {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .current
        hijriCalendar = calendar
        self.prayerTimes = prayerTimes
    }

    /// An unrecognised condition string keeps the category hidden, so a typo in
    /// `adhkar.json` fails closed instead of showing a seasonal card all year.
    func isOpen(condition: String, on date: Date) -> Bool {
        guard let condition = DhikrCondition(rawValue: condition) else { return false }
        return isOpen(condition, on: date)
    }

    func isOpen(_ condition: DhikrCondition, on date: Date) -> Bool {
        switch condition {
        case .dhulHijjahFirstTen:
            return isHijri(date, month: 12, days: 1...10)
        case .arafah:
            return isHijri(date, month: 12, days: 9...9)
        case .eidAdha:
            return isHijri(date, month: 12, days: 10...10)
        case .tashreeq:
            return isHijri(date, month: 12, days: 11...13)
        case .ramadan:
            return isHijri(date, month: 9, days: 1...30)
        case .eidFitr:
            return isHijri(date, month: 10, days: 1...1)
        case .qiyam, .lastThirdOfNight, .afterIsha, .afterMaghrib, .morning, .evening:
            return isPrayerWindowOpen(condition, on: date)
        }
    }

    // MARK: - Private

    private func isPrayerWindowOpen(_ condition: DhikrCondition, on date: Date) -> Bool {
        guard let prayerTimes else { return false }
        let calculator = PrayerWindowCalculator(times: prayerTimes)
        return calculator.isOpen(condition, atMinutes: prayerTimes.minutes(at: date))
    }

    private func isHijri(_ date: Date, month: Int, days: ClosedRange<Int>) -> Bool {
        let components = hijriCalendar.dateComponents([.month, .day], from: date)
        guard let currentMonth = components.month, let currentDay = components.day else { return false }
        return currentMonth == month && days.contains(currentDay)
    }
}
