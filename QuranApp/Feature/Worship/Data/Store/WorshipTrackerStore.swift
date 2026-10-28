//
//  WorshipTrackerStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import Foundation

struct WorshipHistory: Codable, Equatable {
    var days: [String: Set<WorshipAct>]
}

@MainActor
final class WorshipTrackerStore {

    static let shared = WorshipTrackerStore()

    private let historyDefaultsKey = "worship.tracker"
    private let retainedDayLimit = 400
    private let defaults: UserDefaults
    private let prayerCompletion: PrayerCompletionStore
    private var cachedHistory: WorshipHistory?
    private var cachedCompletedActs: [String: Set<WorshipAct>] = [:]
    private var cachedCalendar: Calendar?
    private var cachedDayKeyFormatter: DateFormatter?
    private var cachedZoneIdentifier: String?

    init(defaults: UserDefaults = .standard,
         prayerCompletion: PrayerCompletionStore = .shared) {
        self.defaults = defaults
        self.prayerCompletion = prayerCompletion
    }
}

// MARK: - Day Keys

extension WorshipTrackerStore {

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

// MARK: - Day Context Cache

private extension WorshipTrackerStore {

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

// MARK: - Reads

extension WorshipTrackerStore {

    func completedActs(on dayKey: String) -> Set<WorshipAct> {
        if let cached = cachedCompletedActs[dayKey] { return cached }

        var combined = loadHistory().days[dayKey] ?? []
        for index in prayerCompletion.prayed(on: dayKey) {
            guard let act = WorshipAct.act(forPrayerIndex: index) else { continue }
            combined.insert(act)
        }
        cachedCompletedActs[dayKey] = combined
        return combined
    }

    func isActCompleted(_ act: WorshipAct, on dayKey: String) -> Bool {
        completedActs(on: dayKey).contains(act)
    }

    func isCategoryCompleted(_ category: WorshipCategory, on dayKey: String) -> Bool {
        let done = completedActs(on: dayKey)
        return category.acts.allSatisfy { done.contains($0) }
    }

    func isEveryCategoryCompleted(on dayKey: String) -> Bool {
        WorshipCategory.allCases.allSatisfy { isCategoryCompleted($0, on: dayKey) }
    }

    func completedActCount(on dayKey: String) -> Int {
        completedActs(on: dayKey).count
    }

    func completionFraction(on dayKey: String) -> Double {
        let total = WorshipAct.allCases.count
        guard total > 0 else { return 0 }
        return Double(completedActCount(on: dayKey)) / Double(total)
    }
}

// MARK: - Streaks

extension WorshipTrackerStore {

    func currentStreak(for category: WorshipCategory, endingAt date: Date) -> Int {
        currentStreakLength(endingAt: date) { self.isCategoryCompleted(category, on: $0) }
    }

    func currentOverallStreak(endingAt date: Date) -> Int {
        currentStreakLength(endingAt: date) { self.isEveryCategoryCompleted(on: $0) }
    }

    func bestStreak(for category: WorshipCategory, endingAt date: Date) -> Int {
        longestStreakLength(endingAt: date) { self.isCategoryCompleted(category, on: $0) }
    }

    func bestOverallStreak(endingAt date: Date) -> Int {
        longestStreakLength(endingAt: date) { self.isEveryCategoryCompleted(on: $0) }
    }

    func recentCompletionFractions(dayCount: Int, endingAt date: Date) -> [(dayKey: String, fraction: Double)] {
        (0..<dayCount).reversed().map { offset in
            let key = dayKey(for: self.date(byAddingDays: -offset, to: date))
            return (key, completionFraction(on: key))
        }
    }
}

// MARK: - Writes

extension WorshipTrackerStore {

    func toggleCompletion(for act: WorshipAct, on dayKey: String) {
        cachedCompletedActs[dayKey] = nil

        if let index = act.prayerIndex {
            prayerCompletion.toggle(index: index, on: dayKey)
            return
        }

        var record = loadHistory()
        var day = record.days[dayKey] ?? []
        if day.contains(act) {
            day.remove(act)
        } else {
            day.insert(act)
        }
        record.days[dayKey] = day
        saveHistory(record)
    }

    func markCompleted(_ act: WorshipAct, on dayKey: String? = nil) {
        let key = dayKey ?? self.dayKey(for: Date())
        cachedCompletedActs[key] = nil

        if let index = act.prayerIndex {
            guard !prayerCompletion.isPrayed(index: index, on: key) else { return }
            prayerCompletion.toggle(index: index, on: key)
            return
        }

        var record = loadHistory()
        var day = record.days[key] ?? []
        guard !day.contains(act) else { return }
        day.insert(act)
        record.days[key] = day
        saveHistory(record)
    }

    func markCompleted(adhkarCategoryIdentifier: String) {
        guard let act = WorshipAct(adhkarCategoryIdentifier: adhkarCategoryIdentifier) else { return }
        markCompleted(act)
    }

    func invalidateCompletionCache() {
        cachedCompletedActs.removeAll()
    }

    func clearAllHistory() {
        cachedHistory = nil
        cachedCompletedActs.removeAll()
        defaults.removeObject(forKey: historyDefaultsKey)
    }
}

// MARK: - Streak Walking

private extension WorshipTrackerStore {

    func currentStreakLength(endingAt date: Date, isSatisfied: (String) -> Bool) -> Int {
        var cursor = date
        if !isSatisfied(dayKey(for: cursor)) {
            cursor = self.date(byAddingDays: -1, to: cursor)
        }

        var total = 0
        while total < retainedDayLimit, isSatisfied(dayKey(for: cursor)) {
            total += 1
            cursor = self.date(byAddingDays: -1, to: cursor)
        }
        return total
    }

    func longestStreakLength(endingAt date: Date, isSatisfied: (String) -> Bool) -> Int {
        var best = 0
        var running = 0

        for offset in 0..<retainedDayLimit {
            let key = dayKey(for: self.date(byAddingDays: -offset, to: date))
            if isSatisfied(key) {
                running += 1
                best = max(best, running)
            } else {
                running = 0
            }
        }
        return best
    }
}

// MARK: - Storage

private extension WorshipTrackerStore {

    func loadHistory() -> WorshipHistory {
        if let cachedHistory { return cachedHistory }

        guard let data = defaults.data(forKey: historyDefaultsKey),
              let decoded = try? JSONDecoder().decode(WorshipHistory.self, from: data) else {
            let empty = WorshipHistory(days: [:])
            cachedHistory = empty
            return empty
        }
        cachedHistory = decoded
        return decoded
    }

    func saveHistory(_ record: WorshipHistory) {
        var trimmed = record
        if trimmed.days.count > retainedDayLimit {
            let retained = Set(trimmed.days.keys.sorted().suffix(retainedDayLimit))
            trimmed.days = trimmed.days.filter { retained.contains($0.key) }
        }
        cachedHistory = trimmed
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        defaults.set(data, forKey: historyDefaultsKey)
    }
}
