//
//  KhatmahPlanScheduleTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
import Core
@testable import QuranApp

final class KhatmahPlanScheduleTests: XCTestCase {

    // MARK: - Distribution Invariants

    func testEveryDurationCoversEveryPageExactlyOnce() {
        for totalDays in 1...KhatmahPageBounds.totalPages {
            let schedule = KhatmahFixture.schedule(totalDays: totalDays)

            var pagesCovered = 0
            var smallestDay = Int.max
            var isContiguous = true

            for dayNumber in 1...totalDays {
                pagesCovered += schedule.pageCount(ofDay: dayNumber)
                smallestDay = min(smallestDay, schedule.pageCount(ofDay: dayNumber))

                if dayNumber < totalDays,
                   schedule.lastPage(ofDay: dayNumber) + 1 != schedule.firstPage(ofDay: dayNumber + 1) {
                    isContiguous = false
                }
            }

            XCTAssertEqual(schedule.firstPage(ofDay: 1), KhatmahPageBounds.firstPage, "duration \(totalDays)")
            XCTAssertEqual(schedule.lastPage(ofDay: totalDays), KhatmahPageBounds.lastPage, "duration \(totalDays)")
            XCTAssertEqual(pagesCovered, KhatmahPageBounds.totalPages, "duration \(totalDays)")
            XCTAssertGreaterThanOrEqual(smallestDay, 1, "duration \(totalDays)")
            XCTAssertTrue(isContiguous, "duration \(totalDays) has a gap or an overlap")
        }
    }

    func testCumulativePagesLandsExactlyOnTheLastPage() {
        for totalDays in [1, 7, 15, 30, 60, 90, 120, 603, 604] {
            let schedule = KhatmahFixture.schedule(totalDays: totalDays)
            XCTAssertEqual(schedule.cumulativePages(throughDay: 0), KhatmahPageBounds.firstPage - 1)
            XCTAssertEqual(schedule.cumulativePages(throughDay: totalDays), KhatmahPageBounds.lastPage)
        }
    }

