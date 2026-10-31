//
//  PrayerNotificationManagerTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
import UserNotifications
@testable import QuranApp

@MainActor
final class PrayerNotificationManagerTests: XCTestCase {

    private let dayKey = PrayerNotificationFixture.mondayDayKey
    private let foreignIdentifier = "athkar_reminder.morning"

    private var now: Date {
        PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey, minutesSinceMidnight: 30)
    }

    private func manager(center: LocalNotificationCenterDouble,
                         defaults: UserDefaults,
                         preferences: PrayerNotificationPreferences) -> PrayerNotificationManager {
        PrayerNotificationManagerBuilder.manager(center: center,
                                                 defaults: defaults,
                                                 preferences: preferences,
                                                 now: now)
    }

    // MARK: - Scheduling

    func testAuthorizedRunSchedulesTheWholeWindow() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertEqual(center.ownedIdentifiers.count, 35)
        XCTAssertEqual(subject.scheduledRequestCount, 35)
        XCTAssertEqual(subject.scheduledWindowInDays, PrayerNotificationScheduleBuilder.maximumWindowInDays)
        XCTAssertEqual(subject.authorizationStatus, .authorized)
    }

    func testReschedulingTwiceProducesNoDuplicates() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(isReminderEnabled: true))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let first = center.ownedIdentifiers.sorted()
        center.resetLog()
        await subject.reschedule(day: PrayerNotificationFixture.day())
        let second = center.ownedIdentifiers.sorted()

        XCTAssertEqual(first, second)
        XCTAssertEqual(Set(second).count, second.count)
        XCTAssertEqual(center.addedDrafts.count, second.count)
        XCTAssertEqual(Set(center.addedDrafts.map(\.identifier)).count, center.addedDrafts.count)
        XCTAssertEqual(center.removedIdentifiers.sorted(), first)
    }

    func testDisablingOnePrayerRemovesOnlyItsRequests() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let defaults = PrayerNotificationFixture.defaults()
        let allPrayers = manager(center: center,
                                 defaults: defaults,
                                 preferences: PrayerNotificationFixture.preferences())

        await allPrayers.reschedule(day: PrayerNotificationFixture.day())
        let before = Set(center.ownedIdentifiers)
        center.seedForeignRequest(identifier: foreignIdentifier)

        let withoutAsr = manager(center: center,
                                 defaults: defaults,
                                 preferences: PrayerNotificationFixture.preferences(
                                     slots: Set(PrayerSlot.obligatorySlots).subtracting([.asr])
                                 ))
        await withoutAsr.reschedule(day: PrayerNotificationFixture.day())
        let after = Set(center.ownedIdentifiers)

        XCTAssertEqual(before.count, 35)
        XCTAssertEqual(after.count, 28)
        XCTAssertTrue(after.isSubset(of: before))
        XCTAssertTrue(before.subtracting(after).allSatisfy { PrayerNotificationIdentifier.slot(of: $0) == .asr })
        XCTAssertFalse(after.contains { PrayerNotificationIdentifier.slot(of: $0) == .asr })
        XCTAssertEqual(center.foreignIdentifiers, [foreignIdentifier])
    }

    func testForeignRequestsAreNeverRemoved() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        center.seedForeignRequest(identifier: foreignIdentifier)
        center.seedForeignRequest(identifier: "quran_khatma.daily")
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertEqual(center.foreignIdentifiers.sorted(), ["athkar_reminder.morning", "quran_khatma.daily"])
        XCTAssertTrue(center.removedIdentifiers.allSatisfy(PrayerNotificationIdentifier.isOwned))
    }

    func testStaleOwnedRequestsAreClearedBeforeTheNewWindowIsAdded() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        center.seedOwnedRequest(dayKey: "2026-01-01", slot: .fajr, kind: .adhan)
        center.seedForeignRequest(identifier: foreignIdentifier)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertFalse(center.pendingIdentifiers.contains("prayer_notification.2026-01-01.fajr.adhan"))
        XCTAssertEqual(center.foreignIdentifiers, [foreignIdentifier])
    }

    func testMissingDayClearsOwnedRequestsAndZeroesTheCounters() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())
        center.seedForeignRequest(identifier: foreignIdentifier)
        await subject.reschedule(day: nil)

        XCTAssertTrue(center.ownedIdentifiers.isEmpty)
        XCTAssertEqual(center.foreignIdentifiers, [foreignIdentifier])
        XCTAssertEqual(subject.scheduledRequestCount, 0)
        XCTAssertEqual(subject.scheduledWindowInDays, 0)
    }

    func testDisabledMasterToggleSchedulesNothing() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(isEnabled: false))

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertTrue(center.ownedIdentifiers.isEmpty)
        XCTAssertEqual(subject.scheduledRequestCount, 0)
    }

    // MARK: - Authorization

    func testDeniedAuthorizationSchedulesNothingAndReportsDenied() async {
        let center = LocalNotificationCenterDouble(status: .denied)
        center.seedForeignRequest(identifier: foreignIdentifier)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertTrue(center.addedDrafts.isEmpty)
        XCTAssertTrue(center.ownedIdentifiers.isEmpty)
        XCTAssertEqual(center.foreignIdentifiers, [foreignIdentifier])
        XCTAssertEqual(subject.authorizationStatus, .denied)
        XCTAssertTrue(subject.authorizationStatus.isDenied)
        XCTAssertFalse(subject.authorizationStatus.allowsScheduling)
        XCTAssertEqual(subject.scheduledRequestCount, 0)
    }

    func testNotDeterminedAuthorizationSchedulesNothing() async {
        let center = LocalNotificationCenterDouble(status: .notDetermined)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertTrue(center.addedDrafts.isEmpty)
        XCTAssertEqual(subject.authorizationStatus, .notDetermined)
    }

    func testProvisionalAuthorizationStillSchedules() async {
        let center = LocalNotificationCenterDouble(status: .provisional)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertEqual(center.ownedIdentifiers.count, 35)
    }

    func testRefreshAuthorizationStatusMirrorsTheCenter() async {
        let center = LocalNotificationCenterDouble(status: .denied)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.refreshAuthorizationStatus()

        XCTAssertEqual(subject.authorizationStatus, .denied)
        XCTAssertEqual(center.authorizationRequestCount, 0)
    }

    func testAuthorizationIsRequestedOnlyWhileUndecided() async {
        let center = LocalNotificationCenterDouble(status: .notDetermined, statusAfterRequest: .denied)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.requestAuthorization()
        XCTAssertEqual(center.authorizationRequestCount, 1)
        XCTAssertEqual(subject.authorizationStatus, .denied)

        await subject.requestAuthorization()
        XCTAssertEqual(center.authorizationRequestCount, 1)
        XCTAssertEqual(subject.authorizationStatus, .denied)
    }

    // MARK: - Location Change

    func testSelectedLocationChangeTriggersReschedule() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        center.seedOwnedRequest(dayKey: "2026-01-01", slot: .fajr, kind: .adhan)
        center.seedForeignRequest(identifier: foreignIdentifier)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        subject.handleSelectedLocationChange()
        await PrayerNotificationWait.until { center.statusReadCount > 0 }

        XCTAssertGreaterThan(center.statusReadCount, 0)
        XCTAssertFalse(center.pendingIdentifiers.contains("prayer_notification.2026-01-01.fajr.adhan"))
        XCTAssertEqual(center.foreignIdentifiers, [foreignIdentifier])
    }

    func testRescheduleEntryPointReplacesThePreviousWindow() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        subject.reschedule(for: PrayerNotificationFixture.day())
        await PrayerNotificationWait.until { subject.scheduledRequestCount == 35 }

        XCTAssertEqual(center.ownedIdentifiers.count, 35)
        XCTAssertEqual(subject.scheduledRequestCount, 35)
    }

    // MARK: - Drafts

    func testAdhanDraftCarriesTheSlotNameAndFiresWithoutACustomSound() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(slots: [.fajr]))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let draft = center.addedDrafts.first { PrayerNotificationIdentifier.kind(of: $0.identifier) == .adhan }

        XCTAssertEqual(draft?.title, PrayerSlot.fajr.localizedName)
        XCTAssertFalse(draft?.title.isEmpty ?? true)
        XCTAssertFalse(draft?.body.isEmpty ?? true)
        XCTAssertNil(draft?.soundFileName)
        XCTAssertEqual(draft?.dateComponents.hour, PrayerNotificationFixture.fajrMinutes / 60)
    }

    func testReminderDraftMentionsTheLeadMinutes() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(slots: [.fajr],
                                                                                 isReminderEnabled: true,
                                                                                 leadMinutes: 25))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let draft = center.addedDrafts.first { PrayerNotificationIdentifier.kind(of: $0.identifier) == .reminder }

        XCTAssertNotNil(draft)
        XCTAssertFalse(draft?.body.isEmpty ?? true)
        XCTAssertEqual(draft?.dateComponents.minute, (PrayerNotificationFixture.fajrMinutes - 25) % 60)
    }

    // MARK: - Alert Style

    func testShortAdhanToneFallsBackToTheStandardToneWhileTheAssetIsMissing() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(slots: [.fajr],
                                                                                 alertStyle: .shortAdhanTone))

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertFalse(subject.isShortAdhanToneAvailable)
        XCTAssertEqual(subject.effectiveAlertStyle, .standardTone)
        XCTAssertTrue(center.addedDrafts.allSatisfy { $0.soundFileName == nil })
    }

    func testShortAdhanToneFileNameTargetsABundledCafAsset() {
        XCTAssertEqual(PrayerNotificationSoundCatalog.shortAdhanToneFileName, "adhan_short.caf")
        XCTAssertEqual(PrayerNotificationSoundCatalog.shortAdhanToneExtension, "caf")
        XCTAssertEqual(PrayerNotificationSoundCatalog.shortAdhanToneMaximumDuration, 30)
    }

    // MARK: - Preferences

    func testUpdatePreferencesClampsAndPersistsTheReminderLead() {
        let defaults = PrayerNotificationFixture.defaults()
        let subject = manager(center: LocalNotificationCenterDouble(status: .denied),
                              defaults: defaults,
                              preferences: PrayerNotificationFixture.preferences())

        subject.updatePreferences { $0.prePrayerReminderLeadMinutes = 500 }

        XCTAssertEqual(subject.preferences.prePrayerReminderLeadMinutes,
                       PrayerNotificationPreferences.reminderLeadMinutesRange.upperBound)
        XCTAssertEqual(PrayerNotificationPreferencesStore(defaults: defaults)
            .restoredPreferences()
            .prePrayerReminderLeadMinutes,
                       PrayerNotificationPreferences.reminderLeadMinutesRange.upperBound)
    }

    func testUpdatePreferencesPersistsSlotChanges() {
        let defaults = PrayerNotificationFixture.defaults()
        let subject = manager(center: LocalNotificationCenterDouble(status: .denied),
                              defaults: defaults,
                              preferences: PrayerNotificationFixture.preferences())

        subject.updatePreferences { $0.enabledSlots.insert(.duha) }

        XCTAssertTrue(subject.preferences.enabledSlots.contains(.duha))
        XCTAssertTrue(PrayerNotificationPreferencesStore(defaults: defaults)
            .restoredPreferences()
            .enabledSlots
            .contains(.duha))
    }

    // MARK: - Foreground Presentation

    func testOwnedAdhanKeepsTheSystemSoundWhileTheInAppAudioIsUnavailable() {
        let subject = manager(center: LocalNotificationCenterDouble(status: .authorized),
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(isInAppAdhanEnabled: true))
        let identifier = PrayerNotificationIdentifier.identifier(dayKey: dayKey, slot: .fajr, kind: .adhan)

        XCTAssertFalse(subject.isFullAdhanAudioAvailable)
        XCTAssertEqual(subject.presentationOptions(forIdentifier: identifier), [.banner, .list, .sound])
    }

    func testReminderAndForeignNotificationsNeverTriggerTheInAppAdhan() {
        let subject = manager(center: LocalNotificationCenterDouble(status: .authorized),
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(isInAppAdhanEnabled: true))
        let reminder = PrayerNotificationIdentifier.identifier(dayKey: dayKey, slot: .fajr, kind: .reminder)

        XCTAssertEqual(subject.presentationOptions(forIdentifier: reminder), [.banner, .list, .sound])
        XCTAssertEqual(subject.presentationOptions(forIdentifier: foreignIdentifier), [.banner, .list, .sound])
    }
}
