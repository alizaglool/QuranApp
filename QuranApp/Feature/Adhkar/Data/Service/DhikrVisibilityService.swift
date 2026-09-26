//
//  DhikrVisibilityService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import Foundation

/// Decides whether a conditional dhikr category is open at a given moment.
/// Hijri windows are evaluated here; prayer-time windows stay closed until the
/// shared prayer-times store lands.
struct DhikrVisibilityService {

    private let hijriCalendar: Calendar

    init() {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = .current
        hijriCalendar = calendar
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
            return false
        }
    }

    // MARK: - Private

    private func isHijri(_ date: Date, month: Int, days: ClosedRange<Int>) -> Bool {
        let components = hijriCalendar.dateComponents([.month, .day], from: date)
        guard let currentMonth = components.month, let currentDay = components.day else { return false }
        return currentMonth == month && days.contains(currentDay)
    }
}
