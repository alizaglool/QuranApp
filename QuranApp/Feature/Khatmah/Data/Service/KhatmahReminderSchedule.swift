//
//  KhatmahReminderSchedule.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

enum KhatmahNotificationIdentifier {

    static let ownedPrefix = "khatmah_reminder"
    private static let separator = "."

    static let ownedIdentifierPrefix = KhatmahNotificationIdentifier.ownedPrefix
        + KhatmahNotificationIdentifier.separator

    static func identifier(dayKey: String) -> String {
        [KhatmahNotificationIdentifier.ownedPrefix, dayKey]
            .joined(separator: KhatmahNotificationIdentifier.separator)
    }

    static func isOwned(_ identifier: String) -> Bool {
        identifier.hasPrefix(KhatmahNotificationIdentifier.ownedIdentifierPrefix)
    }

    static func dayKey(of identifier: String) -> String? {
        let parts = identifier.components(separatedBy: KhatmahNotificationIdentifier.separator)
        guard parts.count == 2, parts[0] == KhatmahNotificationIdentifier.ownedPrefix else { return nil }
        return parts[1]
    }
}

struct KhatmahReminderScheduleEntry: Equatable {

    let identifier: String
    let dayKey: String
    let dayNumber: Int
    let firstPage: Int
    let lastPage: Int
    let fireDate: Date
    let dateComponents: DateComponents
}

struct KhatmahReminderScheduleBuilder {

    static let pendingRequestLimit = LocalNotificationPendingBudget.requestLimit
    static let maximumWindowInDays = 7

    let clock: LocalNotificationClock

    func entries(for schedule: KhatmahPlanSchedule) -> [KhatmahReminderScheduleEntry] {
        let reminder = schedule.plan.reminder
        guard reminder.isEnabled else { return [] }

        let calendar = schedule.calendar
        let now = clock.currentDate
        let firstDayNumber = max(schedule.elapsedDayNumber(on: now), 1)
        var dayGroups: [[KhatmahReminderScheduleEntry]] = []

        for offset in 0..<KhatmahReminderScheduleBuilder.maximumWindowInDays {
            let dayNumber = firstDayNumber + offset
            guard schedule.plan.dayNumbers.contains(dayNumber) else { break }
            guard !schedule.plan.isDayCompleted(dayNumber) else { continue }

            guard let entry = entry(forDay: dayNumber,
                                    schedule: schedule,
                                    reminder: reminder,
                                    calendar: calendar,
                                    now: now)
            else { continue }

            dayGroups.append([entry])
        }

        return LocalNotificationPendingBudget
            .affordableGroups(dayGroups, limit: KhatmahReminderScheduleBuilder.pendingRequestLimit)
            .flatMap { $0 }
    }
}

private extension KhatmahReminderScheduleBuilder {

    func entry(forDay dayNumber: Int,
               schedule: KhatmahPlanSchedule,
               reminder: KhatmahReminder,
               calendar: Calendar,
               now: Date) -> KhatmahReminderScheduleEntry? {

        let dayKey = schedule.dayKey(ofDay: dayNumber)
        guard let dayStart = DayPrayerTimes.date(fromDayKey: dayKey, calendar: calendar),
              let fireDate = calendar.date(bySettingHour: reminder.clampedHour,
                                           minute: reminder.clampedMinute,
                                           second: 0,
                                           of: calendar.startOfDay(for: dayStart)),
              fireDate > now
        else { return nil }

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        components.timeZone = calendar.timeZone

        return KhatmahReminderScheduleEntry(
            identifier: KhatmahNotificationIdentifier.identifier(dayKey: dayKey),
            dayKey: dayKey,
            dayNumber: dayNumber,
            firstPage: schedule.firstPage(ofDay: dayNumber),
            lastPage: schedule.lastPage(ofDay: dayNumber),
            fireDate: fireDate,
            dateComponents: components
        )
    }
}
