//
//  KhatmahPlanStoreTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
import Core
@testable import QuranApp

@MainActor
final class KhatmahPlanStoreTests: XCTestCase {

    private var suiteName: String = ""
    private var defaults: UserDefaults = .standard
    private var store: KhatmahPlanStore = KhatmahPlanStore(defaults: .standard)

    override func setUp() {
        super.setUp()
        suiteName = UUID().uuidString
        defaults = PrayerNotificationFixture.defaults(suiteName)
        store = KhatmahPlanStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Creation

    func testNewStoreStartsEmpty() {
        XCTAssertNil(store.activePlan)
        XCTAssertFalse(store.hasActivePlan)
        XCTAssertNil(store.activeSchedule)
        XCTAssertTrue(store.archivedPlans.isEmpty)
        XCTAssertEqual(store.completedKhatmahCount, 0)
    }

    func testCreatePlanStoresTheRequestedPace() {
        let plan = store.createPlan(totalDays: 30, startDate: startDate)

        XCTAssertEqual(plan.totalDays, 30)
        XCTAssertEqual(plan.startPage, KhatmahPageBounds.firstPage)
        XCTAssertEqual(plan.endPage, KhatmahPageBounds.lastPage)
        XCTAssertEqual(store.activePlan, plan)
        XCTAssertTrue(store.hasActivePlan)
    }

    func testCreatePlanAnchorsTheStartDayKeyToTheStoreCalendar() {
        let plan = store.createPlan(totalDays: 30, startDate: startDate)

        XCTAssertEqual(plan.startDayKey, store.dayKey(for: startDate))
        XCTAssertEqual(plan.startDayKey.count, 10)
        XCTAssertEqual(plan.startDayKey.filter { $0 == "-" }.count, 2)
    }

    func testCreatePlanReplacesAnEarlierPlan() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)
        let second = store.createPlan(totalDays: 7, startDate: startDate)

