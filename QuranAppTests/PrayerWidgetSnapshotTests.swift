//
//  PrayerWidgetSnapshotTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import XCTest
import Core
@testable import QuranApp

// MARK: - Fixtures

enum PrayerWidgetFixture {

    static let slotMinutes: [Int] = [300, 380, 710, 910, 1055, 1145]

    static let labels = PrayerWidgetLabels(nextPrayerTitle: "Next Prayer",
                                           remainingTitle: "Remaining",
                                           scheduleTitle: "Prayer Schedule",
                                           unavailableMessage: "Unavailable",
                                           nowTitle: "Now",
                                           hourMinuteRemainingFormat: "%@h %@m",
                                           minuteRemainingFormat: "%@m",
                                           nextPrayerGalleryTitle: "Next Prayer",
                                           nextPrayerGalleryDescription: "Countdown",
                                           scheduleGalleryTitle: "Prayer Schedule",
                                           scheduleGalleryDescription: "Timings",
                                           dateGalleryTitle: "Hijri Date",
                                           dateGalleryDescription: "Today")

    static func snapshot(dayKeys: [String] = [PrayerNotificationFixture.mondayDayKey,
                                              PrayerNotificationFixture.tuesdayDayKey]) -> PrayerWidgetSnapshot {
        let days = dayKeys.enumerated().map { offset, dayKey in
            PrayerWidgetDay(dayKey: dayKey,
                            dayOffset: offset,
                            startDate: PrayerNotificationFixture.date(dayKey: dayKey, minutesSinceMidnight: 0),
                            hijriDateText: "١٢ جمادى الأولى ١٤٤٨ هـ",
                            gregorianDateText: dayKey,
                            slots: slots(dayKey: dayKey))
        }
        return PrayerWidgetSnapshot(languageCode: "en",
                                    isRightToLeft: false,
                                    locationTitle: "Riyadh",
                                    days: days,
                                    labels: labels)
    }

    static func slots(dayKey: String) -> [PrayerWidgetSlot] {
        slotMinutes.map { minutes in
            PrayerWidgetSlot(id: "\(dayKey)-\(minutes)",
                             title: "Prayer \(minutes)",
                             iconName: "sun.max",
                             timeText: "\(minutes)",
                             date: PrayerNotificationFixture.date(dayKey: dayKey, minutesSinceMidnight: minutes),
                             isObligatory: true)
        }
    }

    static func date(dayKey: String = PrayerNotificationFixture.mondayDayKey, minutes: Int) -> Date {
        PrayerNotificationFixture.date(dayKey: dayKey, minutesSinceMidnight: minutes)
    }
}

// MARK: - Queries

final class PrayerWidgetSnapshotQueryTests: XCTestCase {

    func testSlotsFlattenEveryProjectedDay() {
        XCTAssertEqual(PrayerWidgetFixture.snapshot().slots.count, 12)
    }

    func testSnapshotWithoutDaysIsEmpty() {
        XCTAssertTrue(PrayerWidgetSnapshot.placeholder.isEmpty)
    }

    func testNextSlotExcludesTheSlotAtTheCurrentInstant() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let next = snapshot.nextSlot(at: PrayerWidgetFixture.date(minutes: 710))

        XCTAssertEqual(next?.date, PrayerWidgetFixture.date(minutes: 910))
    }

    func testCurrentSlotIncludesTheSlotAtTheCurrentInstant() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let current = snapshot.currentSlot(at: PrayerWidgetFixture.date(minutes: 710))

        XCTAssertEqual(current?.date, PrayerWidgetFixture.date(minutes: 710))
    }

    func testCurrentSlotIsMissingBeforeTheFirstSlotOfTheWindow() {
        let snapshot = PrayerWidgetFixture.snapshot()

        XCTAssertNil(snapshot.currentSlot(at: PrayerWidgetFixture.date(minutes: 10)))
    }

    func testNextSlotRollsOverToTheFollowingDay() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let next = snapshot.nextSlot(at: PrayerWidgetFixture.date(minutes: 1200))

        XCTAssertEqual(next?.date, PrayerWidgetFixture.date(dayKey: PrayerNotificationFixture.tuesdayDayKey,
                                                            minutes: 300))
    }

    func testDayFollowsTheClockPastMidnight() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let afterMidnight = PrayerWidgetFixture.date(dayKey: PrayerNotificationFixture.tuesdayDayKey, minutes: 30)

        XCTAssertEqual(snapshot.day(at: afterMidnight)?.dayKey, PrayerNotificationFixture.tuesdayDayKey)
    }

    func testDayBeforeTheWindowFallsBackToTheFirstDay() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let beforeWindow = PrayerWidgetFixture.date(minutes: 0).addingTimeInterval(-3600)

        XCTAssertEqual(snapshot.day(at: beforeWindow)?.dayKey, PrayerNotificationFixture.mondayDayKey)
    }

    func testScheduleSlotsBelongToTheDayInProgress() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let afterMidnight = PrayerWidgetFixture.date(dayKey: PrayerNotificationFixture.tuesdayDayKey, minutes: 30)
        let identifiers = snapshot.scheduleSlots(at: afterMidnight).map { $0.id }

        XCTAssertEqual(identifiers.count, 6)
        XCTAssertTrue(identifiers.allSatisfy { $0.hasPrefix(PrayerNotificationFixture.tuesdayDayKey) })
    }

    func testScheduleSlotsAreEmptyWithoutAnyDay() {
        XCTAssertTrue(PrayerWidgetSnapshot.placeholder.scheduleSlots(at: Date()).isEmpty)
    }

    func testSlotIdentifiersAreUniqueAcrossProjectedDays() {
        let identifiers = PrayerWidgetFixture.snapshot().slots.map { $0.id }

        XCTAssertEqual(Set(identifiers).count, identifiers.count)
    }
}

