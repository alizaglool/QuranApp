//
//  KhatmahTestDoubles.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core
@testable import QuranApp

// MARK: - KhatmahFixture

enum KhatmahFixture {

    static let timeZoneIdentifier = "Asia/Riyadh"
    static let startDayKey = "2026-11-01"

    static var calendar: Calendar { DayPrayerTimes.calendar(for: KhatmahFixture.timeZoneIdentifier) }

    static func calendar(timeZoneIdentifier: String) -> Calendar {
        DayPrayerTimes.calendar(for: timeZoneIdentifier)
    }

    static func plan(totalDays: Int,
                     startPage: Int = KhatmahPageBounds.firstPage,
                     endPage: Int = KhatmahPageBounds.lastPage,
                     startDayKey: String = KhatmahFixture.startDayKey,
                     completedDayNumbers: Set<Int> = [],
                     reminder: KhatmahReminder = .default) -> KhatmahPlan {
        KhatmahPlan(createdAt: KhatmahFixture.date(dayKey: startDayKey, hour: 9),
                    startDayKey: startDayKey,
                    totalDays: totalDays,
                    startPage: startPage,
                    endPage: endPage,
                    completedDayNumbers: completedDayNumbers,
                    reminder: reminder)
    }

    static func schedule(totalDays: Int,
                         startPage: Int = KhatmahPageBounds.firstPage,
                         endPage: Int = KhatmahPageBounds.lastPage,
                         startDayKey: String = KhatmahFixture.startDayKey,
                         completedDayNumbers: Set<Int> = [],
                         reminder: KhatmahReminder = .default,
                         calendar: Calendar = KhatmahFixture.calendar) -> KhatmahPlanSchedule {
        KhatmahPlanSchedule(
            plan: KhatmahFixture.plan(totalDays: totalDays,
                                      startPage: startPage,
                                      endPage: endPage,
                                      startDayKey: startDayKey,
                                      completedDayNumbers: completedDayNumbers,
                                      reminder: reminder),
            calendar: calendar
        )
    }

    static func date(dayKey: String,
                     hour: Int = 12,
                     minute: Int = 0,
                     calendar: Calendar = KhatmahFixture.calendar) -> Date {
        let midnight = DayPrayerTimes.date(fromDayKey: dayKey, calendar: calendar)
            ?? Date(timeIntervalSince1970: 0)
        return calendar.date(byAdding: DateComponents(hour: hour, minute: minute), to: midnight) ?? midnight
    }

    static func dayKey(dayNumber: Int, calendar: Calendar = KhatmahFixture.calendar) -> String {
        let anchor = KhatmahFixture.date(dayKey: KhatmahFixture.startDayKey, hour: 0, calendar: calendar)
        let shifted = calendar.date(byAdding: .day, value: dayNumber - 1, to: anchor) ?? anchor
        return DayPrayerTimes.dayKey(for: shifted, calendar: calendar)
    }

    static func date(dayNumber: Int,
                     hour: Int = 12,
                     minute: Int = 0,
                     calendar: Calendar = KhatmahFixture.calendar) -> Date {
        KhatmahFixture.date(dayKey: KhatmahFixture.dayKey(dayNumber: dayNumber, calendar: calendar),
                            hour: hour,
                            minute: minute,
                            calendar: calendar)
    }
}

// MARK: - EgyptianRadioPlaybackSourceDouble

@MainActor
final class EgyptianRadioPlaybackSourceDouble: EgyptianRadioPlaybackSource {

    var currentStation: RadioStation?
    var isPlaying: Bool = false
    var isLoading: Bool = false
    var failure: RadioPlayerFailure?

    private(set) var playedStations: [RadioStation] = []
    private(set) var playedTitles: [String] = []
    private(set) var toggleCount: Int = 0
    private(set) var stopCount: Int = 0

    func play(station: RadioStation, title: String) {
        playedStations.append(station)
        playedTitles.append(title)
        currentStation = station
        isLoading = true
        failure = nil
    }

    func toggle() {
        toggleCount += 1
        isPlaying.toggle()
    }

    func stop() {
        stopCount += 1
        currentStation = nil
        isPlaying = false
        isLoading = false
    }
}
