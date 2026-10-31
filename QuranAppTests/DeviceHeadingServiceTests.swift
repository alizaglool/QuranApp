//
//  DeviceHeadingServiceTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
import CoreLocation
import UIKit
@testable import QuranApp

// MARK: - Accuracy Classification

final class DeviceHeadingAccuracyTests: XCTestCase {

    func testNegativeAccuracyIsInvalid() {
        XCTAssertEqual(DeviceHeadingAccuracy(headingAccuracyInDegrees: -1), .invalid)
        XCTAssertEqual(DeviceHeadingAccuracy(headingAccuracyInDegrees: -0.1), .invalid)
    }

    func testZeroAccuracyIsGood() {
        XCTAssertEqual(DeviceHeadingAccuracy(headingAccuracyInDegrees: 0), .good)
    }

    func testAccuracyAtGoodLimitIsGood() {
        let limit = DeviceHeadingAccuracy.goodAccuracyLimitInDegrees
        XCTAssertEqual(DeviceHeadingAccuracy(headingAccuracyInDegrees: limit), .good)
    }

    func testAccuracyJustPastGoodLimitIsPoor() {
        let limit = DeviceHeadingAccuracy.goodAccuracyLimitInDegrees
        XCTAssertEqual(DeviceHeadingAccuracy(headingAccuracyInDegrees: limit + 0.1), .poor)
    }

    func testAccuracyAtUsableLimitIsPoor() {
        let limit = DeviceHeadingAccuracy.usableAccuracyLimitInDegrees
        XCTAssertEqual(DeviceHeadingAccuracy(headingAccuracyInDegrees: limit), .poor)
    }

    func testAccuracyJustPastUsableLimitIsInvalid() {
        let limit = DeviceHeadingAccuracy.usableAccuracyLimitInDegrees
        XCTAssertEqual(DeviceHeadingAccuracy(headingAccuracyInDegrees: limit + 0.1), .invalid)
    }

    func testThresholdsMatchDocumentedPolicy() {
        XCTAssertEqual(DeviceHeadingAccuracy.goodAccuracyLimitInDegrees, 15)
        XCTAssertEqual(DeviceHeadingAccuracy.usableAccuracyLimitInDegrees, 30)
    }

    func testUsabilityFlags() {
        XCTAssertFalse(DeviceHeadingAccuracy.invalid.isUsable)
        XCTAssertTrue(DeviceHeadingAccuracy.poor.isUsable)
        XCTAssertTrue(DeviceHeadingAccuracy.good.isUsable)

        XCTAssertFalse(DeviceHeadingAccuracy.invalid.isReliable)
        XCTAssertFalse(DeviceHeadingAccuracy.poor.isReliable)
        XCTAssertTrue(DeviceHeadingAccuracy.good.isReliable)
    }
}

// MARK: - Heading Orientation

final class DeviceHeadingOrientationTests: XCTestCase {

    func testPortraitOrientationsMapDirectly() {
        XCTAssertEqual(DeviceHeadingService.headingOrientation(for: .portrait), .portrait)
        XCTAssertEqual(DeviceHeadingService.headingOrientation(for: .portraitUpsideDown), .portraitUpsideDown)
    }

    func testLandscapeOrientationsAreSwapped() {
        XCTAssertEqual(DeviceHeadingService.headingOrientation(for: .landscapeLeft), .landscapeRight)
        XCTAssertEqual(DeviceHeadingService.headingOrientation(for: .landscapeRight), .landscapeLeft)
    }

    func testUnknownOrientationFallsBackToPortrait() {
        XCTAssertEqual(DeviceHeadingService.headingOrientation(for: .unknown), .portrait)
    }

    @MainActor
    func testApplyingOrientationUpdatesTheHeadingOrientationInUse() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        service.applyHeadingOrientation(for: .landscapeLeft)
        XCTAssertEqual(service.headingOrientation, .landscapeRight)

        service.applyHeadingOrientation(for: .portraitUpsideDown)
        XCTAssertEqual(service.headingOrientation, .portraitUpsideDown)

        service.applyHeadingOrientation(for: .portrait)
        XCTAssertEqual(service.headingOrientation, .portrait)
    }
}

// MARK: - Observation Lifecycle

final class DeviceHeadingServiceLifecycleTests: XCTestCase {

    @MainActor
    func testServiceDoesNotTrackBeforeAnyObserverAttaches() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        XCTAssertEqual(service.observerCount, 0)
        XCTAssertFalse(service.isTrackingHeading)
        XCTAssertNil(service.latestReading)
    }

    @MainActor
    func testManyObserversShareASingleHeadingStream() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        service.attachHeadingObserver()
        XCTAssertTrue(service.isTrackingHeading)

        service.attachHeadingObserver()
        service.attachHeadingObserver()

        XCTAssertEqual(service.observerCount, 3)
        XCTAssertTrue(service.isTrackingHeading)
    }

    @MainActor
    func testStreamStopsOnlyWhenEveryObserverDetaches() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        service.attachHeadingObserver()
        service.attachHeadingObserver()

        service.detachHeadingObserver()
        XCTAssertEqual(service.observerCount, 1)
        XCTAssertTrue(service.isTrackingHeading)

        service.detachHeadingObserver()
        XCTAssertEqual(service.observerCount, 0)
        XCTAssertFalse(service.isTrackingHeading)
    }

    @MainActor
    func testStreamRestartsWhenAnObserverReturns() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        service.attachHeadingObserver()
        service.detachHeadingObserver()
        XCTAssertFalse(service.isTrackingHeading)

        service.attachHeadingObserver()
        XCTAssertEqual(service.observerCount, 1)
        XCTAssertTrue(service.isTrackingHeading)
    }

    @MainActor
    func testUnbalancedDetachDoesNotDriveObserverCountNegative() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        service.detachHeadingObserver()
        service.detachHeadingObserver()

        XCTAssertEqual(service.observerCount, 0)
        XCTAssertFalse(service.isTrackingHeading)
    }

    @MainActor
    func testServiceNeverTracksWhenHeadingHardwareIsUnavailable() {
        let service = DeviceHeadingService(isHeadingAvailable: false)

        service.attachHeadingObserver()

        XCTAssertEqual(service.observerCount, 1)
        XCTAssertFalse(service.isTrackingHeading)
    }
}

// MARK: - Calibration Prompt

final class DeviceHeadingCalibrationTests: XCTestCase {

    @MainActor
    func testCalibrationPromptIsSuppressedWhileNotTracking() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        XCTAssertFalse(service.locationManagerShouldDisplayHeadingCalibration(CLLocationManager()))
    }

    @MainActor
    func testCalibrationPromptIsAllowedWhileTrackingWithoutAReliableReading() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        service.attachHeadingObserver()

        XCTAssertTrue(service.locationManagerShouldDisplayHeadingCalibration(CLLocationManager()))
    }

    @MainActor
    func testCalibrationPromptIsSuppressedAgainAfterEveryObserverDetaches() {
        let service = DeviceHeadingService(isHeadingAvailable: true)

        service.attachHeadingObserver()
        service.detachHeadingObserver()

        XCTAssertFalse(service.locationManagerShouldDisplayHeadingCalibration(CLLocationManager()))
    }

    @MainActor
    func testCalibrationPromptIsSuppressedWhenHeadingHardwareIsUnavailable() {
        let service = DeviceHeadingService(isHeadingAvailable: false)

        service.attachHeadingObserver()

        XCTAssertFalse(service.locationManagerShouldDisplayHeadingCalibration(CLLocationManager()))
    }
}
