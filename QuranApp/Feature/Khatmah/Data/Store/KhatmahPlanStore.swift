//
//  KhatmahPlanStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

struct KhatmahArchiveEntry: Codable, Equatable, Identifiable {

    let plan: KhatmahPlan
    let archivedAt: Date

    var id: Date { plan.createdAt }
}

@MainActor
final class KhatmahPlanStore: ObservableObject {

    static let shared = KhatmahPlanStore()

    @Published private(set) var activePlan: KhatmahPlan?
    @Published private(set) var archivedPlans: [KhatmahArchiveEntry]
    @Published private(set) var completedKhatmahCount: Int

    private enum DefaultsKey {
        static let activePlan = "khatmah.activePlan"
        static let archive = "khatmah.archive"
        static let completedCount = "khatmah.completedCount"
    }

    private let retainedArchiveLimit = 50
    private let defaults: UserDefaults
    private var cachedCalendar: Calendar?
    private var cachedDayKeyFormatter: DateFormatter?
    private var cachedZoneIdentifier: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.activePlan = KhatmahPlanStore
            .decode(KhatmahPlan.self, from: defaults, key: DefaultsKey.activePlan)
        self.archivedPlans = KhatmahPlanStore
            .decode([KhatmahArchiveEntry].self, from: defaults, key: DefaultsKey.archive) ?? []
        self.completedKhatmahCount = defaults.integer(forKey: DefaultsKey.completedCount)
    }
}

// MARK: - Day Keys

extension KhatmahPlanStore {

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

    func dayCount(from startDate: Date, to endDate: Date) -> Int {
        let calendar = dayCalendar
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return difference + 1
    }
}

// MARK: - Day Context Cache

private extension KhatmahPlanStore {

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

extension KhatmahPlanStore {

    var hasActivePlan: Bool { activePlan != nil }

    var activeSchedule: KhatmahPlanSchedule? {
        activePlan.map { KhatmahPlanSchedule(plan: $0, calendar: dayCalendar) }
    }
}

// MARK: - Writes

extension KhatmahPlanStore {

    @discardableResult
    func createPlan(totalDays: Int,
                    startDate: Date,
                    startPage: Int = KhatmahPageBounds.firstPage,
                    endPage: Int = KhatmahPageBounds.lastPage,
                    reminder: KhatmahReminder = .default) -> KhatmahPlan {
        let plan = KhatmahPlan(
            createdAt: Date(),
            startDayKey: dayKey(for: startDate),
            totalDays: totalDays,
            startPage: startPage,
            endPage: endPage,
            reminder: reminder
        )
        store(plan)
        return plan
    }

    func toggleDayCompletion(_ dayNumber: Int) {
        guard var plan = activePlan, plan.dayNumbers.contains(dayNumber) else { return }

        if plan.completedDayNumbers.contains(dayNumber) {
            plan.completedDayNumbers.remove(dayNumber)
        } else {
            plan.completedDayNumbers.insert(dayNumber)
        }
        store(plan)
    }

    func markDayCompleted(_ dayNumber: Int) {
        guard var plan = activePlan,
              plan.dayNumbers.contains(dayNumber),
              !plan.completedDayNumbers.contains(dayNumber)
        else { return }

        plan.completedDayNumbers.insert(dayNumber)
        store(plan)
    }

    func updateReminder(_ reminder: KhatmahReminder) {
        guard var plan = activePlan, plan.reminder != reminder else { return }
        plan.reminder = reminder
        store(plan)
    }

    func archiveActivePlan() {
        guard let plan = activePlan else { return }

        var archive = archivedPlans
        archive.insert(KhatmahArchiveEntry(plan: plan, archivedAt: Date()), at: 0)
        if archive.count > retainedArchiveLimit {
            archive = Array(archive.prefix(retainedArchiveLimit))
        }
        archivedPlans = archive
        persist(archive, key: DefaultsKey.archive)

        if plan.isCompleted {
            completedKhatmahCount += 1
            defaults.set(completedKhatmahCount, forKey: DefaultsKey.completedCount)
        }

        activePlan = nil
        defaults.removeObject(forKey: DefaultsKey.activePlan)
    }

    func clearAll() {
        activePlan = nil
        archivedPlans = []
        completedKhatmahCount = 0
        defaults.removeObject(forKey: DefaultsKey.activePlan)
        defaults.removeObject(forKey: DefaultsKey.archive)
        defaults.removeObject(forKey: DefaultsKey.completedCount)
    }
}

// MARK: - Storage

private extension KhatmahPlanStore {

    static func decode<Value: Decodable>(_ type: Value.Type,
                                         from defaults: UserDefaults,
                                         key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func store(_ plan: KhatmahPlan) {
        activePlan = plan
        persist(plan, key: DefaultsKey.activePlan)
    }

    func persist<Value: Encodable>(_ value: Value, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }
}
