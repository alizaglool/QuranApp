//
//  PrayerWindowCalculator.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation

/// Turns a day's prayer anchors into the clock windows the app gates on.
///
/// Mirrors Athkar's own rules: أذكار الصباح open after Fajr, أذكار المساء after
/// Asr, أذكار النوم after Maghrib, القيام والوتر after Isha, and the
/// night dua runs from Islamic midnight to Fajr.
struct PrayerWindowCalculator {

    private let times: DayPrayerTimes

    init(times: DayPrayerTimes) {
        self.times = times
    }

    /// `nil` for a Hijri condition — those are calendar-based and answered by
    /// `DhikrVisibilityService` itself — and `nil` for any window the anchors
    /// make impossible, so a bad payload closes a section rather than opening
    /// one across most of the day.
    func window(for condition: DhikrCondition) -> ClockWindow? {
        switch condition {
        case .morning:
            // Fajr → Dhuhr, as in Athkar. Closing on the post-sunrise nafilah
            // grace instead would hide أذكار الصباح twenty minutes after
            // sunrise. That grace belongs to the first prohibited window and
            // lives in `prohibited_times.json`, where the window is described.
            return dayWindow(from: times.fajr, to: times.dhuhr)
        case .evening:
            return dayWindow(from: times.asr, to: times.maghrib)
        case .afterMaghrib:
            // Maghrib → Isha looks intra-day in Riyadh, but at high latitude in
            // summer Isha lands past midnight, so the wrap is legitimate here.
            return nightWindow(from: times.maghrib, to: times.isha)
        case .afterIsha:
            return nightWindow(from: times.isha, to: times.midnight)
        case .qiyam:
            return nightWindow(from: times.isha, to: times.fajr)
        case .lastThirdOfNight:
            return nightWindow(from: times.lastThird, to: times.fajr)
        case .dhulHijjahFirstTen, .arafah, .eidAdha, .tashreeq, .ramadan, .eidFitr:
            return nil
        }
    }

    /// A window that belongs to a single clock day. Fajr precedes Dhuhr and Asr
    /// precedes Maghrib at every latitude, so a wrap here means the anchors
    /// crossed, and "closed" is safer than a window covering almost the day.
    private func dayWindow(from start: Int, to end: Int) -> ClockWindow? {
        let window = ClockWindow(start: start, end: end)
        return (window.wrapsMidnight || window.isEmpty) ? nil : window
    }

    /// A window allowed to run through midnight, bounded by the night it
    /// belongs to. Two ways it can be wrong: zero length, which `contains(_:)`
    /// would read as the whole day, or longer than the night — at high latitude
    /// Aladhan can place Isha a minute *after* Islamic midnight, and without the
    /// length check أذكار بعد العشاء would gate open for 23 hours 59 minutes.
    private func nightWindow(from start: Int, to end: Int) -> ClockWindow? {
        let window = ClockWindow(start: start, end: end)
        guard !window.isEmpty, window.length <= nightLength else { return nil }
        return window
    }

    /// Sunset → the following Fajr. Every night window has to fit inside it, and
    /// a degenerate night of zero minutes closes all of them, which is correct:
    /// there is no night to pray in.
    private var nightLength: Int {
        ClockWindow(start: times.sunset, end: times.fajr).length
    }

    func isOpen(_ condition: DhikrCondition, atMinutes minutes: Int) -> Bool {
        guard let window = window(for: condition) else { return false }
        return window.contains(minutes)
    }

    // MARK: - Prohibited Times

    /// `nil` when the resolved anchors would make the window wrap midnight or
    /// collapse to nothing. A prohibited window is minutes long by design, so a
    /// wrap means the anchors crossed — at an extreme latitude Asr can fall past
    /// `sunset - 10` — and "no window" is the honest answer there, rather than a
    /// warning that covers almost the whole day.
    func window(for prohibited: ProhibitedWindow) -> ClockWindow? {
        let window = ClockWindow(
            start: prohibited.start.minutes(in: times),
            end: prohibited.end.minutes(in: times)
        )
        return (window.wrapsMidnight || window.isEmpty) ? nil : window
    }

    /// The window the given moment falls in, or `nil` when prayer is permitted.
    /// The first match wins — the four windows never overlap.
    func activeProhibitedWindow(in windows: [ProhibitedWindow], atMinutes minutes: Int) -> ProhibitedWindow? {
        windows.first { window(for: $0)?.contains(minutes) == true }
    }
}
