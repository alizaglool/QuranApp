//
//  PrayerMinuteOffsetTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import XCTest
@testable import QuranApp

final class PrayerMinuteOffsetTests: XCTestCase {

    private let day = PrayerNotificationFixture.day()

    private func preferences(_ offsets: [PrayerSlot: Int]) -> PrayerNotificationPreferences {
        PrayerNotificationFixture.preferences(minuteOffsets: offsets)
    }

    // MARK: - Clamping

    func testOffsetsClampToTheSupportedRange() {
        let range = PrayerNotificationPreferences.prayerMinuteOffsetRange

        XCTAssertEqual(PrayerNotificationPreferences.clampedMinuteOffset(999), range.upperBound)
        XCTAssertEqual(PrayerNotificationPreferences.clampedMinuteOffset(-999), range.lowerBound)
        XCTAssertEqual(PrayerNotificationPreferences.clampedMinuteOffset(0), 0)
        XCTAssertEqual(PrayerNotificationPreferences.clampedMinuteOffset(17), 17)
    }

    func testStoredOffsetBeyondTheRangeIsReadBackClamped() {
        let subject = preferences([.fajr: 400, .isha: -400])

        XCTAssertEqual(subject.minuteOffset(for: .fajr),
                       PrayerNotificationPreferences.prayerMinuteOffsetRange.upperBound)
        XCTAssertEqual(subject.minuteOffset(for: .isha),
                       PrayerNotificationPreferences.prayerMinuteOffsetRange.lowerBound)
    }

    func testSlotsOutsideTheAdjustableSetNeverReportAnOffset() {
        let unadjustable = PrayerSlot.allCases.filter { !PrayerSlot.adjustableSlots.contains($0) }
        let subject = preferences(Dictionary(uniqueKeysWithValues: unadjustable.map { ($0, 20) }))

        XCTAssertFalse(unadjustable.isEmpty)
        for slot in unadjustable {
            XCTAssertEqual(subject.minuteOffset(for: slot), 0)
        }
        XCTAssertTrue(subject.clampedPrayerMinuteOffsets.isEmpty)
    }

    func testClampedOffsetsDropTheUnadjustedSlots() {
        let subject = preferences([.fajr: 5, .dhuhr: 0, .asr: -3])

        XCTAssertEqual(subject.clampedPrayerMinuteOffsets, [.fajr: 5, .asr: -3])
    }

    // MARK: - Persistence

    func testOffsetsSurviveAStoreRoundTrip() {
        let defaults = PrayerNotificationFixture.defaults()
        let store = PrayerNotificationPreferencesStore(defaults: defaults)
        let saved = preferences([.fajr: -8, .maghrib: 12, .sunrise: 3])

        store.save(saved)

        XCTAssertEqual(store.restoredPreferences().prayerMinuteOffsets, saved.prayerMinuteOffsets)
    }

    func testStoredPayloadWithoutOffsetsDecodesWithNoAdjustments() throws {
        let legacy = """
        {
          "isPrayerNotificationEnabled": true,
          "enabledSlots": ["fajr", "dhuhr", "asr", "maghrib", "isha"],
          "prePrayerReminderLeadMinutes": 20
        }
        """

        let decoded = try JSONDecoder().decode(PrayerNotificationPreferences.self,
                                               from: Data(legacy.utf8))

        XCTAssertTrue(decoded.prayerMinuteOffsets.isEmpty)
        XCTAssertTrue(decoded.isPrayerNotificationEnabled)
        XCTAssertEqual(decoded.prePrayerReminderLeadMinutes, 20)
        XCTAssertEqual(decoded.enabledSlots, Set(PrayerSlot.obligatorySlots))
    }

    func testStoredPayloadWithoutTheSupplementalSlotsLeavesThemDisabled() throws {
        let legacy = """
        {
          "enabledSlots": ["fajr", "isha"]
        }
        """

        let decoded = try JSONDecoder().decode(PrayerNotificationPreferences.self,
                                               from: Data(legacy.utf8))

        XCTAssertEqual(decoded.enabledSlots, [.fajr, .isha])
        for slot in PrayerSlot.supplementalSlots {
            XCTAssertFalse(decoded.enabledSlots.contains(slot))
        }
    }

    func testSupplementalSlotsSurviveAStoreRoundTrip() {
        let defaults = PrayerNotificationFixture.defaults()
        let store = PrayerNotificationPreferencesStore(defaults: defaults)
        let slots: Set<PrayerSlot> = [.fajr, .sunrise, .lastThirdOfNight, .surahAlKahf]

        store.save(PrayerNotificationFixture.preferences(slots: slots))

        XCTAssertEqual(store.restoredPreferences().enabledSlots, slots)
    }

    // MARK: - Displayed Times

    func testDisplayedTimesShiftWithTheirOwnOffsetOnly() {
        let adjusted = day.applyingMinuteOffsets([.fajr: -10, .asr: 12])

        XCTAssertEqual(adjusted.fajr, day.fajr - 10)
        XCTAssertEqual(adjusted.asr, day.asr + 12)
        XCTAssertEqual(adjusted.dhuhr, day.dhuhr)
        XCTAssertEqual(adjusted.maghrib, day.maghrib)
        XCTAssertEqual(adjusted.isha, day.isha)
        XCTAssertEqual(adjusted.sunrise, day.sunrise)
    }

    func testEmptyOffsetsLeaveTheDayUntouched() {
        XCTAssertEqual(day.applyingMinuteOffsets([:]), day)
        XCTAssertEqual(day.applyingMinuteOffsets([.fajr: 0]), day)
    }

    func testDerivedTimesFollowTheAnchorsTheyAreBuiltFrom() {
        let adjusted = day.applyingMinuteOffsets([.sunrise: 10, .dhuhr: 10])

        XCTAssertEqual(adjusted.duha, day.duha + 10)
        XCTAssertEqual(adjusted.minutesSinceMidnight(of: .surahAlKahf), day.sunrise + 10)
        XCTAssertEqual(adjusted.minutesSinceMidnight(of: .jumuah), day.dhuhr + 10)
    }

    func testOffsetsNeverPushATimeOutsideTheDay() {
        let early = day.applyingMinuteOffsets([.fajr: -60])
        let late = day.applyingMinuteOffsets([.isha: 60])

        XCTAssertGreaterThanOrEqual(early.fajr, 0)
        XCTAssertLessThan(late.isha, DayPrayerTimes.minutesPerDay)
    }

    func testOffsetsOutsideTheRangeStillOnlyMoveTheTimeByTheClampedAmount() {
        let adjusted = day.applyingMinuteOffsets([.asr: 500])

        XCTAssertEqual(adjusted.asr,
                       day.asr + PrayerNotificationPreferences.prayerMinuteOffsetRange.upperBound)
    }
}
