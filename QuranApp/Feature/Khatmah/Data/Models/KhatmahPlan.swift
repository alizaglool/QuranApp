//
//  KhatmahPlan.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

enum KhatmahPageBounds {
    static let firstPage = 1
    static let lastPage = 604
    static let totalPages = KhatmahPageBounds.lastPage - KhatmahPageBounds.firstPage + 1
}

enum KhatmahDurationPreset: Int, CaseIterable, Identifiable {
    case week = 7
    case fortnight = 15
    case month = 30
    case twoMonths = 60
    case threeMonths = 90
    case fourMonths = 120

    var id: Int { rawValue }

    var dayCount: Int { rawValue }
}

struct KhatmahReminder: Codable, Equatable {

    var isEnabled: Bool
    var hour: Int
    var minute: Int

    static let `default` = KhatmahReminder(isEnabled: true, hour: 20, minute: 0)

    var clampedHour: Int { min(max(hour, 0), 23) }

    var clampedMinute: Int { min(max(minute, 0), 59) }
}

struct KhatmahPlan: Codable, Equatable {

    let createdAt: Date
    let startDayKey: String
    let totalDays: Int
    let startPage: Int
    let endPage: Int
    var completedDayNumbers: Set<Int>
    var reminder: KhatmahReminder

    init(createdAt: Date,
         startDayKey: String,
         totalDays: Int,
         startPage: Int = KhatmahPageBounds.firstPage,
         endPage: Int = KhatmahPageBounds.lastPage,
         completedDayNumbers: Set<Int> = [],
         reminder: KhatmahReminder = .default) {
        let clampedStart = min(max(startPage, KhatmahPageBounds.firstPage), KhatmahPageBounds.lastPage)
        let clampedEnd = min(max(endPage, clampedStart), KhatmahPageBounds.lastPage)
        let pageCount = clampedEnd - clampedStart + 1

        self.createdAt = createdAt
        self.startDayKey = startDayKey
        self.totalDays = min(max(totalDays, 1), pageCount)
        self.startPage = clampedStart
        self.endPage = clampedEnd
        self.completedDayNumbers = completedDayNumbers
        self.reminder = reminder
    }
}

// MARK: - Derived Values

extension KhatmahPlan {

    var pageCount: Int { endPage - startPage + 1 }

    var completedDayCount: Int { completedDayNumbers.filter(dayNumbers.contains).count }

    var isCompleted: Bool { completedDayCount >= totalDays }

    var dayNumbers: ClosedRange<Int> { 1...totalDays }

    func isDayCompleted(_ dayNumber: Int) -> Bool { completedDayNumbers.contains(dayNumber) }
}

enum KhatmahDayStatus {
    case completed
    case today
    case missed
    case upcoming
}

struct KhatmahDay: Equatable, Identifiable {

    let dayNumber: Int
    let dayKey: String
    let firstPage: Int
    let lastPage: Int
    let status: KhatmahDayStatus

    var id: Int { dayNumber }

    var pageCount: Int { lastPage - firstPage + 1 }
}

enum KhatmahDrift: Equatable {
    case onSchedule
    case ahead(pages: Int)
    case behind(pages: Int)
}
