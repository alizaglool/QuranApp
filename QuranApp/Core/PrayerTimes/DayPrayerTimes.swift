//
//  DayPrayerTimes.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation

/// One day's prayer anchors, each stored as minutes since local midnight.
///
/// Minutes rather than `Date` for two reasons: the value survives a
/// `UserDefaults` round trip unchanged, and a window that crosses midnight
/// becomes a plain wrap-around comparison instead of date arithmetic.
struct DayPrayerTimes: Codable, Equatable {

    /// The local calendar day these anchors belong to, `yyyy-MM-dd`.
    let dayKey: String

    let fajr: Int
    let sunrise: Int
    let dhuhr: Int
    let asr: Int
    let sunset: Int
    let maghrib: Int
    let isha: Int
    /// Islamic midnight — the midpoint between sunset and the following Fajr.
    let midnight: Int
    /// Start of the last third of the night. It falls after midnight, so its
    /// value is normally smaller than `isha`.
    let lastThird: Int

    /// The zone every anchor above is expressed in — `"Asia/Riyadh"` for the
    /// pinned city. Optional so a cache written before this field existed still
    /// decodes; `nil` falls back to `fallbackTimeZoneIdentifier`.
    let timeZoneIdentifier: String?

    /// The pinned city's zone. Used when a payload omits `meta`: the anchors are
    /// Riyadh's either way, so reading them on the device's clock would gate
    /// hours out for a user sitting anywhere else.
    static let fallbackTimeZoneIdentifier = "Asia/Riyadh"
}

// MARK: - Clock Helpers

extension DayPrayerTimes {

    /// The calendar the anchors live on. Prayer times arrive on the city's own
    /// clock, so a user sitting in another zone is still measured against
    /// Riyadh's minutes rather than their own.
    var calendar: Calendar { DayPrayerTimes.calendar(for: timeZoneIdentifier) }

    /// Minutes since midnight measured in *this day's* zone.
    func minutes(at date: Date) -> Int {
        DayPrayerTimes.minutesSinceMidnight(of: date, calendar: calendar)
    }

    static func calendar(for timeZoneIdentifier: String?) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZoneIdentifier.flatMap(TimeZone.init(identifier:))
            ?? TimeZone(identifier: fallbackTimeZoneIdentifier)
            ?? .current
        return calendar
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        dayKeyFormatter(calendar: calendar).string(from: date)
    }

    /// The inverse of `dayKey(for:calendar:)`, so a cached day can be aged
    /// against today on the anchors' own calendar rather than the device's.
    static func date(fromDayKey dayKey: String, calendar: Calendar) -> Date? {
        dayKeyFormatter(calendar: calendar).date(from: dayKey)
    }

    private static func dayKeyFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        return formatter
    }

    static func minutesSinceMidnight(of date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}

// MARK: - API Mapping

extension DayPrayerTimes {

    /// `nil` when any anchor is missing or unparseable. The caller then keeps
    /// whatever it had rather than publishing a half-built day, which would
    /// open or close windows at the wrong moment.
    init?(response: PrayerTimesData, dayKey: String) {
        let timings = response.timings

        guard let fajr = DayPrayerTimes.minutes(from: timings.Fajr),
              let sunrise = DayPrayerTimes.minutes(from: timings.Sunrise),
              let dhuhr = DayPrayerTimes.minutes(from: timings.Dhuhr),
              let asr = DayPrayerTimes.minutes(from: timings.Asr),
              let sunset = DayPrayerTimes.minutes(from: timings.Sunset),
              let maghrib = DayPrayerTimes.minutes(from: timings.Maghrib),
              let isha = DayPrayerTimes.minutes(from: timings.Isha),
              let midnight = DayPrayerTimes.minutes(from: timings.Midnight),
              let lastThird = DayPrayerTimes.minutes(from: timings.Lastthird)
        else { return nil }

        self.dayKey = dayKey
        self.timeZoneIdentifier = response.meta?.timezone ?? DayPrayerTimes.fallbackTimeZoneIdentifier
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.sunset = sunset
        self.maghrib = maghrib
        self.isha = isha
        self.midnight = midnight
        self.lastThird = lastThird
    }

    /// Aladhan returns `"HH:mm"`. Some payloads append a zone, `"04:26 (AST)"`,
    /// so only the leading clock is read. A missing value reads as `nil`, which
    /// makes the whole day `nil` and keeps every window closed.
    private static func minutes(from value: String?) -> Int? {
        guard let value else { return nil }
        let clock = value.trimmingCharacters(in: .whitespaces).prefix(5)
        let parts = clock.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else { return nil }
        return hour * 60 + minute
    }
}
