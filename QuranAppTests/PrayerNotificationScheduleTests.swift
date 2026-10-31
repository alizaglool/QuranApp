//
//  PrayerNotificationScheduleTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
@testable import QuranApp

final class PrayerNotificationScheduleTests: XCTestCase {

    private let dayKey = PrayerNotificationFixture.mondayDayKey

    private func builder(atMinutes minutes: Int = 30,
                         dayKey: String = PrayerNotificationFixture.mondayDayKey) -> PrayerNotificationScheduleBuilder {
        let now = PrayerNotificationFixture.date(dayKey: dayKey, minutesSinceMidnight: minutes)
        return PrayerNotificationScheduleBuilder(clock: LocalNotificationClockDouble(currentDate: now))
    }

    private func minutes(of entry: PrayerNotificationScheduleEntry) -> Int {
        DayPrayerTimes.minutesSinceMidnight(of: entry.fireDate, calendar: PrayerNotificationFixture.calendar)
    }

    // MARK: - Fixture Sanity

    func testFixtureWeekdaysMatchTheGregorianCalendar() {
        XCTAssertEqual(PrayerNotificationFixture.weekday(ofDayKey: PrayerNotificationFixture.mondayDayKey), 2)
        XCTAssertEqual(PrayerNotificationFixture.weekday(ofDayKey: PrayerNotificationFixture.tuesdayDayKey), 3)
        XCTAssertEqual(PrayerNotificationFixture.weekday(ofDayKey: PrayerNotificationFixture.fridayDayKey), 6)
        XCTAssertEqual(PrayerNotificationFixture.weekday(ofDayKey: PrayerNotificationFixture.nextFridayDayKey), 6)
    }

    // MARK: - Identifiers

    func testIdentifierIsBuiltFromDayKeySlotAndKind() {
        let identifier = PrayerNotificationIdentifier.identifier(dayKey: dayKey, slot: .fajr, kind: .adhan)

        XCTAssertEqual(identifier, "prayer_notification.2026-11-02.fajr.adhan")
        XCTAssertTrue(PrayerNotificationIdentifier.isOwned(identifier))
        XCTAssertEqual(PrayerNotificationIdentifier.slot(of: identifier), .fajr)
        XCTAssertEqual(PrayerNotificationIdentifier.kind(of: identifier), .adhan)
    }

    func testForeignIdentifierIsNotOwned() {
        XCTAssertFalse(PrayerNotificationIdentifier.isOwned("athkar_reminder.morning"))
        XCTAssertFalse(PrayerNotificationIdentifier.isOwned("prayer_notification_other"))
        XCTAssertNil(PrayerNotificationIdentifier.slot(of: "athkar_reminder.morning"))
        XCTAssertNil(PrayerNotificationIdentifier.kind(of: "athkar_reminder.morning"))
    }

    func testIdentifiersAreStableAcrossTwoIdenticalRuns() {
        let day = PrayerNotificationFixture.day()
        let preferences = PrayerNotificationFixture.preferences(slots: Set(PrayerSlot.allCases),
                                                                isReminderEnabled: true)

        let first = builder().entries(for: day, preferences: preferences).map(\.identifier)
        let second = builder().entries(for: day, preferences: preferences).map(\.identifier)

        XCTAssertFalse(first.isEmpty)
        XCTAssertEqual(first, second)
        XCTAssertEqual(Set(first).count, first.count)
        for identifier in first {
            XCTAssertEqual(identifier.split(separator: ".").count, 4)
            XCTAssertNotNil(PrayerNotificationIdentifier.slot(of: identifier))
            XCTAssertNotNil(PrayerNotificationIdentifier.kind(of: identifier))
        }
    }

    // MARK: - Gating

    func testMasterToggleOffSchedulesNothing() {
        let entries = builder().entries(for: PrayerNotificationFixture.day(),
                                        preferences: PrayerNotificationFixture.preferences(isEnabled: false))

        XCTAssertTrue(entries.isEmpty)
    }

    func testEmptySlotSelectionSchedulesNothing() {
        let entries = builder().entries(for: PrayerNotificationFixture.day(),
                                        preferences: PrayerNotificationFixture.preferences(slots: []))

        XCTAssertTrue(entries.isEmpty)
    }

    func testEntriesAlreadyPastAreSkipped() {
        let entries = builder(atMinutes: 720).entries(for: PrayerNotificationFixture.day(),
                                                      preferences: PrayerNotificationFixture.preferences())
        let firstDay = entries.filter { $0.dayKey == dayKey }

        XCTAssertEqual(firstDay.map(\.slot), [.asr, .maghrib, .isha])
        XCTAssertEqual(entries.count, 3 + 5 * 6)
    }

    // MARK: - Rolling Window

    func testObligatorySetFillsTheSevenDayWindow() {
        let entries = builder().entries(for: PrayerNotificationFixture.day(),
                                        preferences: PrayerNotificationFixture.preferences())

        XCTAssertEqual(entries.count, 35)
        XCTAssertEqual(Set(entries.map(\.dayKey)).count, PrayerNotificationScheduleBuilder.maximumWindowInDays)
    }