// MARK: - Remaining text

final class PrayerWidgetRemainingTextTests: XCTestCase {

    func testRemainingTextUsesTheHourAndMinuteFormatBeyondAnHour() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let text = snapshot.remainingText(at: PrayerWidgetFixture.date(minutes: 760))

        XCTAssertEqual(text, "2h 30m")
    }

    func testRemainingTextUsesTheMinuteFormatBelowAnHour() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let text = snapshot.remainingText(at: PrayerWidgetFixture.date(minutes: 865))

        XCTAssertEqual(text, "45m")
    }

    func testRemainingTextIsTheNowTitleInsideTheFinalMinute() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let text = snapshot.remainingText(at: PrayerWidgetFixture.date(minutes: 910).addingTimeInterval(-30))

        XCTAssertEqual(text, "Now")
    }

    func testRemainingTextIsEmptyWithoutAnUpcomingSlot() {
        let snapshot = PrayerWidgetFixture.snapshot()
        let afterWindow = PrayerWidgetFixture.date(dayKey: PrayerNotificationFixture.tuesdayDayKey, minutes: 1400)

        XCTAssertEqual(snapshot.remainingText(at: afterWindow), "")
    }
}

// MARK: - Timeline

final class PrayerWidgetTimelineTests: XCTestCase {

    func testTimelineStartsAtTheRequestedDate() {
        let now = PrayerWidgetFixture.date(minutes: 600)

        XCTAssertEqual(PrayerWidgetFixture.snapshot().timelineDates(from: now).first, now)
    }

    func testTimelineDatesAscendStrictly() {
        let dates = PrayerWidgetFixture.snapshot().timelineDates(from: PrayerWidgetFixture.date(minutes: 600))

        XCTAssertEqual(dates, dates.sorted())
        XCTAssertEqual(Set(dates).count, dates.count)
    }

    func testTimelineDatesStayAtLeastOneSecondApart() {
        let dates = PrayerWidgetFixture.snapshot().timelineDates(from: PrayerWidgetFixture.date(minutes: 600))
        let gaps = zip(dates.dropFirst(), dates).map { $0.timeIntervalSince($1) }

        XCTAssertTrue(gaps.allSatisfy { $0 >= 1 })
    }

    func testTimelineIncludesEverySlotBoundaryInsideTheWindow() {
        let now = PrayerWidgetFixture.date(minutes: 600)
        let snapshot = PrayerWidgetFixture.snapshot()
        let dates = Set(snapshot.timelineDates(from: now))
        let horizon = now.addingTimeInterval(PrayerWidgetSnapshot.coarseWindow)
        let expected = snapshot.slots.map { $0.date }.filter { $0 > now && $0 <= horizon }

        XCTAssertFalse(expected.isEmpty)
        XCTAssertTrue(expected.allSatisfy { dates.contains($0) })
    }

    func testTimelineNeverReachesBeyondTheCoarseWindow() {
        let now = PrayerWidgetFixture.date(minutes: 600)
        let dates = PrayerWidgetFixture.snapshot().timelineDates(from: now)

        XCTAssertNotNil(dates.last)
        XCTAssertLessThanOrEqual(dates.last ?? now,
                                 now.addingTimeInterval(PrayerWidgetSnapshot.coarseWindow))
    }

    func testTimelineKeepsEveryMinuteInsideTheFineGrainedWindow() {
        let now = PrayerWidgetFixture.date(minutes: 600)
        let dates = PrayerWidgetFixture.snapshot().timelineDates(from: now)
        let fineGrained = dates.filter { $0 <= now.addingTimeInterval(PrayerWidgetSnapshot.fineGrainedWindow) }

        XCTAssertGreaterThanOrEqual(fineGrained.count, 120)
    }
}

// MARK: - Shared store

final class PrayerWidgetSharedStoreTests: XCTestCase {

    private let suiteName = "PrayerWidgetSharedStoreTests"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testStoreReturnsNothingBeforeAnyWrite() {
        XCTAssertNil(PrayerWidgetSharedStore.loadSnapshot(from: defaults))
    }

    func testStoreRoundTripsASnapshot() {
        let snapshot = PrayerWidgetFixture.snapshot()
        PrayerWidgetSharedStore.save(snapshot, to: defaults)

        XCTAssertEqual(PrayerWidgetSharedStore.loadSnapshot(from: defaults), snapshot)
    }

