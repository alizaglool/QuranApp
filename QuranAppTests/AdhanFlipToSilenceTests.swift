//
//  AdhanFlipToSilenceTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 19/11/2026.
//

import XCTest
import AVFoundation
import CoreMotion
@testable import QuranApp

@MainActor
final class AdhanFlipToSilenceTests: XCTestCase {

    private let bundledCatalog = PrayerNotificationFixture.soundCatalogWithBundledAudio()
    private var retainedPlayer: PrayerAdhanAudioPlayer?
    private var retainedNotificationManager: PrayerNotificationManager?

    override func tearDown() {
        retainedPlayer?.stop()
        retainedNotificationManager?.stopAdhanAudio()
        retainedPlayer = nil
        retainedNotificationManager = nil
        super.tearDown()
    }

    // MARK: - Gravity Readings

    func testPlacingTheDeviceFaceDownAfterFacingUpIsReportedOnce() {
        var evaluator = DeviceFaceDownGravityEvaluator()

        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: -1))
        XCTAssertTrue(evaluator.isNewlyFaceDown(gravityZ: 0.95))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0.95))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 1))
    }

    func testADeviceAlreadyRestingFaceDownIsNeverReported() {
        var evaluator = DeviceFaceDownGravityEvaluator()

        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0.98))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0.99))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 1))
    }

    func testReadingsBetweenTheThresholdsAreNotReportedAsFaceDown() {
        var evaluator = DeviceFaceDownGravityEvaluator()

        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: -0.9))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0.6))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0.79))
        XCTAssertTrue(evaluator.isNewlyFaceDown(gravityZ: 0.81))
    }

    func testEachFaceDownPlacementNeedsTheDeviceToBeLiftedFirst() {
        var evaluator = DeviceFaceDownGravityEvaluator()

        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: -1))
        XCTAssertTrue(evaluator.isNewlyFaceDown(gravityZ: 0.9))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0.9))
        XCTAssertFalse(evaluator.isNewlyFaceDown(gravityZ: 0.45))
        XCTAssertTrue(evaluator.isNewlyFaceDown(gravityZ: 0.9))
    }

    // MARK: - Monitoring Lifecycle

    func testFullAdhanPlaybackStartsFaceDownMonitoring() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let player = makePlayer(faceDownDetector: detector)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)

        player.playFullAdhan(for: recording)

        XCTAssertNil(player.lastFailure)
        XCTAssertEqual(player.playingMode, .fullAdhan)
        XCTAssertTrue(detector.isMonitoring)
        XCTAssertEqual(detector.startCallCount, 1)
    }

    func testNotificationTonePreviewNeverStartsFaceDownMonitoring() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let player = makePlayer(faceDownDetector: detector)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)

        player.playNotificationTonePreview(for: recording)

        XCTAssertNil(player.lastFailure)
        XCTAssertEqual(player.playingMode, .notificationTonePreview)
        XCTAssertFalse(detector.isMonitoring)
        XCTAssertEqual(detector.startCallCount, 0)
    }

    func testAMissingRecordingNeverStartsFaceDownMonitoring() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let player = makePlayer(soundCatalog: PrayerNotificationFixture.soundCatalogWithoutAudio(),
                                faceDownDetector: detector)
        let recording = try XCTUnwrap(AdhanRecording.bundled.first)

        player.playFullAdhan(for: recording)

        XCTAssertEqual(player.lastFailure?.reason, .missingResource)
        XCTAssertFalse(detector.isMonitoring)
        XCTAssertEqual(detector.startCallCount, 0)
    }

    func testStoppingPlaybackStopsFaceDownMonitoring() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let player = makePlayer(faceDownDetector: detector)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)

        player.playFullAdhan(for: recording)

        XCTAssertTrue(detector.isMonitoring)

        player.stop()

        XCTAssertFalse(detector.isMonitoring)
        XCTAssertNil(player.playingMode)
    }

    // MARK: - Silencing

    func testFaceDownPlacementStopsTheFullAdhan() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let player = makePlayer(faceDownDetector: detector)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)

        player.playFullAdhan(for: recording)
        detector.simulateFaceDownPlacement()

        XCTAssertNil(player.playingMode)
        XCTAssertNil(player.playingRecordingIdentifier)
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(detector.isMonitoring)
    }

    func testFaceDownPlacementDoesNotResumePlaybackAfterwards() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let player = makePlayer(faceDownDetector: detector)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)

        player.playFullAdhan(for: recording)
        detector.simulateFaceDownPlacement()
        detector.simulateFaceDownPlacement()

        XCTAssertEqual(detector.startCallCount, 1)
        XCTAssertNil(player.playingMode)
        XCTAssertFalse(player.isPlaying)
        XCTAssertNil(player.lastFailure)
    }

    func testFaceDownPlacementIsIgnoredWhileNothingPlays() {
        let detector = DeviceFaceDownDetectorDouble()
        let player = makePlayer(faceDownDetector: detector)

        detector.simulateFaceDownPlacement()

        XCTAssertEqual(detector.startCallCount, 0)
        XCTAssertNil(player.playingMode)
        XCTAssertNil(player.lastFailure)
    }

    func testAForegroundAdhanDeliveryStartsFaceDownMonitoring() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let manager = makeNotificationManager(faceDownDetector: detector)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)
        let identifier = PrayerNotificationIdentifier.identifier(dayKey: PrayerNotificationFixture.mondayDayKey,
                                                                 slot: .fajr,
                                                                 kind: .adhan)

        manager.selectRecording(recording)

        XCTAssertEqual(manager.presentationOptions(forIdentifier: identifier), [.banner, .list])
        XCTAssertTrue(detector.isMonitoring)

        detector.simulateFaceDownPlacement()

        XCTAssertFalse(detector.isMonitoring)
        XCTAssertFalse(manager.isPlayingAdhanAudio(recording, mode: .fullAdhan))
    }

    func testAReminderDeliveryNeverStartsFaceDownMonitoring() throws {
        let detector = DeviceFaceDownDetectorDouble()
        let manager = makeNotificationManager(faceDownDetector: detector)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)
        let identifier = PrayerNotificationIdentifier.identifier(dayKey: PrayerNotificationFixture.mondayDayKey,
                                                                 slot: .fajr,
                                                                 kind: .reminder)

        manager.selectRecording(recording)

        XCTAssertEqual(manager.presentationOptions(forIdentifier: identifier), [.banner, .list, .sound])
        XCTAssertFalse(detector.isMonitoring)
    }

    // MARK: - Sensor Availability

    func testTheMotionDetectorStaysInertWhileDeviceMotionIsUnavailable() throws {
        let motionManager = CMMotionManager()

        try XCTSkipIf(motionManager.isDeviceMotionAvailable)

        var faceDownCallCount = 0
        let detector = MotionDeviceFaceDownDetector(motionManager: motionManager)
        detector.onFaceDown = { faceDownCallCount += 1 }

        detector.startMonitoring()
        detector.stopMonitoring()
        detector.startMonitoring()

        XCTAssertFalse(motionManager.isDeviceMotionActive)
        XCTAssertEqual(faceDownCallCount, 0)
    }
}

private extension AdhanFlipToSilenceTests {

    func makePlayer(soundCatalog: PrayerNotificationSoundCatalog? = nil,
                    faceDownDetector: DeviceFaceDownDetector) -> PrayerAdhanAudioPlayer {
        let player = PrayerAdhanAudioPlayer(soundCatalog: soundCatalog ?? bundledCatalog,
                                            audioFocus: AdhanAudioFocusDouble(),
                                            faceDownDetector: faceDownDetector,
                                            notificationCenter: NotificationCenter())
        retainedPlayer = player
        return player
    }

    func makeNotificationManager(faceDownDetector: DeviceFaceDownDetector) -> PrayerNotificationManager {
        let manager = PrayerNotificationManagerBuilder
            .manager(center: LocalNotificationCenterDouble(status: .authorized),
                     defaults: PrayerNotificationFixture.defaults(),
                     preferences: PrayerNotificationFixture.preferences(isInAppAdhanEnabled: true),
                     now: PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey,
                                                         minutesSinceMidnight: 30),
                     soundCatalog: bundledCatalog,
                     faceDownDetector: faceDownDetector)
        retainedNotificationManager = manager
        return manager
    }
}