        XCTAssertEqual(store.activePlan, second)
        XCTAssertEqual(store.activePlan?.totalDays, 7)
        XCTAssertTrue(store.archivedPlans.isEmpty)
    }

    func testCreatePlanAcceptsAPartialRange() {
        let plan = store.createPlan(totalDays: 10, startDate: startDate, startPage: 100, endPage: 200)

        XCTAssertEqual(plan.startPage, 100)
        XCTAssertEqual(plan.endPage, 200)
        XCTAssertEqual(store.activeSchedule?.firstPage(ofDay: 1), 100)
        XCTAssertEqual(store.activeSchedule?.lastPage(ofDay: 10), 200)
    }

    // MARK: - Persistence

    func testActivePlanSurvivesANewStoreOnTheSameSuite() {
        let plan = store.createPlan(totalDays: 30,
                                    startDate: startDate,
                                    reminder: KhatmahReminder(isEnabled: true, hour: 6, minute: 45))
        store.markDayCompleted(1)
        store.markDayCompleted(2)

        let reopened = KhatmahPlanStore(defaults: defaults)

        XCTAssertEqual(reopened.activePlan?.createdAt, plan.createdAt)
        XCTAssertEqual(reopened.activePlan?.startDayKey, plan.startDayKey)
        XCTAssertEqual(reopened.activePlan?.totalDays, 30)
        XCTAssertEqual(reopened.activePlan?.completedDayNumbers, [1, 2])
        XCTAssertEqual(reopened.activePlan?.reminder, KhatmahReminder(isEnabled: true, hour: 6, minute: 45))
    }

    func testArchiveAndCompletedCountSurviveANewStore() {
        _ = store.createPlan(totalDays: 2, startDate: startDate)
        store.markDayCompleted(1)
        store.markDayCompleted(2)
        store.archiveActivePlan()

        let reopened = KhatmahPlanStore(defaults: defaults)

        XCTAssertNil(reopened.activePlan)
        XCTAssertEqual(reopened.archivedPlans.count, 1)
        XCTAssertEqual(reopened.archivedPlans.first?.plan.completedDayNumbers, [1, 2])
        XCTAssertEqual(reopened.completedKhatmahCount, 1)
    }

    func testPlansAreIsolatedBetweenSuites() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        let otherSuite = UUID().uuidString
        let other = KhatmahPlanStore(defaults: PrayerNotificationFixture.defaults(otherSuite))

        XCTAssertNil(other.activePlan)
        UserDefaults().removePersistentDomain(forName: otherSuite)
    }

    // MARK: - Day Ticking

    func testToggleDayCompletionTicksAndUnticks() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        store.toggleDayCompletion(4)
        XCTAssertEqual(store.activePlan?.completedDayNumbers, [4])

        store.toggleDayCompletion(4)
        XCTAssertEqual(store.activePlan?.completedDayNumbers, [])
    }

    func testMarkDayCompletedIsIdempotent() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        store.markDayCompleted(3)
        store.markDayCompleted(3)

        XCTAssertEqual(store.activePlan?.completedDayNumbers, [3])
        XCTAssertEqual(store.activePlan?.completedDayCount, 1)
    }

    func testDayNumbersOutsideThePlanAreIgnored() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        store.markDayCompleted(0)
        store.markDayCompleted(31)
        store.toggleDayCompletion(-1)

        XCTAssertEqual(store.activePlan?.completedDayNumbers, [])
    }

    func testTickingEveryDayCompletesThePlan() {
        _ = store.createPlan(totalDays: 3, startDate: startDate)

        (1...3).forEach(store.markDayCompleted)

        XCTAssertEqual(store.activePlan?.isCompleted, true)
        XCTAssertEqual(store.activeSchedule?.remainingPages, 0)
    }

    // MARK: - Reminder

    func testUpdateReminderPersistsTheChosenTime() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        store.updateReminder(KhatmahReminder(isEnabled: true, hour: 5, minute: 30))

        XCTAssertEqual(store.activePlan?.reminder.hour, 5)
        XCTAssertEqual(store.activePlan?.reminder.minute, 30)
        XCTAssertEqual(KhatmahPlanStore(defaults: defaults).activePlan?.reminder.hour, 5)
    }

    func testUpdateReminderCanDisableTheReminder() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        store.updateReminder(KhatmahReminder(isEnabled: false, hour: 20, minute: 0))

        XCTAssertEqual(store.activePlan?.reminder.isEnabled, false)
    }

    func testUpdateReminderWithoutAPlanDoesNothing() {
        store.updateReminder(KhatmahReminder(isEnabled: true, hour: 5, minute: 30))

        XCTAssertNil(store.activePlan)
    }

    // MARK: - Archiving

    func testArchiveActivePlanMovesThePlanOutOfTheActiveSlot() {
        let plan = store.createPlan(totalDays: 30, startDate: startDate)

        store.archiveActivePlan()

        XCTAssertNil(store.activePlan)
        XCTAssertFalse(store.hasActivePlan)
        XCTAssertEqual(store.archivedPlans.count, 1)
        XCTAssertEqual(store.archivedPlans.first?.plan, plan)
    }

    func testCompletedCountOnlyRisesForAFinishedPlan() {
        _ = store.createPlan(totalDays: 3, startDate: startDate)
        store.markDayCompleted(1)
        store.archiveActivePlan()

        XCTAssertEqual(store.completedKhatmahCount, 0)

        _ = store.createPlan(totalDays: 3, startDate: startDate)
        (1...3).forEach(store.markDayCompleted)
        store.archiveActivePlan()

        XCTAssertEqual(store.completedKhatmahCount, 1)
        XCTAssertEqual(store.archivedPlans.count, 2)
    }

    func testMostRecentArchiveIsFirst() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)
        store.archiveActivePlan()
        _ = store.createPlan(totalDays: 7, startDate: startDate)
        store.archiveActivePlan()

        XCTAssertEqual(store.archivedPlans.map(\.plan.totalDays), [7, 30])
    }

    func testArchivingWithoutAPlanDoesNothing() {
        store.archiveActivePlan()

        XCTAssertTrue(store.archivedPlans.isEmpty)
        XCTAssertEqual(store.completedKhatmahCount, 0)
    }

    func testClearAllRemovesEveryStoredValue() {
        _ = store.createPlan(totalDays: 2, startDate: startDate)
        store.markDayCompleted(1)
        store.markDayCompleted(2)
        store.archiveActivePlan()
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        store.clearAll()

        XCTAssertNil(store.activePlan)
        XCTAssertTrue(store.archivedPlans.isEmpty)
        XCTAssertEqual(store.completedKhatmahCount, 0)
        XCTAssertNil(KhatmahPlanStore(defaults: defaults).activePlan)
        XCTAssertTrue(KhatmahPlanStore(defaults: defaults).archivedPlans.isEmpty)
    }

    // MARK: - Day Arithmetic

    func testDayKeyIsStableForEveryHourOfTheSameDay() {
        let calendar = store.dayCalendar
        let midnight = calendar.startOfDay(for: startDate)
        let keys = (0..<24).compactMap { hour in
            calendar.date(byAdding: .hour, value: hour, to: midnight).map(store.dayKey(for:))
        }

        XCTAssertEqual(Set(keys).count, 1)
        XCTAssertEqual(keys.first, store.dayKey(for: midnight))
    }

    func testDayCountIsInclusiveSoItReadsAsADuration() {
        let target = store.date(byAddingDays: 29, to: startDate)

        XCTAssertEqual(store.dayCount(from: startDate, to: target), 30)
        XCTAssertEqual(store.dayCount(from: startDate, to: startDate), 1)
    }

    func testDayCountMatchesThePlanDurationItDrives() {
        let target = store.date(byAddingDays: 6, to: startDate)
        let plan = store.createPlan(totalDays: store.dayCount(from: startDate, to: target),
                                    startDate: startDate)

        XCTAssertEqual(plan.totalDays, 7)
        XCTAssertEqual(store.activeSchedule?.dayKey(ofDay: plan.totalDays), store.dayKey(for: target))
    }

    func testDayCountIgnoresTheTimeOfDay() {
        let calendar = store.dayCalendar
        let earlyFirstDay = calendar.startOfDay(for: startDate)
        let lateNextDay = store.date(byAddingDays: 1, to: earlyFirstDay).addingTimeInterval(23 * 3_600)

        XCTAssertEqual(store.dayCount(from: earlyFirstDay, to: lateNextDay), 2)
    }

    func testActiveScheduleUsesTheStoreCalendar() {
        _ = store.createPlan(totalDays: 30, startDate: startDate)

        XCTAssertEqual(store.activeSchedule?.calendar.timeZone, store.dayCalendar.timeZone)
        XCTAssertEqual(store.activeSchedule?.dayKey(ofDay: 1), store.dayKey(for: startDate))
    }
}

// MARK: - Helpers

private extension KhatmahPlanStoreTests {

    var startDate: Date {
        KhatmahFixture.date(dayKey: KhatmahFixture.startDayKey, hour: 9)
    }
}
