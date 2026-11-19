//
//  InsightsSummaryBuilder.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

@MainActor
final class InsightsSummaryBuilder {

    private let worshipTracker: WorshipTrackerStore
    private let prayerCompletion: PrayerCompletionStore
    private let readingLog: QuranReadingLogStore
    private let khatmahStore: KhatmahPlanStore

    init() {
        self.worshipTracker = .shared
        self.prayerCompletion = .shared
        self.readingLog = .shared
        self.khatmahStore = .shared
    }

    init(worshipTracker: WorshipTrackerStore,
         prayerCompletion: PrayerCompletionStore,
         readingLog: QuranReadingLogStore,
         khatmahStore: KhatmahPlanStore) {
        self.worshipTracker = worshipTracker
        self.prayerCompletion = prayerCompletion
        self.readingLog = readingLog
        self.khatmahStore = khatmahStore
    }
}

// MARK: - Summary

extension InsightsSummaryBuilder {

    func summary(range: InsightsRange, endingAt date: Date) -> InsightsSummary {
        worshipTracker.invalidateCompletionCache()

        let dayKeys = self.dayKeys(dayCount: range.dayCount, endingAt: date)

        return InsightsSummary(range: range,
                               dayPoints: dayPoints(dayKeys),
                               prayerConsistency: prayerConsistency(dayKeys),
                               trackedPrayerDayCount: trackedPrayerDayKeys(dayKeys).count,
                               prayedPrayerCount: prayedPrayerCount(dayKeys),
                               activeWorshipDayCount: activeWorshipDayCount(dayKeys),
                               readPageCount: readPageCount(dayKeys),
                               readingDayCount: readingDayCount(dayKeys),
                               khatmah: khatmahProgress(on: date),
                               completedKhatmahCount: khatmahStore.completedKhatmahCount)
    }
}

// MARK: - Days

private extension InsightsSummaryBuilder {

    func dayKeys(dayCount: Int, endingAt date: Date) -> [String] {
        guard dayCount > 0 else { return [] }
        return (0..<dayCount).reversed().map { offset in
            readingLog.dayKey(for: readingLog.date(byAddingDays: -offset, to: date))
        }
    }

    func dayPoints(_ dayKeys: [String]) -> [InsightsDayPoint] {
        dayKeys.map { key in
            InsightsDayPoint(dayKey: key,
                             readPageCount: readingLog.pageCount(on: key),
                             worshipFraction: worshipTracker.completionFraction(on: key))
        }
    }

    func activeWorshipDayCount(_ dayKeys: [String]) -> Int {
        dayKeys.filter { !worshipTracker.completedActs(on: $0).isEmpty }.count
    }

    func readPageCount(_ dayKeys: [String]) -> Int {
        dayKeys.reduce(0) { $0 + readingLog.pageCount(on: $1) }
    }

    func readingDayCount(_ dayKeys: [String]) -> Int {
        dayKeys.filter { readingLog.pageCount(on: $0) > 0 }.count
    }
}

// MARK: - Prayers

private extension InsightsSummaryBuilder {

    func trackedPrayerDayKeys(_ dayKeys: [String]) -> [String] {
        dayKeys.filter { !prayerCompletion.prayed(on: $0).isEmpty }
    }

    func prayedPrayerCount(_ dayKeys: [String]) -> Int {
        dayKeys.reduce(0) { $0 + prayerCompletion.count(on: $1) }
    }

    func prayerConsistency(_ dayKeys: [String]) -> [InsightsPrayerConsistency] {
        let trackedKeys = trackedPrayerDayKeys(dayKeys)
        let prayedSets = trackedKeys.map { prayerCompletion.prayed(on: $0) }

        return WorshipCategory.prayers.acts.compactMap { act in
            guard let index = act.prayerIndex else { return nil }
            let prayedDayCount = prayedSets.filter { $0.contains(index) }.count
            return InsightsPrayerConsistency(prayerIndex: index,
                                             prayedDayCount: prayedDayCount,
                                             trackedDayCount: trackedKeys.count)
        }
    }
}

// MARK: - Khatmah

private extension InsightsSummaryBuilder {

    func khatmahProgress(on date: Date) -> InsightsKhatmahProgress? {
        guard let plan = khatmahStore.activePlan else { return nil }

        let schedule = KhatmahPlanSchedule(plan: plan, calendar: khatmahStore.dayCalendar)

        return InsightsKhatmahProgress(readPageCount: schedule.actualPagesRead,
                                       totalPageCount: plan.pageCount,
                                       completedDayCount: plan.completedDayCount,
                                       totalDayCount: plan.totalDays,
                                       drift: schedule.drift(on: date))
    }
}
