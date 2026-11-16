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
                         preferences: PrayerNotificationPreferences,
                         soundCatalog: PrayerNotificationSoundCatalog = PrayerNotificationFixture
                             .soundCatalogWithoutAudio()) -> PrayerNotificationManager {
        PrayerNotificationManagerBuilder.manager(center: center,
                                                 defaults: defaults,
                                                 preferences: preferences,
                                                 now: now,
                                                 soundCatalog: soundCatalog)
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

    func testSoundCatalogDeclaresTheSupportedAdhanAssetFormats() {
        XCTAssertEqual(PrayerNotificationSoundCatalog.shortAdhanToneExtension, "caf")
        XCTAssertEqual(PrayerNotificationSoundCatalog.fullAdhanAudioExtension, "m4a")
        XCTAssertEqual(PrayerNotificationSoundCatalog.shortAdhanToneMaximumDuration, 30)
    }

    // MARK: - Bundled Recordings

    func testBundledRecordingIdentifiersAreUniqueAndIncludeTheDefault() {
        let identifiers = AdhanRecording.bundled.map(\.id)

        XCTAssertFalse(identifiers.isEmpty)
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
        XCTAssertNotNil(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))
    }

    func testEveryBundledRecordingShipsBothAudioAssets() {
        let catalog = PrayerNotificationFixture.soundCatalogWithBundledAudio()

        XCTAssertEqual(catalog.availableRecordings.count, AdhanRecording.bundled.count)

        for recording in AdhanRecording.bundled {
            XCTAssertNotNil(catalog.shortAdhanToneURL(for: recording), recording.id)
            XCTAssertNotNil(catalog.fullAdhanAudioURL(for: recording), recording.id)
        }
    }

    func testEveryBundledNotificationToneStaysUnderTheSystemSoundLimit() throws {
        let catalog = PrayerNotificationFixture.soundCatalogWithBundledAudio()

        for recording in AdhanRecording.bundled {
            let url = try XCTUnwrap(catalog.shortAdhanToneURL(for: recording), recording.id)
            let measured = try XCTUnwrap(catalog.measuredDuration(ofFileAt: url), recording.id)

            XCTAssertLessThan(measured,
                              PrayerNotificationSoundCatalog.shortAdhanToneMaximumDuration,
                              recording.id)
            XCTAssertEqual(measured, recording.notificationToneDuration, accuracy: 1, recording.id)
            XCTAssertEqual(catalog.notificationSoundFileName(for: recording),
                           "\(recording.notificationToneResource).caf",
                           recording.id)
        }
    }

    func testEveryBundledFullAdhanRunsLongerThanItsNotificationTone() throws {
        let catalog = PrayerNotificationFixture.soundCatalogWithBundledAudio()

        for recording in AdhanRecording.bundled {
            let url = try XCTUnwrap(catalog.fullAdhanAudioURL(for: recording), recording.id)
            let measured = try XCTUnwrap(catalog.measuredDuration(ofFileAt: url), recording.id)

            XCTAssertGreaterThan(measured,
                                 PrayerNotificationSoundCatalog.shortAdhanToneMaximumDuration,
                                 recording.id)
            XCTAssertEqual(measured, recording.fullAdhanDuration, accuracy: 1, recording.id)
        }
    }

    func testSelectingARecordingPersistsItAndDrivesTheScheduledSound() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let defaults = PrayerNotificationFixture.defaults()
        let subject = manager(center: center,
                              defaults: defaults,
                              preferences: PrayerNotificationFixture.preferences(slots: [.fajr],
                                                                                 alertStyle: .shortAdhanTone),
                              soundCatalog: PrayerNotificationFixture.soundCatalogWithBundledAudio())
        let recording = AdhanRecording.bundled[1]

        subject.selectRecording(recording)
        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertEqual(subject.preferences.adhanRecordingIdentifier, recording.id)
        XCTAssertEqual(PrayerNotificationPreferencesStore(defaults: defaults)
            .restoredPreferences()
            .adhanRecordingIdentifier,
                       recording.id)
        XCTAssertEqual(subject.selectedRecording, recording)
        XCTAssertTrue(subject.isShortAdhanToneAvailable)
        XCTAssertEqual(subject.effectiveAlertStyle, .shortAdhanTone)
        XCTAssertFalse(center.addedDrafts.isEmpty)
        XCTAssertTrue(center.addedDrafts.allSatisfy {
            $0.soundFileName == "\(recording.notificationToneResource).caf"
        })
    }

    func testAnUnknownRecordingIdentifierFallsBackToTheDefaultRecording() {
        let subject = manager(center: LocalNotificationCenterDouble(status: .authorized),
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture
                                  .preferences(recordingIdentifier: "voice_that_is_not_bundled"),
                              soundCatalog: PrayerNotificationFixture.soundCatalogWithBundledAudio())

        XCTAssertEqual(subject.selectedRecording?.id, AdhanRecording.defaultIdentifier)
    }

    func testAMissingAudioBundleLeavesNoSelectableRecording() {
        let subject = manager(center: LocalNotificationCenterDouble(status: .authorized),
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        XCTAssertTrue(subject.availableRecordings.isEmpty)
        XCTAssertNil(subject.selectedRecording)
        XCTAssertFalse(subject.isShortAdhanToneAvailable)
        XCTAssertFalse(subject.isFullAdhanAudioAvailable)
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

    // MARK: - Test Notification

    func testTestNotificationIsScheduledOutsideThePrayerSchedule() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        let outcome = await subject.sendTestNotification()

        XCTAssertEqual(outcome, .scheduled)
        XCTAssertFalse(PrayerNotificationIdentifier.isOwned(PrayerNotificationManager.testRequestIdentifier))
        XCTAssertEqual(center.foreignIdentifiers, [PrayerNotificationManager.testRequestIdentifier])
        XCTAssertTrue(center.ownedIdentifiers.isEmpty)
    }

    func testTestNotificationFiresFromAShortDelayWhilePrayerDraftsStayOnTheCalendar() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let prayerDrafts = center.addedDrafts
        center.resetLog()
        _ = await subject.sendTestNotification()

        XCTAssertEqual(PrayerNotificationManager.testNotificationDelayInSeconds, 5)
        XCTAssertEqual(center.addedDrafts.count, 1)
        XCTAssertEqual(center.addedDrafts.first?.secondsFromNow, 5)
        XCTAssertFalse(prayerDrafts.isEmpty)
        XCTAssertTrue(prayerDrafts.allSatisfy { $0.secondsFromNow == nil })
    }

    func testTestNotificationLeavesTheRealScheduleUntouched() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let scheduled = center.ownedIdentifiers.sorted()
        let requestCount = subject.scheduledRequestCount
        let windowInDays = subject.scheduledWindowInDays
        center.resetLog()
        _ = await subject.sendTestNotification()

        XCTAssertEqual(center.ownedIdentifiers.sorted(), scheduled)
        XCTAssertEqual(subject.scheduledRequestCount, requestCount)
        XCTAssertEqual(subject.scheduledWindowInDays, windowInDays)
        XCTAssertTrue(center.removedIdentifiers.isEmpty)
    }

    func testTestNotificationLeavesStoredPreferencesUntouched() async {
        let defaults = PrayerNotificationFixture.defaults()
        let subject = manager(center: LocalNotificationCenterDouble(status: .authorized),
                              defaults: defaults,
                              preferences: PrayerNotificationFixture.preferences(isReminderEnabled: true))
        let store = PrayerNotificationPreferencesStore(defaults: defaults)
        let storedBefore = store.restoredPreferences()
        let inMemoryBefore = subject.preferences

        _ = await subject.sendTestNotification()

        XCTAssertEqual(store.restoredPreferences(), storedBefore)
        XCTAssertEqual(subject.preferences, inMemoryBefore)
    }

    func testTestNotificationCarriesTheTestCopyRatherThanAPrayerName() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        _ = await subject.sendTestNotification()
        let draft = center.addedDrafts.first

        XCTAssertEqual(draft?.title, AppLocalizedKeys.prayerNotificationsTestTitle.value)
        XCTAssertEqual(draft?.body, AppLocalizedKeys.prayerNotificationsTestBody.value)
        XCTAssertFalse(PrayerSlot.allCases.map(\.localizedName).contains(draft?.title ?? ""))
    }

    func testTestNotificationFallsBackToTheSystemSoundWhileTheShortAdhanToneIsMissing() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(alertStyle: .shortAdhanTone))

        _ = await subject.sendTestNotification()

        XCTAssertFalse(subject.isShortAdhanToneAvailable)
        XCTAssertEqual(subject.effectiveAlertStyle, .standardTone)
        XCTAssertNil(center.addedDrafts.first?.soundFileName)
    }

    func testDeniedAuthorizationReportsTheDenialWithoutScheduling() async {
        let center = LocalNotificationCenterDouble(status: .denied)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        let outcome = await subject.sendTestNotification()

        XCTAssertEqual(outcome, .authorizationDenied)
        XCTAssertTrue(center.addedDrafts.isEmpty)
        XCTAssertTrue(center.pendingIdentifiers.isEmpty)
        XCTAssertEqual(subject.authorizationStatus, .denied)
    }

    func testNotDeterminedAuthorizationReportsTheMissingPermissionWithoutScheduling() async {
        let center = LocalNotificationCenterDouble(status: .notDetermined)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        let outcome = await subject.sendTestNotification()

        XCTAssertEqual(outcome, .authorizationNotRequested)
        XCTAssertTrue(center.addedDrafts.isEmpty)
        XCTAssertEqual(center.authorizationRequestCount, 0)
        XCTAssertEqual(subject.authorizationStatus, .notDetermined)
    }

    func testRepeatedTestNotificationsNeverAccumulatePendingRequests() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences())

        _ = await subject.sendTestNotification()
        _ = await subject.sendTestNotification()
        _ = await subject.sendTestNotification()

        XCTAssertEqual(center.addedDrafts.count, 3)
        XCTAssertEqual(center.pendingIdentifiers, [PrayerNotificationManager.testRequestIdentifier])
    }

    func testTestNotificationPresentsABannerWithItsSoundInTheForeground() {
        let subject = manager(center: LocalNotificationCenterDouble(status: .authorized),
                              defaults: PrayerNotificationFixture.defaults(),
                              preferences: PrayerNotificationFixture.preferences(isInAppAdhanEnabled: true))

        XCTAssertEqual(subject.presentationOptions(forIdentifier: PrayerNotificationManager.testRequestIdentifier),
                       [.banner, .list, .sound])
    }
}
