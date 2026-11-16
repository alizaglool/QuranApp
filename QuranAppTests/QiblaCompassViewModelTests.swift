//
//  QiblaCompassViewModelTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
import CoreLocation
@testable import QuranApp

@MainActor
final class QiblaCompassViewModelTests: XCTestCase {

    // MARK: - Ready State

    func testStoredLocationWithAvailableCompassIsReady() {
        let context = makeContext()

        XCTAssertEqual(context.viewModel.readinessState, .ready)
        XCTAssertNil(context.viewModel.readinessMessage)
        XCTAssertNil(context.viewModel.recoveryAction)
        XCTAssertNil(context.viewModel.recoveryActionTitle)
        XCTAssertTrue(context.viewModel.isCompassAvailable)
    }

    func testGoodHeadingOnTheQiblaBearingClaimsAlignment() {
        let context = makeContext()

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: context.viewModel.qiblaBearingDegrees))

        XCTAssertEqual(context.viewModel.headingAccuracy, .good)
        XCTAssertEqual(context.viewModel.readinessState, .ready)
        XCTAssertTrue(context.viewModel.isFacingQibla)
    }

    // MARK: - Heading Availability

    func testUnavailableHeadingHardwareIsSurfaced() {
        let context = makeContext(isHeadingAvailable: false)

        XCTAssertEqual(context.viewModel.readinessState, .headingUnavailable)
        XCTAssertFalse(context.viewModel.isCompassAvailable)
        XCTAssertNotNil(context.viewModel.readinessMessage)
        XCTAssertNil(context.viewModel.recoveryAction)
        XCTAssertFalse(context.viewModel.isFacingQibla)
    }

    // MARK: - Authorization

    func testUnrequestedPermissionOffersToRequestIt() {
        let context = makeContext(authorizationStatus: .notDetermined)

        XCTAssertEqual(context.viewModel.readinessState, .locationPermissionNotRequested)
        XCTAssertEqual(context.viewModel.recoveryAction, .requestLocationPermission)
        XCTAssertNotNil(context.viewModel.readinessMessage)

        context.viewModel.onRecoveryActionTapped()

        XCTAssertEqual(context.authorization.requestAuthorizationCallCount, 1)
    }

    func testDeniedPermissionIsSurfacedAndWithholdsAnyBearingClaim() {
        let context = makeContext(authorizationStatus: .denied)

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: context.viewModel.qiblaBearingDegrees))

        XCTAssertEqual(context.viewModel.readinessState, .locationPermissionDenied)
        XCTAssertEqual(context.viewModel.recoveryAction, .openSystemSettings)
        XCTAssertFalse(context.viewModel.isFacingQibla)

        let message = context.viewModel.readinessMessage
        XCTAssertNotNil(message)
        XCTAssertEqual(context.viewModel.statusText, message)
        XCTAssertEqual(context.viewModel.turnGuidanceText, message)
    }

    func testRestrictedPermissionIsTreatedAsDenied() {
        let context = makeContext(authorizationStatus: .restricted)

        XCTAssertEqual(context.viewModel.readinessState, .locationPermissionDenied)
    }

    func testAuthorizationLossUpdatesReadinessWhileOnScreen() {
        let context = makeContext()
        XCTAssertEqual(context.viewModel.readinessState, .ready)

        context.authorization.update(authorizationStatus: .denied)

        XCTAssertEqual(context.viewModel.readinessState, .locationPermissionDenied)
    }

    func testReducedPreciseAccuracyIsSurfacedAsApproximate() {
        let context = makeContext(isPreciseAccuracyReduced: true)

        XCTAssertEqual(context.viewModel.readinessState, .approximateLocation)
        XCTAssertEqual(context.viewModel.recoveryAction, .openSystemSettings)
        XCTAssertNotNil(context.viewModel.readinessMessage)
    }

    // MARK: - Fallback Location

    func testFallbackLocationIsSurfacedWithoutAFacingClaim() {
        let context = makeContext(storedLocation: nil)

        XCTAssertTrue(context.locationStore.isUsingFallbackLocation)
        XCTAssertEqual(context.viewModel.readinessState, .fallbackLocation)
        XCTAssertNotNil(context.viewModel.readinessMessage)
        XCTAssertNil(context.viewModel.recoveryAction)

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: context.viewModel.qiblaBearingDegrees))

        XCTAssertFalse(context.viewModel.isFacingQibla)
    }

    func testStoringARealLocationClearsTheFallbackState() {
        let context = makeContext(storedLocation: nil)
        XCTAssertEqual(context.viewModel.readinessState, .fallbackLocation)

        context.locationStore.updateSelectedLocation(QiblaFixture.cairo())

        XCTAssertFalse(context.locationStore.isUsingFallbackLocation)
        XCTAssertEqual(context.viewModel.readinessState, .ready)
    }

    // MARK: - Heading Accuracy

    func testPoorHeadingAccuracyIsSurfacedAndBlocksAlignment() {
        let context = makeContext()

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: context.viewModel.qiblaBearingDegrees,
                                                  accuracy: .poor))

        XCTAssertEqual(context.viewModel.headingAccuracy, .poor)
        XCTAssertEqual(context.viewModel.readinessState, .lowHeadingAccuracy)
        XCTAssertNotNil(context.viewModel.readinessMessage)
        XCTAssertNil(context.viewModel.recoveryAction)
        XCTAssertFalse(context.viewModel.isFacingQibla)
    }

    func testRecoveredHeadingAccuracyRestoresTheReadyState() {
        let context = makeContext()
        let bearing = context.viewModel.qiblaBearingDegrees

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: bearing, accuracy: .poor))
        XCTAssertEqual(context.viewModel.readinessState, .lowHeadingAccuracy)

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: bearing, accuracy: .good))

        XCTAssertEqual(context.viewModel.readinessState, .ready)
        XCTAssertTrue(context.viewModel.isFacingQibla)
    }

    // MARK: - Selected Location Changes

    func testSelectedLocationChangeRecomputesBearingAndDistance() {
        let context = makeContext(storedLocation: QiblaFixture.cairo())
        let cairoBearing = context.viewModel.qiblaBearingDegrees
        let cairoDistance = context.viewModel.distanceToKaabaMeters

        context.locationStore.updateSelectedLocation(QiblaFixture.istanbul())

        XCTAssertNotEqual(context.viewModel.qiblaBearingDegrees, cairoBearing)
        XCTAssertNotEqual(context.viewModel.distanceToKaabaMeters, cairoDistance)
        XCTAssertEqual(context.viewModel.elevationMeters, 40)
    }

    func testSelectedLocationChangeKeepsAlignmentConsistentWithTheNewBearing() {
        let context = makeContext(storedLocation: QiblaFixture.cairo())

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: context.viewModel.qiblaBearingDegrees))
        XCTAssertTrue(context.viewModel.isFacingQibla)

        context.locationStore.updateSelectedLocation(QiblaFixture.istanbul())

        XCTAssertFalse(context.viewModel.isFacingQibla)
    }

    // MARK: - Shared Stream

    func testObserverAttachesOnceWhileOnScreen() {
        let context = makeContext()

        context.viewModel.onAppear()
        context.viewModel.onAppear()

        XCTAssertEqual(context.heading.attachCallCount, 1)

        context.viewModel.onDisappear()
        context.viewModel.onDisappear()

        XCTAssertEqual(context.heading.detachCallCount, 1)
        XCTAssertEqual(context.heading.activeObserverCount, 0)
    }

    func testObserverReattachesAfterReturningToScreen() {
        let context = makeContext()

        context.viewModel.onAppear()
        context.viewModel.onDisappear()
        context.viewModel.onAppear()

        XCTAssertEqual(context.heading.attachCallCount, 2)
        XCTAssertEqual(context.heading.activeObserverCount, 1)
    }

    func testOneHeadingStreamFeedsEveryObserverAndStopsWhenAllDetach() {
        let heading = DeviceHeadingProviderDouble()
        let authorization = DeviceLocationAuthorizationDouble()
        let locationStore = SelectedLocationStore(defaults: QiblaFixture.defaults())
        locationStore.updateSelectedLocation(QiblaFixture.cairo())

        let card = QiblaCompassViewModel(headingService: heading,
                                         locationStore: locationStore,
                                         locationAuthorization: authorization)
        let screen = QiblaCompassViewModel(headingService: heading,
                                           locationStore: locationStore,
                                           locationAuthorization: authorization)

        card.onAppear()
        screen.onAppear()
        XCTAssertEqual(heading.activeObserverCount, 2)

        heading.emit(QiblaFixture.reading(degreesFromNorth: card.qiblaBearingDegrees))

        XCTAssertEqual(card.headingAccuracy, .good)
        XCTAssertEqual(screen.headingAccuracy, .good)
        XCTAssertTrue(card.isFacingQibla)
        XCTAssertTrue(screen.isFacingQibla)

        card.onDisappear()
        XCTAssertEqual(heading.activeObserverCount, 1)

        screen.onDisappear()
        XCTAssertEqual(heading.activeObserverCount, 0)
        XCTAssertEqual(heading.detachCallCount, 2)
    }
    func testReleasingAViewModelWithoutLeavingTheScreenStillReleasesItsObserver() {
        let heading = DeviceHeadingProviderDouble()
        let locationStore = SelectedLocationStore(defaults: QiblaFixture.defaults())
        locationStore.updateSelectedLocation(QiblaFixture.cairo())

        autoreleasepool {
            let viewModel = QiblaCompassViewModel(headingService: heading,
                                                  locationStore: locationStore,
                                                  locationAuthorization: DeviceLocationAuthorizationDouble())
            viewModel.onAppear()
            XCTAssertEqual(heading.activeObserverCount, 1)
        }

        XCTAssertEqual(heading.activeObserverCount, 0)
    }

    // MARK: - Alignment Feedback

    func testReachingTheQiblaBearingPlaysTheAlignmentFeedbackExactlyOnce() {
        let context = makeContext()

        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees)

        XCTAssertTrue(context.viewModel.isFacingQibla)
        XCTAssertEqual(context.feedback.playCallCount, 1)
    }

    func testHeadingThatNeverReachesTheQiblaBearingPlaysNoAlignmentFeedback() {
        let context = makeContext()

        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees + 40)

        XCTAssertFalse(context.viewModel.isFacingQibla)
        XCTAssertEqual(context.feedback.playCallCount, 0)
    }

    func testDriftInsideTheReleaseToleranceKeepsAlignmentWithoutRepeatingTheFeedback() {
        let context = makeContext()
        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees)

        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees + 7)

        XCTAssertTrue(context.viewModel.isFacingQibla)
        XCTAssertEqual(context.feedback.playCallCount, 1)
    }

    func testAlignmentFeedbackPlaysAgainOnlyAfterTheAlignedStateIsLeft() {
        let context = makeContext()
        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees)

        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees + 30)
        XCTAssertFalse(context.viewModel.isFacingQibla)

        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees)

        XCTAssertTrue(context.viewModel.isFacingQibla)
        XCTAssertEqual(context.feedback.playCallCount, 2)
    }

    func testUnreliableAccuracyWithholdsTheAlignmentFeedback() {
        let context = makeContext()

        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees)
        context.heading.emit(QiblaFixture.reading(degreesFromNorth: context.viewModel.qiblaBearingDegrees,
                                                  accuracy: .invalid))

        XCTAssertFalse(context.viewModel.isFacingQibla)
        XCTAssertEqual(context.feedback.playCallCount, 1)
    }

    func testLeavingTheAlignedStatePrimesTheFeedbackGeneratorAgain() {
        let context = makeContext()
        context.viewModel.onAppear()
        let prepareCountAfterAppear = context.feedback.prepareCallCount

        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees)
        settleHeading(context, onDegreesFromNorth: context.viewModel.qiblaBearingDegrees + 30)

        XCTAssertFalse(context.viewModel.isFacingQibla)
        XCTAssertGreaterThan(context.feedback.prepareCallCount, prepareCountAfterAppear)

        context.viewModel.onDisappear()
    }

    // MARK: - Heading Driven Geometry

    func testHeadingOffsetFromTheQiblaBearingDrivesTheArrowRotation() {
        let context = makeContext()
        let bearing = context.viewModel.qiblaBearingDegrees

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: bearing - 30))

        XCTAssertEqual(context.viewModel.qiblaOffsetDegrees, 30, accuracy: 0.001)
    }

    func testTurningPastTheQiblaBearingReversesTheArrowRotationSign() {
        let context = makeContext()
        let bearing = context.viewModel.qiblaBearingDegrees

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: bearing - 40))
        XCTAssertGreaterThan(context.viewModel.qiblaOffsetDegrees, 0)

        settleHeading(context, onDegreesFromNorth: bearing + 40)

        XCTAssertLessThan(context.viewModel.qiblaOffsetDegrees, 0)
    }

    func testArrowRotationHoldsAtZeroWhenTheCompassIsUnavailable() {
        let context = makeContext(isHeadingAvailable: false)

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: 90))

        XCTAssertEqual(context.viewModel.qiblaOffsetDegrees, 0)
    }

    // MARK: - Calibration Prompt

    func testNoCalibrationPromptBeforeAnyAccuracyReadingArrives() {
        let context = makeContext()

        XCTAssertFalse(context.viewModel.hasHeadingAccuracyReading)
        XCTAssertEqual(context.viewModel.readinessState, .ready)
        XCTAssertNil(context.viewModel.readinessMessage)
    }

    func testReliableHeadingAccuracyShowsNoCalibrationPrompt() {
        let context = makeContext()

        context.heading.emitAccuracy(.good)

        XCTAssertTrue(context.viewModel.hasHeadingAccuracyReading)
        XCTAssertEqual(context.viewModel.readinessState, .ready)
        XCTAssertNil(context.viewModel.readinessMessage)
    }

    func testInvalidHeadingAccuracySurfacesTheCalibrationPrompt() {
        let context = makeContext()

        context.heading.emitAccuracy(.invalid)

        XCTAssertEqual(context.viewModel.readinessState, .lowHeadingAccuracy)
        XCTAssertNotNil(context.viewModel.readinessMessage)
        XCTAssertNil(context.viewModel.recoveryAction)
        XCTAssertFalse(context.viewModel.isFacingQibla)
    }

    func testRecoveringFromInvalidAccuracyClearsTheCalibrationPrompt() {
        let context = makeContext()

        context.heading.emitAccuracy(.invalid)
        XCTAssertEqual(context.viewModel.readinessState, .lowHeadingAccuracy)

        context.heading.emitAccuracy(.good)

        XCTAssertEqual(context.viewModel.readinessState, .ready)
        XCTAssertNil(context.viewModel.readinessMessage)
    }

    // MARK: - Alignment Hysteresis

    func testOffsetInsideTheReleaseBandDoesNotAcquireAlignment() {
        let context = makeContext()
        let bearing = context.viewModel.qiblaBearingDegrees

        context.heading.emit(QiblaFixture.reading(degreesFromNorth: bearing - 7))

        XCTAssertFalse(context.viewModel.isFacingQibla)
        XCTAssertEqual(context.feedback.playCallCount, 0)
    }
}