    func testWorstCaseEnabledSetNeverExceedsThePendingLimit() {
        let preferences = PrayerNotificationFixture.preferences(slots: Set(PrayerSlot.allCases),
                                                                isReminderEnabled: true)
        let entries = builder().entries(for: PrayerNotificationFixture.day(), preferences: preferences)

        XCTAssertLessThanOrEqual(entries.count, PrayerNotificationScheduleBuilder.pendingRequestLimit)
        XCTAssertEqual(entries.count, 60)
        XCTAssertEqual(Set(entries.map(\.dayKey)).count, 5)
    }

    func testWindowNeverExceedsThePendingLimitForAnyEnabledCombination() {
        let day = PrayerNotificationFixture.day()
        var combinations: [Set<PrayerSlot>] = [Set(PrayerSlot.allCases), Set(PrayerSlot.obligatorySlots)]
        for slot in PrayerSlot.allCases {
            combinations.append([slot])
            combinations.append(Set(PrayerSlot.obligatorySlots).union([slot]))
        }

        for slots in combinations {
            for isReminderEnabled in [false, true] {
                let preferences = PrayerNotificationFixture.preferences(slots: slots,
                                                                        isReminderEnabled: isReminderEnabled)
                let entries = builder().entries(for: day, preferences: preferences)

                XCTAssertLessThanOrEqual(entries.count,
                                         PrayerNotificationScheduleBuilder.pendingRequestLimit,
                                         "slots: \(slots.map(\.rawValue).sorted())")
                XCTAssertLessThanOrEqual(Set(entries.map(\.dayKey)).count,
                                         PrayerNotificationScheduleBuilder.maximumWindowInDays)
            }
        }
    }

    func testEntriesAreSortedByFireDate() {
        let preferences = PrayerNotificationFixture.preferences(slots: Set(PrayerSlot.allCases),
                                                                isReminderEnabled: true)
        let entries = builder().entries(for: PrayerNotificationFixture.day(), preferences: preferences)
        let fireDates = entries.map(\.fireDate)

        XCTAssertEqual(fireDates, fireDates.sorted())
    }

    // MARK: - Reminder Offset

    func testPrePrayerReminderLandsAtTheConfiguredOffset() {
        let preferences = PrayerNotificationFixture.preferences(slots: [.fajr],
                                                                isReminderEnabled: true,
                                                                leadMinutes: 20)
        let entries = builder().entries(for: PrayerNotificationFixture.day(), preferences: preferences)
            .filter { $0.dayKey == dayKey }

        XCTAssertEqual(entries.count, 2)
        let reminder = entries.first { $0.kind == .reminder }
        let adhan = entries.first { $0.kind == .adhan }
        XCTAssertEqual(reminder?.leadMinutes, 20)
        XCTAssertEqual(adhan?.leadMinutes, 0)
        XCTAssertEqual(reminder.map(minutes(of:)), PrayerNotificationFixture.fajrMinutes - 20)
        XCTAssertEqual(adhan.map(minutes(of:)), PrayerNotificationFixture.fajrMinutes)
        XCTAssertEqual(reminder?.fireDate,
                       PrayerNotificationFixture.date(dayKey: dayKey,
                                                      minutesSinceMidnight: PrayerNotificationFixture.fajrMinutes - 20))
    }

    func testReminderIsNotScheduledWhenDisabled() {
        let entries = builder().entries(for: PrayerNotificationFixture.day(),
                                        preferences: PrayerNotificationFixture.preferences(slots: [.fajr]))

        XCTAssertTrue(entries.allSatisfy { $0.kind == .adhan })
    }

    // MARK: - Duha

