//
//  PrayerClockFormatter.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 21/10/2026.
//

import Foundation

enum PrayerClockFormatter {

    static func twelveHourClock(fromMinutesSinceMidnight minutes: Int) -> String {
        let normalizedMinutes = ((minutes % minutesPerDay) + minutesPerDay) % minutesPerDay
        let hour = normalizedMinutes / 60
        let minute = normalizedMinutes % 60

        return "\(displayHour(forHour: hour)):\(String(format: "%02d", minute)) \(suffix(forHour: hour))"
    }
}

// MARK: - Components

private extension PrayerClockFormatter {

    static let minutesPerDay = 24 * 60

    static func displayHour(forHour hour: Int) -> Int {
        let twelveHour = hour % 12
        return twelveHour == 0 ? 12 : twelveHour
    }

    static func suffix(forHour hour: Int) -> String {
        hour < 12
            ? AppLocalizedKeys.clockMorningSuffix.value
            : AppLocalizedKeys.clockEveningSuffix.value
    }
}