// MARK: - Context

private struct QiblaCompassTestContext {
    let viewModel: QiblaCompassViewModel
    let heading: DeviceHeadingProviderDouble
    let authorization: DeviceLocationAuthorizationDouble
    let locationStore: SelectedLocationStore
    let feedback: QiblaAlignmentFeedbackDouble
}

private extension QiblaCompassViewModelTests {

    func makeContext(isHeadingAvailable: Bool = true,
                     authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse,
                     isPreciseAccuracyReduced: Bool = false,
                     storedLocation: SelectedLocation? = QiblaFixture.cairo()) -> QiblaCompassTestContext {
        let heading = DeviceHeadingProviderDouble(isHeadingAvailable: isHeadingAvailable)
        let authorization = DeviceLocationAuthorizationDouble(authorizationStatus: authorizationStatus,
                                                              isPreciseAccuracyReduced: isPreciseAccuracyReduced)
        let locationStore = SelectedLocationStore(defaults: QiblaFixture.defaults())

        if let storedLocation {
            locationStore.updateSelectedLocation(storedLocation)
        }

        let feedback = QiblaAlignmentFeedbackDouble()

        let viewModel = QiblaCompassViewModel(headingService: heading,
                                              locationStore: locationStore,
                                              locationAuthorization: authorization,
                                              alignmentFeedback: feedback)

        return QiblaCompassTestContext(viewModel: viewModel,
                                       heading: heading,
                                       authorization: authorization,
                                       locationStore: locationStore,
                                       feedback: feedback)
    }

    func settleHeading(_ context: QiblaCompassTestContext,
                       onDegreesFromNorth degreesFromNorth: Double,
                       emitCount: Int = 20) {
        (0..<emitCount).forEach { _ in
            context.heading.emit(QiblaFixture.reading(degreesFromNorth: degreesFromNorth))
        }
    }
}