    func testDuhaIsDerivedFromSunriseAndDhuhr() {
        let day = PrayerNotificationFixture.day()
        let expected = PrayerNotificationFixture.sunriseMinutes
            + (PrayerNotificationFixture.dhuhrMinutes - PrayerNotificationFixture.sunriseMinutes) / 4

        XCTAssertEqual(day.duha, expected)
        XCTAssertEqual(day.duha, 462)
        XCTAssertEqual(day.minutesSinceMidnight(of: .duha), expected)

        let entries = builder().entries(for: day,
                                        preferences: PrayerNotificationFixture.preferences(slots: [.duha]))
            .filter { $0.dayKey == dayKey }

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first.map(minutes(of:)), expected)
    }

    func testDuhaIsNotScheduledUnlessEnabled() {
        let entries = builder().entries(for: PrayerNotificationFixture.day(),
                                        preferences: PrayerNotificationFixture.preferences())

        XCTAssertFalse(entries.contains { $0.slot == .duha })
    }

    // MARK: - Jumuah

    func testJumuahOnlyEverLandsOnFriday() {
        let preferences = PrayerNotificationFixture.preferences(slots: [.jumuah], isReminderEnabled: true)
        let entries = builder().entries(for: PrayerNotificationFixture.day(), preferences: preferences)

        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(Set(entries.map(\.dayKey)), [PrayerNotificationFixture.nextFridayDayKey])
        for entry in entries {
            XCTAssertEqual(entry.slot, .jumuah)
            XCTAssertEqual(PrayerNotificationFixture.weekday(ofDayKey: entry.dayKey), 6)
        }
    }

    func testJumuahSupersedesDhuhrOnFridayOnly() {
        let preferences = PrayerNotificationFixture.preferences(slots: [.dhuhr, .jumuah])
        let entries = builder().entries(for: PrayerNotificationFixture.day(), preferences: preferences)
        let friday = entries.filter { $0.dayKey == PrayerNotificationFixture.nextFridayDayKey }
        let monday = entries.filter { $0.dayKey == dayKey }

        XCTAssertEqual(entries.count, 7)
        XCTAssertEqual(friday.map(\.slot), [.jumuah])
        XCTAssertEqual(monday.map(\.slot), [.dhuhr])
        XCTAssertEqual(friday.first.map(minutes(of:)), PrayerNotificationFixture.dhuhrMinutes)
    }

    func testDhuhrStillFiresOnFridayWhenJumuahIsDisabled() {
        let entries = builder().entries(for: PrayerNotificationFixture.day(),
                                        preferences: PrayerNotificationFixture.preferences(slots: [.dhuhr]))
        let friday = entries.filter { $0.dayKey == PrayerNotificationFixture.nextFridayDayKey }

        XCTAssertEqual(entries.count, 7)
        XCTAssertEqual(friday.map(\.slot), [.dhuhr])
    }

    // MARK: - Trigger Components

    func testDateComponentsResolveBackToTheFireDateInTheDayZone() {
        let entries = builder().entries(for: PrayerNotificationFixture.day(),
                                        preferences: PrayerNotificationFixture.preferences(slots: [.maghrib]))
        guard let entry = entries.first else { return XCTFail("expected one entry") }

        XCTAssertEqual(entry.dateComponents.timeZone, PrayerNotificationFixture.calendar.timeZone)
        XCTAssertEqual(entry.dateComponents.hour, PrayerNotificationFixture.maghribMinutes / 60)
        XCTAssertEqual(entry.dateComponents.minute, PrayerNotificationFixture.maghribMinutes % 60)
        XCTAssertNil(entry.dateComponents.second)
        XCTAssertEqual(Calendar(identifier: .gregorian).date(from: entry.dateComponents), entry.fireDate)
    }

    // MARK: - Preferences

    func testReminderLeadMinutesAreClampedToTheSupportedRange() {
        XCTAssertEqual(PrayerNotificationFixture.preferences(leadMinutes: 0).clampedReminderLeadMinutes,
                       PrayerNotificationPreferences.reminderLeadMinutesRange.lowerBound)
        XCTAssertEqual(PrayerNotificationFixture.preferences(leadMinutes: 999).clampedReminderLeadMinutes,
                       PrayerNotificationPreferences.reminderLeadMinutesRange.upperBound)
        XCTAssertEqual(PrayerNotificationFixture.preferences(leadMinutes: 25).clampedReminderLeadMinutes, 25)
    }

    func testPreferencesRoundTripThroughUserDefaults() {
        let defaults = PrayerNotificationFixture.defaults()
        let store = PrayerNotificationPreferencesStore(defaults: defaults)
        let preferences = PrayerNotificationFixture.preferences(slots: [.fajr, .jumuah],
                                                                alertStyle: .shortAdhanTone,
                                                                isReminderEnabled: true,
                                                                leadMinutes: 30,
                                                                isInAppAdhanEnabled: true,
                                                                method: .moonsightingCommittee,
                                                                school: .hanafi)

        store.save(preferences)

        XCTAssertEqual(PrayerNotificationPreferencesStore(defaults: defaults).restoredPreferences(), preferences)
    }

    func testUnwrittenPreferencesFallBackToTheStandardSet() {
        let store = PrayerNotificationPreferencesStore(defaults: PrayerNotificationFixture.defaults())

        XCTAssertEqual(store.restoredPreferences(), .standard)
        XCTAssertFalse(PrayerNotificationPreferences.standard.isPrayerNotificationEnabled)
        XCTAssertEqual(PrayerNotificationPreferences.standard.enabledSlots, Set(PrayerSlot.obligatorySlots))
    }

    func testPreferencesDecodeFromAPartialPayload() throws {
        let payload = Data(#"{"isPrayerNotificationEnabled":true}"#.utf8)
        let decoded = try JSONDecoder().decode(PrayerNotificationPreferences.self, from: payload)

        XCTAssertTrue(decoded.isPrayerNotificationEnabled)
        XCTAssertEqual(decoded.enabledSlots, PrayerNotificationPreferences.standard.enabledSlots)
        XCTAssertEqual(decoded.calculationMethod, .default)
        XCTAssertEqual(decoded.jurisprudenceSchool, .default)
    }
}