    func testCumulativePagesClampsOutOfRangeDayNumbers() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)

        XCTAssertEqual(schedule.cumulativePages(throughDay: -5), KhatmahPageBounds.firstPage - 1)
        XCTAssertEqual(schedule.cumulativePages(throughDay: 900), KhatmahPageBounds.lastPage)
    }

    // MARK: - Remainder Cases

    func testThirtyDayPlanSpreadsTheRemainderAcrossTheMonth() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)
        let counts = (1...30).map(schedule.pageCount(ofDay:))

        XCTAssertEqual(schedule.firstPage(ofDay: 1), 1)
        XCTAssertEqual(schedule.lastPage(ofDay: 1), 20)
        XCTAssertEqual(schedule.firstPage(ofDay: 4), 61)
        XCTAssertEqual(schedule.lastPage(ofDay: 4), 81)
        XCTAssertEqual(schedule.firstPage(ofDay: 30), 585)
        XCTAssertEqual(schedule.lastPage(ofDay: 30), 604)
        XCTAssertEqual(counts.filter { $0 == 21 }.count, 4)
        XCTAssertEqual(counts.filter { $0 == 20 }.count, 26)
        XCTAssertEqual(counts.reduce(0, +), KhatmahPageBounds.totalPages)
    }

    func testSevenDayPlanIsTheWorstRemainderCaseAndStillBalances() {
        let schedule = KhatmahFixture.schedule(totalDays: 7)

        XCTAssertEqual((1...7).map(schedule.pageCount(ofDay:)), [86, 87, 86, 86, 86, 87, 86])
        XCTAssertEqual(schedule.firstPage(ofDay: 1), 1)
        XCTAssertEqual(schedule.lastPage(ofDay: 2), 173)
        XCTAssertEqual(schedule.lastPage(ofDay: 7), 604)
    }

    func testSingleDayPlanCoversTheWholeQuran() {
        let schedule = KhatmahFixture.schedule(totalDays: 1)

        XCTAssertEqual(schedule.firstPage(ofDay: 1), KhatmahPageBounds.firstPage)
        XCTAssertEqual(schedule.lastPage(ofDay: 1), KhatmahPageBounds.lastPage)
        XCTAssertEqual(schedule.pageCount(ofDay: 1), KhatmahPageBounds.totalPages)
    }

    func testMaximumDayPlanGivesOnePagePerDay() {
        let schedule = KhatmahFixture.schedule(totalDays: KhatmahPageBounds.totalPages)

        XCTAssertEqual(schedule.pageCount(ofDay: 1), 1)
        XCTAssertEqual(schedule.pageCount(ofDay: 302), 1)
        XCTAssertEqual(schedule.firstPage(ofDay: 302), 302)
        XCTAssertEqual(schedule.pageCount(ofDay: KhatmahPageBounds.totalPages), 1)
    }

    // MARK: - Clamping

    func testTotalDaysIsClampedToThePageCount() {
        XCTAssertEqual(KhatmahFixture.plan(totalDays: 5_000).totalDays, KhatmahPageBounds.totalPages)
        XCTAssertEqual(KhatmahFixture.plan(totalDays: 0).totalDays, 1)
        XCTAssertEqual(KhatmahFixture.plan(totalDays: -3).totalDays, 1)
    }

    func testTotalDaysIsClampedToAPartialRangePageCount() {
        let plan = KhatmahFixture.plan(totalDays: 400, startPage: 100, endPage: 200)

        XCTAssertEqual(plan.pageCount, 101)
        XCTAssertEqual(plan.totalDays, 101)
    }

    func testPageBoundsAreClampedToTheMushaf() {
        let plan = KhatmahFixture.plan(totalDays: 10, startPage: -40, endPage: 9_000)

        XCTAssertEqual(plan.startPage, KhatmahPageBounds.firstPage)
        XCTAssertEqual(plan.endPage, KhatmahPageBounds.lastPage)
    }

    func testInvertedPageBoundsCollapseToASinglePage() {
        let plan = KhatmahFixture.plan(totalDays: 10, startPage: 300, endPage: 100)

        XCTAssertEqual(plan.startPage, 300)
        XCTAssertEqual(plan.endPage, 300)
        XCTAssertEqual(plan.pageCount, 1)
        XCTAssertEqual(plan.totalDays, 1)
    }

    // MARK: - Partial Ranges

    func testPartialRangePlanStaysInsideItsOwnBounds() {
        let schedule = KhatmahFixture.schedule(totalDays: 10, startPage: 100, endPage: 200)
        let counts = (1...10).map(schedule.pageCount(ofDay:))

        XCTAssertEqual(schedule.firstPage(ofDay: 1), 100)
        XCTAssertEqual(schedule.lastPage(ofDay: 10), 200)
        XCTAssertEqual(counts.reduce(0, +), 101)
        XCTAssertEqual(counts, [10, 10, 10, 10, 11, 10, 10, 10, 10, 10])
    }

    // MARK: - Dates

    func testExpectedCompletionDateIsTheLastDayOfThePlan() throws {
        let schedule = KhatmahFixture.schedule(totalDays: 30)
        let completion = try XCTUnwrap(schedule.expectedCompletionDate)

        XCTAssertEqual(schedule.dayKey(ofDay: 1), "2026-11-01")
        XCTAssertEqual(schedule.dayKey(ofDay: 30), "2026-11-30")
        XCTAssertEqual(DayPrayerTimes.dayKey(for: completion, calendar: KhatmahFixture.calendar),
                       "2026-11-30")
    }

    func testSingleDayPlanCompletesOnItsStartDate() {
        let schedule = KhatmahFixture.schedule(totalDays: 1)

        XCTAssertEqual(schedule.dayKey(ofDay: 1), KhatmahFixture.startDayKey)
        XCTAssertEqual(schedule.expectedCompletionDate, schedule.startDate)
    }

    func testDayKeysStayConsecutiveAcrossAMonthBoundary() {
        let schedule = KhatmahFixture.schedule(totalDays: 5, startDayKey: "2026-11-28")

        XCTAssertEqual((1...5).map(schedule.dayKey(ofDay:)),
                       ["2026-11-28", "2026-11-29", "2026-11-30", "2026-12-01", "2026-12-02"])
    }

    func testDayKeysStayConsecutiveAcrossADaylightSavingShift() {
        let calendar = KhatmahFixture.calendar(timeZoneIdentifier: "Europe/London")
        let schedule = KhatmahFixture.schedule(totalDays: 4,
                                               startDayKey: "2026-10-24",
                                               calendar: calendar)

        XCTAssertEqual((1...4).map(schedule.dayKey(ofDay:)),
                       ["2026-10-24", "2026-10-25", "2026-10-26", "2026-10-27"])
    }

    func testElapsedDayNumberCountsTheStartDateAsDayOne() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)

        XCTAssertEqual(schedule.elapsedDayNumber(on: KhatmahFixture.date(dayNumber: 1, hour: 0)), 1)
        XCTAssertEqual(schedule.elapsedDayNumber(on: KhatmahFixture.date(dayNumber: 1, hour: 23, minute: 59)), 1)
        XCTAssertEqual(schedule.elapsedDayNumber(on: KhatmahFixture.date(dayNumber: 12)), 12)
        XCTAssertEqual(schedule.elapsedDayNumber(on: KhatmahFixture.date(dayNumber: 0)), 0)
    }

    func testCurrentDayNumberClampsToThePlanBounds() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)

        XCTAssertEqual(schedule.currentDayNumber(on: KhatmahFixture.date(dayNumber: -4)), 1)
        XCTAssertEqual(schedule.currentDayNumber(on: KhatmahFixture.date(dayNumber: 30)), 30)
        XCTAssertEqual(schedule.currentDayNumber(on: KhatmahFixture.date(dayNumber: 90)), 30)
    }

    func testHasStartedIsFalseOnlyBeforeTheStartDate() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)

        XCTAssertFalse(schedule.hasStarted(on: KhatmahFixture.date(dayNumber: 0)))
        XCTAssertTrue(schedule.hasStarted(on: KhatmahFixture.date(dayNumber: 1, hour: 0)))
    }

    // MARK: - Day Status

    func testDayStatusMarksCompletedTodayMissedAndUpcoming() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: [1, 4])
        let now = KhatmahFixture.date(dayNumber: 3)

        XCTAssertEqual(schedule.status(ofDay: 1, on: now), .completed)
        XCTAssertEqual(schedule.status(ofDay: 2, on: now), .missed)
        XCTAssertEqual(schedule.status(ofDay: 3, on: now), .today)
        XCTAssertEqual(schedule.status(ofDay: 4, on: now), .completed)
        XCTAssertEqual(schedule.status(ofDay: 5, on: now), .upcoming)
    }

    func testDaysListCoversEveryDayOfThePlanInOrder() {
        let schedule = KhatmahFixture.schedule(totalDays: 15)
        let days = schedule.days(on: KhatmahFixture.date(dayNumber: 2))

        XCTAssertEqual(days.count, 15)
        XCTAssertEqual(days.map(\.dayNumber), Array(1...15))
        XCTAssertEqual(days.first?.firstPage, KhatmahPageBounds.firstPage)
        XCTAssertEqual(days.last?.lastPage, KhatmahPageBounds.lastPage)
    }

    func testTodayResolvesToTheCurrentDayPortion() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)
        let today = schedule.today(on: KhatmahFixture.date(dayNumber: 4))

        XCTAssertEqual(today.dayNumber, 4)
        XCTAssertEqual(today.firstPage, 61)
        XCTAssertEqual(today.lastPage, 81)
        XCTAssertEqual(today.pageCount, 21)
        XCTAssertEqual(today.status, .today)
    }

    // MARK: - Progress

    func testActualAndRemainingPagesFollowTheCompletedDays() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: [1, 2, 3])

        XCTAssertEqual(schedule.actualPagesRead, 60)
        XCTAssertEqual(schedule.remainingPages, 544)
        XCTAssertEqual(schedule.completionFraction, 60.0 / 604.0, accuracy: 0.0001)
    }

    func testCompletedPlanLeavesNoRemainingPages() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: Set(1...30))

        XCTAssertTrue(schedule.plan.isCompleted)
        XCTAssertEqual(schedule.actualPagesRead, KhatmahPageBounds.totalPages)
        XCTAssertEqual(schedule.remainingPages, 0)
        XCTAssertEqual(schedule.completionFraction, 1, accuracy: 0.0001)
    }

    func testCompletionFractionNeverExceedsOne() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: Set(1...90))

        XCTAssertLessThanOrEqual(schedule.completionFraction, 1)
    }

    func testResumePageIsTheFirstPageOfTheNextUncompletedDay() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: [1, 2])

        XCTAssertEqual(schedule.nextUncompletedDayNumber, 3)
        XCTAssertEqual(schedule.resumePage, 41)
    }

    func testResumePageSkipsOverAMissedDay() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: [2, 3])

        XCTAssertEqual(schedule.nextUncompletedDayNumber, 1)
        XCTAssertEqual(schedule.resumePage, 1)
    }

    func testResumePageIsTheLastPageWhenThePlanIsComplete() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: Set(1...30))

        XCTAssertNil(schedule.nextUncompletedDayNumber)
        XCTAssertEqual(schedule.resumePage, KhatmahPageBounds.lastPage)
    }

    // MARK: - Drift

    func testDriftIsOnScheduleWhenEveryElapsedDayIsTicked() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: [1, 2, 3])
        let now = KhatmahFixture.date(dayNumber: 3)

        XCTAssertEqual(schedule.expectedPagesRead(by: now), 60)
        XCTAssertEqual(schedule.drift(on: now), .onSchedule)
    }

    func testDriftReportsPagesBehindWithoutMovingTheCompletionDate() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: [1])
        let now = KhatmahFixture.date(dayNumber: 3)

        XCTAssertEqual(schedule.drift(on: now), .behind(pages: 40))
        XCTAssertEqual(schedule.dayKey(ofDay: 30), "2026-11-30")
    }

    func testDriftReportsPagesAheadWhenReadingFaster() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: Set(1...5))
        let now = KhatmahFixture.date(dayNumber: 3)

        XCTAssertEqual(schedule.actualPagesRead, 101)
        XCTAssertEqual(schedule.drift(on: now), .ahead(pages: 41))
    }

    func testNothingIsExpectedBeforeThePlanStarts() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)
        let now = KhatmahFixture.date(dayNumber: -2)

        XCTAssertEqual(schedule.expectedPagesRead(by: now), 0)
        XCTAssertEqual(schedule.drift(on: now), .onSchedule)
    }

    func testExpectedPagesReadStopsAtTheFullQuranAfterTheLastDay() {
        let schedule = KhatmahFixture.schedule(totalDays: 30)
        let now = KhatmahFixture.date(dayNumber: 400)

        XCTAssertEqual(schedule.expectedPagesRead(by: now), KhatmahPageBounds.totalPages)
    }
}
