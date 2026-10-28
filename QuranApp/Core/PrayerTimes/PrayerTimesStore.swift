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

    private static let storageKey = "prayer_times_day_v3"
    private let service = QuranService.shared
    private let locationStore = SelectedLocationStore.shared
    private let defaults = UserDefaults.standard
    private var refreshTask: Task<Void, Never>?
    private var cachedLocationIdentifier: String?

    /// Anchors drift a minute or two a day, so yesterday's cache is a better
    /// gate than none. Last month's is not: a device that never reaches the
    /// network would otherwise keep gating sections on whatever it last saw.
    private let maxCacheAgeInDays = 3

    private init() {
        let restored = restoredCacheEntry()
        today = restored?.times
        cachedLocationIdentifier = restored?.locationIdentifier
    }

    /// Serves the cache when it already covers today at the selected location,
    /// otherwise refreshes once. Safe to call on every `onAppear`.
    func loadTodayForSelectedLocation() {
        let location = locationStore.selectedLocation

        // Measured on the anchors' own clock once we have them, so the day
        // rolls over at the selected location's midnight, not the device's.
        let calendar = today?.calendar ?? DayPrayerTimes.calendar(for: location.timeZoneIdentifier)
        let dayKey = DayPrayerTimes.dayKey(for: Date(), calendar: calendar)

        let isCacheCurrent = today?.dayKey == dayKey
            && cachedLocationIdentifier == location.prayerTimesCacheIdentifier
        guard !isCacheCurrent else { return }
        guard refreshTask == nil else { return }

        refreshTask = Task { [weak self] in
            await self?.refresh(for: location)
            self?.refreshTask = nil
        }
    }

    /// Drops the cached day so the next load fetches the newly selected
    /// location instead of serving the previous city's anchors until midnight.
    func reloadAfterSelectedLocationChange() {
        refreshTask?.cancel()
        refreshTask = nil
        clearCacheEntry()
        loadTodayForSelectedLocation()
    }

    // MARK: - Private

    private func refresh(for location: SelectedLocation) async {
        do {
            let data = try await service.fetchPrayerTimes(latitude: location.latitude,
                                                          longitude: location.longitude)
            // Stamped with the payload's own zone. On a cold launch the day key
            // is the only freshness signal there is, and the device zone would
            // file the fetched anchors under the wrong calendar day.
            let calendar = DayPrayerTimes.calendar(for: data.meta?.timezone)
            let dayKey = DayPrayerTimes.dayKey(for: Date(), calendar: calendar)
            guard let parsed = DayPrayerTimes(response: data, dayKey: dayKey) else {
                print("❌ Prayer times store: incomplete timings for \(dayKey)")
                return
            }
            today = parsed
            cachedLocationIdentifier = location.prayerTimesCacheIdentifier
            persist(parsed, locationIdentifier: location.prayerTimesCacheIdentifier)
        } catch {
            // Yesterday's cache is kept deliberately. Anchors move by a minute
            // or two a day, so a stale day is a far better gate than no gate.
            // Past the age bound it stops being one, and a closed gate is the
            // honest answer — a card at the wrong hour is worse than no card.
            print("❌ Prayer times store: \(error)")
            if let current = today, !isFresh(current) {
                clearCacheEntry()
            }
        }
    }

    private func persist(_ times: DayPrayerTimes, locationIdentifier: String) {
        let entry = CachedPrayerTimesEntry(locationIdentifier: locationIdentifier, times: times)
        guard let encoded = try? JSONEncoder().encode(entry) else { return }
        defaults.set(encoded, forKey: PrayerTimesStore.storageKey)
    }

    private func clearCacheEntry() {
        today = nil
        cachedLocationIdentifier = nil
        defaults.removeObject(forKey: PrayerTimesStore.storageKey)
    }

    private func restoredCacheEntry() -> CachedPrayerTimesEntry? {
        guard let data = defaults.data(forKey: PrayerTimesStore.storageKey),
              let decoded = try? JSONDecoder().decode(CachedPrayerTimesEntry.self, from: data)
        else { return nil }
        // A blob written before the zone was recorded would keep being read on
        // the device clock for the rest of the day. Dropping it costs one fetch
        // and makes the zone fix take hold on the first launch after the update.
        guard decoded.times.timeZoneIdentifier != nil else { return nil }
        guard isFresh(decoded.times) else { return nil }
        return decoded
    }

    /// Measured on the anchors' own calendar, so a user in another zone neither
    /// ages the cached day early nor keeps it a day too long. A day key
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


/// Pairs a cached day with the location it was fetched for, so switching city
/// cannot keep serving the previous city's anchors until the next calendar day.
private struct CachedPrayerTimesEntry: Codable {
    let locationIdentifier: String
    let times: DayPrayerTimes
}
