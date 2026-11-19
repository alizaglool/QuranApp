//
//  QuranReadingLogStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct QuranReadingLog: Codable, Equatable {
    var pagesByDay: [String: Set<Int>]
}

@MainActor
final class QuranReadingLogStore {

    static let shared = QuranReadingLogStore()

    private static let storageKey = "quran_reading_log_v1"

    private let retainedDayLimit = 400
    private let defaults: UserDefaults
    private var cachedLog: QuranReadingLog?
    private var cachedCalendar: Calendar?
    private var cachedDayKeyFormatter: DateFormatter?
    private var cachedZoneIdentifier: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

// MARK: - Day Keys

extension QuranReadingLogStore {

    var dayCalendar: Calendar {
        refreshDayContextIfNeeded()
        return cachedCalendar ?? DayPrayerTimes.calendar(for: nil)
    }

    func dayKey(for date: Date) -> String {
        refreshDayContextIfNeeded()
        return cachedDayKeyFormatter?.string(from: date) ?? ""
    }

    func date(byAddingDays offset: Int, to date: Date) -> Date {
        dayCalendar.date(byAdding: .day, value: offset, to: date) ?? date
    }
}

// MARK: - Reads

extension QuranReadingLogStore {

    func pages(on dayKey: String) -> Set<Int> {
        loadLog().pagesByDay[dayKey] ?? []
    }

    func pageCount(on dayKey: String) -> Int {
        pages(on: dayKey).count
    }

    func recentPageCounts(dayCount: Int, endingAt date: Date) -> [(dayKey: String, pageCount: Int)] {
        guard dayCount > 0 else { return [] }
        let log = loadLog()
        return (0..<dayCount).reversed().map { offset in
            let key = dayKey(for: self.date(byAddingDays: -offset, to: date))
            return (key, log.pagesByDay[key]?.count ?? 0)
        }
    }
}

// MARK: - Writes

extension QuranReadingLogStore {

    func recordPageVisit(_ page: Int, on date: Date = Date()) {
        guard page > 0 else { return }

        let key = dayKey(for: date)
        guard !key.isEmpty else { return }

        var log = loadLog()
        var visitedPages = log.pagesByDay[key] ?? []
        guard !visitedPages.contains(page) else { return }

        visitedPages.insert(page)
        log.pagesByDay[key] = visitedPages
        saveLog(log)
    }

    func clearHistory() {
        cachedLog = QuranReadingLog(pagesByDay: [:])
        defaults.removeObject(forKey: Self.storageKey)
    }
}

// MARK: - Day Context Cache

private extension QuranReadingLogStore {

    func refreshDayContextIfNeeded() {
        let identifier = PrayerTimesStore.shared.today?.timeZoneIdentifier
            ?? DayPrayerTimes.fallbackTimeZoneIdentifier

        guard cachedZoneIdentifier != identifier || cachedDayKeyFormatter == nil else { return }

        let calendar = DayPrayerTimes.calendar(for: identifier)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        cachedCalendar = calendar
        cachedDayKeyFormatter = formatter
        cachedZoneIdentifier = identifier
    }
}

// MARK: - Storage

private extension QuranReadingLogStore {

    func loadLog() -> QuranReadingLog {
        if let cachedLog { return cachedLog }

        guard let data = defaults.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode(QuranReadingLog.self, from: data) else {
            let empty = QuranReadingLog(pagesByDay: [:])
            cachedLog = empty
            return empty
        }

        cachedLog = decoded
        return decoded
    }

    func saveLog(_ log: QuranReadingLog) {
        var trimmed = log

        if trimmed.pagesByDay.count > retainedDayLimit {
            let retainedKeys = Set(trimmed.pagesByDay.keys.sorted().suffix(retainedDayLimit))
            trimmed.pagesByDay = trimmed.pagesByDay.filter { retainedKeys.contains($0.key) }
        }

        cachedLog = trimmed
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
