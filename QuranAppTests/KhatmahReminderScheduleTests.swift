//
//  KhatmahReminderScheduleTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
import Core
@testable import QuranApp

final class KhatmahReminderScheduleTests: XCTestCase {

    // MARK: - Identifiers

    func testIdentifierIsThePrefixedDayKey() {
        XCTAssertEqual(KhatmahNotificationIdentifier.identifier(dayKey: "2026-11-02"),
                       "khatmah_reminder.2026-11-02")
    }

    func testOwnedPrefixEndsWithASeparator() {
        XCTAssertEqual(KhatmahNotificationIdentifier.ownedIdentifierPrefix, "khatmah_reminder.")
    }

    func testOwnershipNeverOverlapsWithPrayerNotifications() {
        let khatmah = KhatmahNotificationIdentifier.identifier(dayKey: "2026-11-02")
        let prayer = PrayerNotificationIdentifier.identifier(dayKey: "2026-11-02", slot: .fajr, kind: .adhan)

        XCTAssertTrue(KhatmahNotificationIdentifier.isOwned(khatmah))
        XCTAssertFalse(KhatmahNotificationIdentifier.isOwned(prayer))
        XCTAssertTrue(PrayerNotificationIdentifier.isOwned(prayer))
        XCTAssertFalse(PrayerNotificationIdentifier.isOwned(khatmah))
    }

    func testDayKeyRoundTripsThroughTheIdentifier() {
        let identifier = KhatmahNotificationIdentifier.identifier(dayKey: "2026-11-02")

        XCTAssertEqual(KhatmahNotificationIdentifier.dayKey(of: identifier), "2026-11-02")
    }

    func testDayKeyIsNilForForeignOrMalformedIdentifiers() {
        let prayer = PrayerNotificationIdentifier.identifier(dayKey: "2026-11-02", slot: .fajr, kind: .adhan)

        XCTAssertNil(KhatmahNotificationIdentifier.dayKey(of: prayer))
        XCTAssertNil(KhatmahNotificationIdentifier.dayKey(of: "khatmah_reminder"))
        XCTAssertNil(KhatmahNotificationIdentifier.dayKey(of: "khatmah_reminder.2026-11-02.extra"))
        XCTAssertNil(KhatmahNotificationIdentifier.dayKey(of: ""))
    }

    // MARK: - Window

