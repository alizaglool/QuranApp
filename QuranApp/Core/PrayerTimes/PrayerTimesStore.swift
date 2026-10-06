//
//  PrayerTimesStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation
import Combine

/// Single source of today's prayer anchors for every time-gated section.
///
/// Cached in `UserDefaults` rather than SwiftData on purpose: `StorageManager`
/// wipes the whole store on a schema mismatch, so a new `@Model` would cost the
/// user their bookmarks and reading progress the next time the schema moves.
@MainActor
final class PrayerTimesStore: ObservableObject {

    static let shared = PrayerTimesStore()

    /// `nil` until a day has been fetched or read back from the cache. Callers
    /// treat `nil` as "no gate can open" so a card never shows at the wrong hour.
    @Published private(set) var today: DayPrayerTimes?

    private let service = QuranService.shared
    private let defaults = UserDefaults.standard
    private let storageKey = "prayer_times_day_v1"
    private var refreshTask: Task<Void, Never>?

    /// Anchors drift a minute or two a day, so yesterday's cache is a better
    /// gate than none. Last month's is not: a device that never reaches the
    /// network would otherwise keep gating sections on whatever it last saw.
    private let maxCacheAgeInDays = 3

    private init() {
        today = cached()
    }

    /// Serves the cache when it already covers today, otherwise refreshes once.
    /// Safe to call on every `onAppear`.
    func load(city: String = "Riyadh", country: String = "SA") {
        // Measured on the anchors' own clock once we have them, so the day
        // rolls over at Riyadh midnight rather than the device's.
        let key = DayPrayerTimes.dayKey(for: Date(), calendar: today?.calendar ?? DayPrayerTimes.calendar(for: nil))
        guard today?.dayKey != key else { return }
        guard refreshTask == nil else { return }

        refreshTask = Task { [weak self] in
            await self?.refresh(city: city, country: country)
            self?.refreshTask = nil
        }
    }

    // MARK: - Private

    private func refresh(city: String, country: String) async {
        do {
            let data = try await service.fetchPrayerTimes(city: city, country: country)
            // Stamped with the payload's own zone. On a cold launch the day key
            // is the only freshness signal there is, and the device zone would
            // file the Riyadh anchors under the wrong calendar day.
            let calendar = DayPrayerTimes.calendar(for: data.meta?.timezone)
            let dayKey = DayPrayerTimes.dayKey(for: Date(), calendar: calendar)
            guard let parsed = DayPrayerTimes(response: data, dayKey: dayKey) else {
                print("❌ Prayer times store: incomplete timings for \(dayKey)")
                return
            }
            today = parsed
            persist(parsed)
        } catch {
            // Yesterday's cache is kept deliberately. Anchors move by a minute
            // or two a day, so a stale day is a far better gate than no gate.
            // Past the age bound it stops being one, and a closed gate is the
            // honest answer — a card at the wrong hour is worse than no card.
            print("❌ Prayer times store: \(error)")
            if let current = today, !isFresh(current) {
                today = nil
                defaults.removeObject(forKey: storageKey)
            }
        }
    }

    private func persist(_ times: DayPrayerTimes) {
        guard let encoded = try? JSONEncoder().encode(times) else { return }
        defaults.set(encoded, forKey: storageKey)
    }

    private func cached() -> DayPrayerTimes? {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(DayPrayerTimes.self, from: data)
        else { return nil }
        // A blob written before the zone was recorded would keep being read on
        // the device clock for the rest of the day. Dropping it costs one fetch
        // and makes the zone fix take hold on the first launch after the update.
        guard decoded.timeZoneIdentifier != nil else { return nil }
        guard isFresh(decoded) else { return nil }
        return decoded
    }

    /// Measured on the anchors' own calendar, so a user in another zone neither
    /// ages the Riyadh cache a day early nor keeps it a day too long. A day key
    /// in the future — the device clock moved back — also reads as stale.
    private func isFresh(_ times: DayPrayerTimes) -> Bool {
        let calendar = times.calendar
        guard let cachedDay = DayPrayerTimes.date(fromDayKey: times.dayKey, calendar: calendar),
              let age = calendar.dateComponents([.day],
                                                from: calendar.startOfDay(for: cachedDay),
                                                to: calendar.startOfDay(for: Date())).day
        else { return false }
        return (0...maxCacheAgeInDays).contains(age)
    }
}