    func testStoreClearRemovesTheSnapshot() {
        PrayerWidgetSharedStore.save(PrayerWidgetFixture.snapshot(), to: defaults)
        PrayerWidgetSharedStore.clear(in: defaults)

        XCTAssertNil(PrayerWidgetSharedStore.loadSnapshot(from: defaults))
    }

    func testStoreIgnoresDataThatIsNotASnapshot() {
        defaults.set(Data("not a snapshot".utf8), forKey: PrayerWidgetSharedStore.snapshotKey)

        XCTAssertNil(PrayerWidgetSharedStore.loadSnapshot(from: defaults))
    }
}

// MARK: - Snapshot writer

@MainActor
final class PrayerWidgetSnapshotWriterTests: XCTestCase {

    private let suiteName = "PrayerWidgetSnapshotWriterTests"
    private var defaults: UserDefaults!
    private var writer: PrayerWidgetSnapshotWriter!

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = UserDefaults(suiteName: suiteName)
        writer = PrayerWidgetSnapshotWriter(defaults: defaults)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        writer = nil
        defaults = nil
        super.tearDown()
    }

    func testWriterStoresASnapshotForTheGivenDay() {
        writer.refresh(day: PrayerNotificationFixture.day())

        XCTAssertNotNil(PrayerWidgetSharedStore.loadSnapshot(from: defaults))
    }

    func testWriterProjectsTwoDays() {
        writer.refresh(day: PrayerNotificationFixture.day())
        let stored = PrayerWidgetSharedStore.loadSnapshot(from: defaults)

        XCTAssertEqual(stored?.days.count, 2)
        XCTAssertEqual(stored?.days.first?.dayKey, PrayerNotificationFixture.mondayDayKey)
        XCTAssertEqual(stored?.days.last?.dayKey, PrayerNotificationFixture.tuesdayDayKey)
    }

    func testWriterProjectsTomorrowFromTodayMinuteValues() {
        writer.refresh(day: PrayerNotificationFixture.day())
        let tomorrow = PrayerWidgetSharedStore.loadSnapshot(from: defaults)?.days.last

        XCTAssertEqual(tomorrow?.slots.first?.date,
                       PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.tuesdayDayKey,
                                                      minutesSinceMidnight: PrayerNotificationFixture.fajrMinutes))
    }

    func testWriterStoresSixSlotsPerDay() {
        writer.refresh(day: PrayerNotificationFixture.day())
        let stored = PrayerWidgetSharedStore.loadSnapshot(from: defaults)

        XCTAssertTrue(stored?.days.allSatisfy { $0.slots.count == 6 } ?? false)
    }

    func testWriterSlotDatesAscendWithinEachDay() {
        writer.refresh(day: PrayerNotificationFixture.day())
        let days = PrayerWidgetSharedStore.loadSnapshot(from: defaults)?.days ?? []

        XCTAssertFalse(days.isEmpty)
        for day in days {
            let dates = day.slots.map { $0.date }
            XCTAssertEqual(dates, dates.sorted())
        }
    }

    func testWriterResolvesEveryCountdownLabel() {
        writer.refresh(day: PrayerNotificationFixture.day())
        let labels = PrayerWidgetSharedStore.loadSnapshot(from: defaults)?.labels

        XCTAssertFalse(labels?.nowTitle.isEmpty ?? true)
        XCTAssertFalse(labels?.nextPrayerTitle.isEmpty ?? true)
        XCTAssertFalse(labels?.scheduleTitle.isEmpty ?? true)
        XCTAssertFalse(labels?.unavailableMessage.isEmpty ?? true)
    }

    func testWriterKeepsTheStoredSnapshotWhenTheDayIsUnchanged() {
        writer.refresh(day: PrayerNotificationFixture.day())
        let first = PrayerWidgetSharedStore.loadSnapshot(from: defaults)
        writer.refresh(day: PrayerNotificationFixture.day())

        XCTAssertEqual(PrayerWidgetSharedStore.loadSnapshot(from: defaults), first)
    }

    func testWriterReplacesTheSnapshotWhenTheDayChanges() {
        writer.refresh(day: PrayerNotificationFixture.day())
        writer.refresh(day: PrayerNotificationFixture.day(dayKey: PrayerNotificationFixture.fridayDayKey))
        let stored = PrayerWidgetSharedStore.loadSnapshot(from: defaults)

        XCTAssertEqual(stored?.days.first?.dayKey, PrayerNotificationFixture.fridayDayKey)
    }

    func testWriterClearsTheSnapshotWhenTheDayIsMissing() {
        writer.refresh(day: PrayerNotificationFixture.day())
        writer.refresh(day: nil)

        XCTAssertNil(PrayerWidgetSharedStore.loadSnapshot(from: defaults))
    }

    func testWriterLeavesAnEmptyStoreUntouchedWhenTheDayIsMissing() {
        writer.refresh(day: nil)

        XCTAssertNil(PrayerWidgetSharedStore.loadSnapshot(from: defaults))
    }
}
