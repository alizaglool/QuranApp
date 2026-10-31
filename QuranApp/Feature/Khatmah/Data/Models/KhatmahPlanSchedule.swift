//
//  KhatmahPlanSchedule.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

struct KhatmahPlanSchedule: Equatable {

    let plan: KhatmahPlan
    let calendar: Calendar

    init(plan: KhatmahPlan, calendar: Calendar) {
        self.plan = plan
        self.calendar = calendar
    }
}

// MARK: - Page Distribution

extension KhatmahPlanSchedule {

    func cumulativePages(throughDay dayNumber: Int) -> Int {
        let clamped = min(max(dayNumber, 0), plan.totalDays)
        let exact = Double(clamped) * Double(plan.pageCount) / Double(plan.totalDays)
        return plan.startPage - 1 + Int(exact.rounded())
    }

    func firstPage(ofDay dayNumber: Int) -> Int {
        cumulativePages(throughDay: dayNumber - 1) + 1
    }

    func lastPage(ofDay dayNumber: Int) -> Int {
        cumulativePages(throughDay: dayNumber)
    }

    func pageCount(ofDay dayNumber: Int) -> Int {
        lastPage(ofDay: dayNumber) - firstPage(ofDay: dayNumber) + 1
    }
}

// MARK: - Dates

extension KhatmahPlanSchedule {

    var startDate: Date? {
        DayPrayerTimes.date(fromDayKey: plan.startDayKey, calendar: calendar)
    }

    var expectedCompletionDate: Date? {
        guard let startDate else { return nil }
        return calendar.date(byAdding: .day, value: plan.totalDays - 1, to: startDate)
    }

    func dayKey(ofDay dayNumber: Int) -> String {
        guard let startDate,
              let date = calendar.date(byAdding: .day, value: dayNumber - 1, to: startDate)
        else { return plan.startDayKey }
        return DayPrayerTimes.dayKey(for: date, calendar: calendar)
    }

    func elapsedDayNumber(on date: Date) -> Int {
        guard let startDate else { return 1 }
        let fromDay = calendar.startOfDay(for: startDate)
        let toDay = calendar.startOfDay(for: date)
        let difference = calendar.dateComponents([.day], from: fromDay, to: toDay).day ?? 0
        return difference + 1
    }

    func currentDayNumber(on date: Date) -> Int {
        min(max(elapsedDayNumber(on: date), 1), plan.totalDays)
    }

    func hasStarted(on date: Date) -> Bool {
        elapsedDayNumber(on: date) >= 1
    }
}

// MARK: - Days

extension KhatmahPlanSchedule {

    func days(on date: Date) -> [KhatmahDay] {
        plan.dayNumbers.map { day(number: $0, on: date) }
    }

    func day(number dayNumber: Int, on date: Date) -> KhatmahDay {
        KhatmahDay(
            dayNumber: dayNumber,
            dayKey: dayKey(ofDay: dayNumber),
            firstPage: firstPage(ofDay: dayNumber),
            lastPage: lastPage(ofDay: dayNumber),
            status: status(ofDay: dayNumber, on: date)
        )
    }

    func today(on date: Date) -> KhatmahDay {
        day(number: currentDayNumber(on: date), on: date)
    }

    func status(ofDay dayNumber: Int, on date: Date) -> KhatmahDayStatus {
        if plan.isDayCompleted(dayNumber) { return .completed }

        let elapsed = elapsedDayNumber(on: date)
        if dayNumber == elapsed { return .today }
        return dayNumber < elapsed ? .missed : .upcoming
    }
}

// MARK: - Progress

extension KhatmahPlanSchedule {

    var actualPagesRead: Int {
        plan.dayNumbers
            .filter(plan.isDayCompleted)
            .reduce(0) { $0 + pageCount(ofDay: $1) }
    }

    var remainingPages: Int {
        max(plan.pageCount - actualPagesRead, 0)
    }

    var completionFraction: Double {
        guard plan.pageCount > 0 else { return 0 }
        return min(Double(actualPagesRead) / Double(plan.pageCount), 1)
    }

    var nextUncompletedDayNumber: Int? {
        plan.dayNumbers.first { !plan.isDayCompleted($0) }
    }

    var resumePage: Int {
        guard let dayNumber = nextUncompletedDayNumber else { return plan.endPage }
        return firstPage(ofDay: dayNumber)
    }

    func expectedPagesRead(by date: Date) -> Int {
        guard hasStarted(on: date) else { return 0 }
        let elapsed = min(elapsedDayNumber(on: date), plan.totalDays)
        return cumulativePages(throughDay: elapsed) - (plan.startPage - 1)
    }

    func drift(on date: Date) -> KhatmahDrift {
        let difference = actualPagesRead - expectedPagesRead(by: date)
        if difference > 0 { return .ahead(pages: difference) }
        if difference < 0 { return .behind(pages: -difference) }
        return .onSchedule
    }
}
