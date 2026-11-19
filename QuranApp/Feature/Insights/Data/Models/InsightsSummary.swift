//
//  InsightsSummary.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

enum InsightsRange: Int, CaseIterable, Identifiable {
    case week = 7
    case month = 30
    case quarter = 90

    var id: Int { rawValue }

    var dayCount: Int { rawValue }
}

struct InsightsDayPoint: Equatable, Identifiable {

    let dayKey: String
    let readPageCount: Int
    let worshipFraction: Double

    var id: String { dayKey }
}

struct InsightsPrayerConsistency: Equatable, Identifiable {

    let prayerIndex: Int
    let prayedDayCount: Int
    let trackedDayCount: Int

    var id: Int { prayerIndex }

    var fraction: Double {
        guard trackedDayCount > 0 else { return 0 }
        return Double(prayedDayCount) / Double(trackedDayCount)
    }
}

struct InsightsKhatmahProgress: Equatable {

    let readPageCount: Int
    let totalPageCount: Int
    let completedDayCount: Int
    let totalDayCount: Int
    let drift: KhatmahDrift

    var fraction: Double {
        guard totalPageCount > 0 else { return 0 }
        return min(Double(readPageCount) / Double(totalPageCount), 1)
    }
}

struct InsightsSummary: Equatable {

    let range: InsightsRange
    let dayPoints: [InsightsDayPoint]
    let prayerConsistency: [InsightsPrayerConsistency]
    let trackedPrayerDayCount: Int
    let prayedPrayerCount: Int
    let activeWorshipDayCount: Int
    let readPageCount: Int
    let readingDayCount: Int
    let khatmah: InsightsKhatmahProgress?
    let completedKhatmahCount: Int

    static let empty = InsightsSummary(range: .week,
                                       dayPoints: [],
                                       prayerConsistency: [],
                                       trackedPrayerDayCount: 0,
                                       prayedPrayerCount: 0,
                                       activeWorshipDayCount: 0,
                                       readPageCount: 0,
                                       readingDayCount: 0,
                                       khatmah: nil,
                                       completedKhatmahCount: 0)
}

// MARK: - Derived Values

extension InsightsSummary {

    var hasAnyActivity: Bool {
        prayedPrayerCount > 0 || readPageCount > 0 || activeWorshipDayCount > 0
    }

    var peakReadPageCount: Int {
        dayPoints.map(\.readPageCount).max() ?? 0
    }

    var averageReadPageCount: Double {
        guard !dayPoints.isEmpty else { return 0 }
        return Double(readPageCount) / Double(dayPoints.count)
    }

    var worshipCompletionFraction: Double {
        guard !dayPoints.isEmpty else { return 0 }
        let total = dayPoints.reduce(0) { $0 + $1.worshipFraction }
        return total / Double(dayPoints.count)
    }

    var prayerCompletionFraction: Double {
        let expected = trackedPrayerDayCount * WorshipCategory.prayers.acts.count
        guard expected > 0 else { return 0 }
        return min(Double(prayedPrayerCount) / Double(expected), 1)
    }

    var strongestPrayer: InsightsPrayerConsistency? {
        guard trackedPrayerDayCount > 0 else { return nil }
        return prayerConsistency.max { $0.fraction < $1.fraction }
    }

    var weakestPrayer: InsightsPrayerConsistency? {
        guard trackedPrayerDayCount > 0 else { return nil }
        return prayerConsistency.min { $0.fraction < $1.fraction }
    }
}