    func testWindowIsSevenDaysForALongPlan() {
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 30))

        XCTAssertEqual(entries.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
        XCTAssertEqual(entries.map(\.dayNumber), [1, 2, 3, 4, 5, 6, 7])
    }

    func testWindowStopsAtThePlanEnd() {
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 3))

        XCTAssertEqual(entries.count, 3)
        XCTAssertEqual(entries.map(\.dayNumber), [1, 2, 3])
    }

    func testWindowStartsFromTodayNotFromTheFirstDay() {
        let entries = builder(onDayNumber: 10, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 30))

        XCTAssertEqual(entries.map(\.dayNumber), [10, 11, 12, 13, 14, 15, 16])
    }

    func testWindowStartsAtDayOneBeforeThePlanBegins() {
        let entries = builder(onDayNumber: -2, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 30))

        XCTAssertEqual(entries.first?.dayNumber, 1)
        XCTAssertEqual(entries.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
    }

    func testNothingIsScheduledAfterThePlanEnds() {
        let entries = builder(onDayNumber: 10, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 3))

        XCTAssertTrue(entries.isEmpty)
    }

    func testWindowNeverExceedsThePendingBudget() {
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 604))

        XCTAssertLessThanOrEqual(entries.count, KhatmahReminderScheduleBuilder.pendingRequestLimit)
    }

    // MARK: - Skipping

    func testTodayIsSkippedOnceItsReminderTimeHasPassed() {
        let entries = builder(onDayNumber: 1, hour: 21).entries(for: KhatmahFixture.schedule(totalDays: 30))

        XCTAssertEqual(entries.map(\.dayNumber), [2, 3, 4, 5, 6, 7])
    }

    func testTodayIsKeptWhileItsReminderTimeIsStillAhead() {
        let entries = builder(onDayNumber: 1, hour: 19).entries(for: KhatmahFixture.schedule(totalDays: 30))

        XCTAssertEqual(entries.first?.dayNumber, 1)
    }

    func testCompletedDaysAreSkipped() {
        let schedule = KhatmahFixture.schedule(totalDays: 30, completedDayNumbers: [1, 2])
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: schedule)

        XCTAssertEqual(entries.map(\.dayNumber), [3, 4, 5, 6, 7])
    }

    func testADisabledReminderSchedulesNothing() {
        let schedule = KhatmahFixture.schedule(totalDays: 30,
                                               reminder: KhatmahReminder(isEnabled: false, hour: 20, minute: 0))

        XCTAssertTrue(builder(onDayNumber: 1, hour: 9).entries(for: schedule).isEmpty)
    }

    func testAFullyCompletedPlanSchedulesNothing() {
        let schedule = KhatmahFixture.schedule(totalDays: 3, completedDayNumbers: [1, 2, 3])

        XCTAssertTrue(builder(onDayNumber: 1, hour: 9).entries(for: schedule).isEmpty)
    }

    // MARK: - Entry Content

    func testEntryCarriesTheDayPortionAndIdentifier() throws {
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 30))
        let first = try XCTUnwrap(entries.first)

        XCTAssertEqual(first.dayKey, KhatmahFixture.startDayKey)
        XCTAssertEqual(first.identifier, "khatmah_reminder.2026-11-01")
        XCTAssertEqual(first.firstPage, 1)
        XCTAssertEqual(first.lastPage, 20)
    }

    func testEveryEntryFiresAtTheChosenReminderTime() {
        let reminder = KhatmahReminder(isEnabled: true, hour: 6, minute: 45)
        let schedule = KhatmahFixture.schedule(totalDays: 30, reminder: reminder)
        let entries = builder(onDayNumber: 1, hour: 5).entries(for: schedule)
        let calendar = KhatmahFixture.calendar

        XCTAssertEqual(entries.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
        entries.forEach { entry in
            XCTAssertEqual(entry.dateComponents.hour, 6, entry.identifier)
            XCTAssertEqual(entry.dateComponents.minute, 45, entry.identifier)
            XCTAssertEqual(calendar.component(.hour, from: entry.fireDate), 6, entry.identifier)
        }
    }

    func testDateComponentsResolveBackToTheFireDate() {
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 30))
        let calendar = KhatmahFixture.calendar

        entries.forEach { entry in
            XCTAssertEqual(calendar.date(from: entry.dateComponents), entry.fireDate, entry.identifier)
        }
    }

    func testDateComponentsCarryThePlanTimeZone() {
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 30))

        entries.forEach { entry in
            XCTAssertEqual(entry.dateComponents.timeZone, KhatmahFixture.calendar.timeZone, entry.identifier)
        }
    }

    func testIdentifiersAreUniquePerDay() {
        let entries = builder(onDayNumber: 1, hour: 9).entries(for: KhatmahFixture.schedule(totalDays: 30))

        XCTAssertEqual(Set(entries.map(\.identifier)).count, entries.count)
        XCTAssertTrue(entries.allSatisfy { KhatmahNotificationIdentifier.isOwned($0.identifier) })
    }

    func testFireTimeStaysAtTheLocalHourAcrossADaylightSavingChange() {
        let calendar = KhatmahFixture.calendar(timeZoneIdentifier: "Europe/London")
        let schedule = KhatmahFixture.schedule(totalDays: 30,
                                               startDayKey: "2026-10-23",
                                               calendar: calendar)
        let now = KhatmahFixture.date(dayKey: "2026-10-23", hour: 9, calendar: calendar)
        let entries = KhatmahReminderScheduleBuilder(clock: LocalNotificationClockDouble(currentDate: now))
            .entries(for: schedule)

        XCTAssertEqual(entries.map(\.dayKey),
                       ["2026-10-23", "2026-10-24", "2026-10-25", "2026-10-26",
                        "2026-10-27", "2026-10-28", "2026-10-29"])
        entries.forEach { entry in
            XCTAssertEqual(calendar.component(.hour, from: entry.fireDate), 20, entry.dayKey)
            XCTAssertEqual(calendar.date(from: entry.dateComponents), entry.fireDate, entry.dayKey)
        }
    }
}

// MARK: - Helpers

private extension KhatmahReminderScheduleTests {

    func builder(onDayNumber dayNumber: Int, hour: Int) -> KhatmahReminderScheduleBuilder {
        let now = KhatmahFixture.date(dayNumber: dayNumber, hour: hour)
        return KhatmahReminderScheduleBuilder(clock: LocalNotificationClockDouble(currentDate: now))
    }
}

