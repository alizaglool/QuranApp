//
//  PrayerTimesAdhanControlTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 01/11/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class PrayerTimesAdhanControlTests: XCTestCase {

    private var retainedCoordinator: AnyObject?
    private var retainedNotificationManager: PrayerNotificationManager?

    override func tearDown() {
        retainedCoordinator = nil
        retainedNotificationManager = nil
        super.tearDown()
    }

    // MARK: - Availability

    func testBundledAdhanAudioMakesTheControlAvailable() {
        let viewModel = makeViewModel(hasBundledAudio: true)

        XCTAssertTrue(viewModel.isInAppAdhanAvailable)
    }

    func testMissingAdhanAudioMakesTheControlUnavailable() {
        let viewModel = makeViewModel(hasBundledAudio: false)

        XCTAssertFalse(viewModel.isInAppAdhanAvailable)
    }

    func testControlReflectsTheStoredInAppAdhanPreference() {
        let enabled = makeViewModel(hasBundledAudio: true, isInAppAdhanEnabled: true)
        let disabled = makeViewModel(hasBundledAudio: true, isInAppAdhanEnabled: false)

        XCTAssertTrue(enabled.isInAppAdhanEnabled)
        XCTAssertFalse(disabled.isInAppAdhanEnabled)
    }

    // MARK: - Icon

    func testUnavailableAudioNeverShowsTheControlAsActive() {
        let viewModel = makeViewModel(hasBundledAudio: false, isInAppAdhanEnabled: true)

        XCTAssertFalse(viewModel.isAdhanControlActive)
        XCTAssertEqual(viewModel.adhanControlIconName, "speaker.slash")
    }

    func testEnabledAudioShowsTheControlAsActive() {
        let viewModel = makeViewModel(hasBundledAudio: true, isInAppAdhanEnabled: true)

        XCTAssertTrue(viewModel.isAdhanControlActive)
        XCTAssertEqual(viewModel.adhanControlIconName, "speaker.wave.2.fill")
    }

    func testAccessibilityLabelExplainsWhyTheControlIsUnavailable() {
        let viewModel = makeViewModel(hasBundledAudio: false)

        XCTAssertTrue(viewModel.adhanControlAccessibilityLabel.contains(viewModel.adhanUnavailableMessage))
    }

    func testControlTitlesAreLocalizedNotRawKeys() {
        let viewModel = makeViewModel(hasBundledAudio: true)

        XCTAssertFalse(viewModel.adhanControlTitle.isEmpty)
        XCTAssertFalse(viewModel.adhanUnavailableMessage.isEmpty)
        XCTAssertFalse(viewModel.adhanControlTitle.hasPrefix("prayerNotifications"))
        XCTAssertFalse(viewModel.adhanUnavailableMessage.hasPrefix("prayerNotifications"))
    }

    // MARK: - Tapping

    func testTappingWithoutBundledAudioExplainsItInsteadOfEnablingPlayback() throws {
        let viewModel = makeViewModel(hasBundledAudio: false)
        let manager = try XCTUnwrap(retainedNotificationManager)

        viewModel.onAdhanControlTapped()

        XCTAssertTrue(viewModel.isAdhanUnavailableNoticeVisible)
        XCTAssertFalse(manager.preferences.isInAppAdhanAudioEnabled)
    }

    func testTappingTwiceWithoutBundledAudioDismissesTheExplanation() {
        let viewModel = makeViewModel(hasBundledAudio: false)

        viewModel.onAdhanControlTapped()
        viewModel.onAdhanControlTapped()

        XCTAssertFalse(viewModel.isAdhanUnavailableNoticeVisible)
    }

    func testTappingWithBundledAudioTogglesTheInAppAdhanPreference() throws {
        let viewModel = makeViewModel(hasBundledAudio: true, isInAppAdhanEnabled: false)
        let manager = try XCTUnwrap(retainedNotificationManager)

        viewModel.onAdhanControlTapped()

        XCTAssertTrue(manager.preferences.isInAppAdhanAudioEnabled)
        XCTAssertTrue(viewModel.isInAppAdhanEnabled)
        XCTAssertFalse(viewModel.isAdhanUnavailableNoticeVisible)

        viewModel.onAdhanControlTapped()

        XCTAssertFalse(manager.preferences.isInAppAdhanAudioEnabled)
        XCTAssertFalse(viewModel.isInAppAdhanEnabled)
    }

    func testTappingNeverMutatesTheSharedNotificationManager() {
        let shared = PrayerNotificationManager.shared
        let sharedPreference = shared.preferences.isInAppAdhanAudioEnabled
        let viewModel = makeViewModel(hasBundledAudio: true, isInAppAdhanEnabled: false)

        viewModel.onAdhanControlTapped()

        XCTAssertEqual(shared.preferences.isInAppAdhanAudioEnabled, sharedPreference)
    }
}

// MARK: - Coordinator Stub

private final class PrayerTimesCoordinatorStub: PrayerTimesCoordinating {

    private(set) var locationPickerCallCount = 0
    private(set) var backCallCount = 0

    func coordinateToLocationPicker() {
        locationPickerCallCount += 1
    }

    func coordinateBack() {
        backCallCount += 1
    }
}

private extension PrayerTimesAdhanControlTests {

    func makeViewModel(hasBundledAudio: Bool,
                       isInAppAdhanEnabled: Bool = false) -> PrayerTimesViewModel {
        let coordinator = PrayerTimesCoordinatorStub()
        let manager = makeNotificationManager(hasBundledAudio: hasBundledAudio,
                                              isInAppAdhanEnabled: isInAppAdhanEnabled)
        retainedCoordinator = coordinator
        retainedNotificationManager = manager
        return PrayerTimesViewModel(coordinator: coordinator, notificationManager: manager)
    }

    func makeNotificationManager(hasBundledAudio: Bool,
                                 isInAppAdhanEnabled: Bool) -> PrayerNotificationManager {
        let catalog = hasBundledAudio
            ? PrayerNotificationFixture.soundCatalogWithBundledAudio()
            : PrayerNotificationFixture.soundCatalogWithoutAudio()
        return PrayerNotificationManagerBuilder
            .manager(center: LocalNotificationCenterDouble(status: .authorized),
                     defaults: PrayerNotificationFixture.defaults(),
                     preferences: PrayerNotificationFixture
                         .preferences(isInAppAdhanEnabled: isInAppAdhanEnabled),
                     now: PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey,
                                                         minutesSinceMidnight: 30),
                     soundCatalog: catalog)
    }
}