// MARK: - Scheduler

@MainActor
final class KhatmahReminderSchedulerTests: XCTestCase {

    private var suiteName: String = ""
    private var defaults: UserDefaults = .standard
    private var store: KhatmahPlanStore = KhatmahPlanStore(defaults: .standard)
    private var center: LocalNotificationCenterDouble = LocalNotificationCenterDouble()
    private var now: Date = Date()

    override func setUp() {
        super.setUp()
        suiteName = UUID().uuidString
        defaults = PrayerNotificationFixture.defaults(suiteName)
        store = KhatmahPlanStore(defaults: defaults)
        center = LocalNotificationCenterDouble()
        now = store.dayCalendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Scheduling

    func testRescheduleAddsOneRequestPerUpcomingDay() async {
        store.createPlan(totalDays: 30, startDate: now)

        await scheduler().reschedule()

        XCTAssertEqual(center.addedDrafts.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
        XCTAssertTrue(center.addedDrafts.allSatisfy { KhatmahNotificationIdentifier.isOwned($0.identifier) })
        XCTAssertEqual(Set(center.addedDrafts.map(\.identifier)).count, center.addedDrafts.count)
    }

    func testScheduledRequestCountMatchesWhatWasAdded() async {
        store.createPlan(totalDays: 30, startDate: now)
        let scheduler = scheduler()

        await scheduler.reschedule()

        XCTAssertEqual(scheduler.scheduledRequestCount, center.addedDrafts.count)
    }

    func testDraftsCoverTheNextSevenDayKeys() async {
        store.createPlan(totalDays: 30, startDate: now)
        let expected = (1...KhatmahReminderScheduleBuilder.maximumWindowInDays).map { dayNumber in
            KhatmahNotificationIdentifier.identifier(
                dayKey: store.dayKey(for: store.date(byAddingDays: dayNumber - 1, to: now))
            )
        }

        await scheduler().reschedule()

        XCTAssertEqual(center.addedDrafts.map(\.identifier), expected)
    }

    func testDraftsCarryALocalizedTitleAndBody() async throws {
        store.createPlan(totalDays: 30, startDate: now)

        await scheduler().reschedule()
        let first = try XCTUnwrap(center.addedDrafts.first)

        XCTAssertFalse(first.title.isEmpty)
        XCTAssertFalse(first.body.isEmpty)
        XCTAssertFalse(first.title.contains("khatmah"))
        XCTAssertFalse(first.body.contains("khatmah"))
        XCTAssertNotNil(first.dateComponents.timeZone)
    }

    func testReschedulingTwiceDoesNotDuplicateRequests() async {
        store.createPlan(totalDays: 30, startDate: now)
        let scheduler = scheduler()

        await scheduler.reschedule()
        center.resetLog()
        await scheduler.reschedule()

        XCTAssertEqual(ownedPendingIdentifiers.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
        XCTAssertEqual(Set(ownedPendingIdentifiers).count, ownedPendingIdentifiers.count)
    }

    func testStaleRemindersFromAnEarlierPlanAreReplaced() async {
        center.seedForeignRequest(identifier: KhatmahNotificationIdentifier.identifier(dayKey: "2026-01-01"))
        store.createPlan(totalDays: 30, startDate: now)

        await scheduler().reschedule()

        XCTAssertFalse(center.pendingIdentifiers.contains("khatmah_reminder.2026-01-01"))
        XCTAssertTrue(center.removedIdentifiers.contains("khatmah_reminder.2026-01-01"))
    }

    func testRescheduleFromStoreReachesTheCenter() async {
        store.createPlan(totalDays: 30, startDate: now)
        let scheduler = scheduler()

        scheduler.rescheduleFromStore()
        await PrayerNotificationWait.until { !self.center.addedDrafts.isEmpty }

        XCTAssertEqual(center.addedDrafts.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
        XCTAssertEqual(scheduler.scheduledRequestCount, center.addedDrafts.count)
    }

    // MARK: - Isolation From Prayer Notifications

    func testPrayerRequestsSurviveAKhatmahReschedule() async {
        center.seedOwnedRequest(dayKey: "2026-11-01", slot: .fajr, kind: .adhan)
        center.seedOwnedRequest(dayKey: "2026-11-01", slot: .maghrib, kind: .reminder)
        store.createPlan(totalDays: 30, startDate: now)

        await scheduler().reschedule()

        XCTAssertEqual(center.ownedIdentifiers.count, 2)
        XCTAssertTrue(center.removedIdentifiers.allSatisfy(KhatmahNotificationIdentifier.isOwned))
    }

    func testPrayerRequestsSurviveADeniedKhatmahReschedule() async {
        center.status = .denied
        center.seedOwnedRequest(dayKey: "2026-11-01", slot: .fajr, kind: .adhan)
        center.seedForeignRequest(identifier: KhatmahNotificationIdentifier.identifier(dayKey: "2026-11-01"))

        await scheduler().reschedule()

        XCTAssertEqual(center.ownedIdentifiers.count, 1)
        XCTAssertTrue(ownedPendingIdentifiers.isEmpty)
    }

    func testPendingReminderIdentifiersReportsOnlyKhatmahRequests() async {
        center.seedOwnedRequest(dayKey: "2026-11-01", slot: .fajr, kind: .adhan)
        store.createPlan(totalDays: 30, startDate: now)
        let scheduler = scheduler()

        await scheduler.reschedule()
        let pending = await scheduler.pendingReminderIdentifiers()

        XCTAssertEqual(pending.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
        XCTAssertTrue(pending.allSatisfy(KhatmahNotificationIdentifier.isOwned))
    }

    // MARK: - Nothing To Schedule

    func testDeniedAuthorizationSchedulesNothing() async {
        center.status = .denied
        store.createPlan(totalDays: 30, startDate: now)
        let scheduler = scheduler()

        await scheduler.reschedule()

        XCTAssertTrue(center.addedDrafts.isEmpty)
        XCTAssertEqual(scheduler.scheduledRequestCount, 0)
        XCTAssertEqual(scheduler.authorizationStatus, .denied)
    }

    func testAbsentPlanRemovesOwnedRequests() async {
        center.seedForeignRequest(identifier: KhatmahNotificationIdentifier.identifier(dayKey: "2026-11-01"))
        let scheduler = scheduler()

        await scheduler.reschedule()

        XCTAssertTrue(ownedPendingIdentifiers.isEmpty)
        XCTAssertEqual(scheduler.scheduledRequestCount, 0)
    }

    func testDisabledReminderClearsOwnedRequests() async {
        store.createPlan(totalDays: 30, startDate: now)
        let scheduler = scheduler()
        await scheduler.reschedule()

        store.updateReminder(KhatmahReminder(isEnabled: false, hour: 20, minute: 0))
        center.resetLog()
        await scheduler.reschedule()

        XCTAssertTrue(center.addedDrafts.isEmpty)
        XCTAssertTrue(ownedPendingIdentifiers.isEmpty)
        XCTAssertEqual(scheduler.scheduledRequestCount, 0)
    }

    func testProvisionalAuthorizationStillSchedules() async {
        center.status = .provisional
        store.createPlan(totalDays: 30, startDate: now)

        await scheduler().reschedule()

        XCTAssertEqual(center.addedDrafts.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)
    }

    // MARK: - Authorization

    func testAuthorizationIsOnlyRequestedWhileUndetermined() async {
        center.status = .notDetermined
        center.statusAfterRequest = .authorized
        store.createPlan(totalDays: 30, startDate: now)
        let scheduler = scheduler()

        await scheduler.requestAuthorization()

        XCTAssertEqual(center.authorizationRequestCount, 1)
        XCTAssertEqual(scheduler.authorizationStatus, .authorized)
        XCTAssertEqual(center.addedDrafts.count, KhatmahReminderScheduleBuilder.maximumWindowInDays)

        await scheduler.requestAuthorization()

        XCTAssertEqual(center.authorizationRequestCount, 1)
    }

    func testRefreshAuthorizationStatusReadsTheCenter() async {
        center.status = .denied
        let scheduler = scheduler()

        await scheduler.refreshAuthorizationStatus()

        XCTAssertEqual(scheduler.authorizationStatus, .denied)
    }
}

// MARK: - Helpers

private extension KhatmahReminderSchedulerTests {

    var ownedPendingIdentifiers: [String] {
        center.pendingIdentifiers.filter(KhatmahNotificationIdentifier.isOwned)
    }

    func scheduler() -> KhatmahReminderScheduler {
        KhatmahReminderScheduler(center: center,
                                 store: store,
                                 clock: LocalNotificationClockDouble(currentDate: now))
    }
}
