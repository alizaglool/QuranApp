//
//  QiblaCompassViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import Combine
import CoreLocation
import UIKit
import Core

// MARK: - Readiness

enum QiblaReadinessState {
    case ready
    case headingUnavailable
    case locationPermissionNotRequested
    case locationPermissionDenied
    case fallbackLocation
    case approximateLocation
    case lowHeadingAccuracy
}

enum QiblaRecoveryAction {
    case requestLocationPermission
    case openSystemSettings
}

extension QiblaReadinessState {

    var isBearingTrustworthy: Bool {
        switch self {
        case .ready, .approximateLocation, .lowHeadingAccuracy:
            return true
        case .headingUnavailable, .locationPermissionNotRequested, .locationPermissionDenied, .fallbackLocation:
            return false
        }
    }
}

// MARK: - View Model

@MainActor
final class QiblaCompassViewModel: ObservableObject {

    @Published private(set) var qiblaBearingDegrees: Double = 0
    @Published private(set) var smoothedHeadingDegrees: Double = 0
    @Published private(set) var isFacingQibla: Bool = false
    @Published private(set) var isCompassAvailable: Bool = true
    @Published private(set) var distanceToKaabaMeters: Double = 0
    @Published private(set) var elevationMeters: Double?
    @Published private(set) var readinessState: QiblaReadinessState = .ready
    @Published private(set) var headingAccuracy: DeviceHeadingAccuracy = .invalid

    private let headingService: DeviceHeadingProviding
    private let locationStore: SelectedLocationStore
    private let locationAuthorization: DeviceLocationAuthorizing
    private let alignmentFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var cancellables = Set<AnyCancellable>()
    private var hasReceivedHeading = false
    private var isObservingHeading = false

    private static let headingSmoothingFactor: Double = 0.25
    private static let facingToleranceDegrees: Double = 5

    init(headingService: DeviceHeadingProviding? = nil,
         locationStore: SelectedLocationStore? = nil,
         locationAuthorization: DeviceLocationAuthorizing? = nil) {
        self.headingService = headingService ?? DeviceHeadingService.shared
        self.locationStore = locationStore ?? SelectedLocationStore.shared
        self.locationAuthorization = locationAuthorization ?? DeviceLocationService.shared

        isCompassAvailable = self.headingService.isHeadingAvailable
        recomputeBearing(for: self.locationStore.selectedLocation)
        bindSelectedLocation()
        bindDeviceHeading()
        bindLocationAuthorization()
        refreshReadinessState()
    }

    deinit {
        guard isObservingHeading else { return }
        headingService.detachHeadingObserver()
    }
}

// MARK: - Lifecycle

extension QiblaCompassViewModel {

    func onAppear() {
        guard !isObservingHeading else { return }
        isObservingHeading = true
        headingService.attachHeadingObserver()
        refreshReadinessState()
    }

    func onDisappear() {
        guard isObservingHeading else { return }
        isObservingHeading = false
        headingService.detachHeadingObserver()
    }
}

// MARK: - Dial Geometry

extension QiblaCompassViewModel {

    var dialRotationDegrees: Double {
        isCompassAvailable ? -smoothedHeadingDegrees : 0
    }

    var needleRotationDegrees: Double {
        isCompassAvailable
            ? qiblaBearingDegrees - smoothedHeadingDegrees
            : qiblaBearingDegrees
    }

    var qiblaOffsetDegrees: Double {
        guard isCompassAvailable else { return 0 }
        return QiblaDirectionCalculator.shortestRotation(from: 0, to: needleRotationDegrees)
    }
}

// MARK: - Readiness State

extension QiblaCompassViewModel {

    var readinessMessage: String? {
        switch readinessState {
        case .ready:
            return nil
        case .headingUnavailable:
            return AppLocalizedKeys.qiblaUnavailable.value
        case .locationPermissionNotRequested:
            return AppLocalizedKeys.qiblaLocationPermissionNeeded.value
        case .locationPermissionDenied:
            return AppLocalizedKeys.qiblaLocationPermissionDenied.value
        case .fallbackLocation:
            return AppLocalizedKeys.qiblaDefaultLocation.value
        case .approximateLocation:
            return AppLocalizedKeys.qiblaApproximateLocation.value
        case .lowHeadingAccuracy:
            return AppLocalizedKeys.qiblaLowHeadingAccuracy.value
        }
    }

    var recoveryAction: QiblaRecoveryAction? {
        switch readinessState {
        case .locationPermissionNotRequested:
            return .requestLocationPermission
        case .locationPermissionDenied, .approximateLocation:
            return .openSystemSettings
        case .ready, .headingUnavailable, .fallbackLocation, .lowHeadingAccuracy:
            return nil
        }
    }

    var recoveryActionTitle: String? {
        switch recoveryAction {
        case .requestLocationPermission:
            return AppLocalizedKeys.qiblaEnableLocation.value
        case .openSystemSettings:
            return AppLocalizedKeys.locationOpenSettings.value
        case .none:
            return nil
        }
    }

    func onRecoveryActionTapped() {
        switch recoveryAction {
        case .requestLocationPermission:
            locationAuthorization.requestAuthorizationIfNotDetermined()
        case .openSystemSettings:
            openSystemSettings()
        case .none:
            break
        }
    }
}

// MARK: - Presentation Strings

extension QiblaCompassViewModel {

    var title: String { AppLocalizedKeys.qiblaTitle.value }

    var bearingText: String {
        String(format: AppLocalizedKeys.qiblaDegreesFormat.value, Int(qiblaBearingDegrees.rounded()))
    }

    var statusText: String {
        if let readinessMessage { return readinessMessage }
        return isFacingQibla
            ? AppLocalizedKeys.qiblaAligned.value
            : AppLocalizedKeys.qiblaAlignHint.value
    }

    var titleTracking: CGFloat {
        LocalizationManager.shared.currentLanguage == .Arabic ? 0 : 1.5
    }

    var cardinalLabels: [String] {
        AppLocalizedKeys.qiblaCardinals.value
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var distanceToKaabaText: String {
        let kilometres = Int((distanceToKaabaMeters / 1000).rounded())
        return String(format: AppLocalizedKeys.qiblaDistanceFormat.value, "\(kilometres)")
    }

    var elevationText: String? {
        guard let elevationMeters else { return nil }
        let metres = Int(elevationMeters.rounded())
        return String(format: AppLocalizedKeys.qiblaElevationFormat.value, "\(metres)")
    }

    var turnGuidanceText: String {
        if let readinessMessage { return readinessMessage }
        guard !isFacingQibla else { return AppLocalizedKeys.qiblaAligned.value }
        return qiblaOffsetDegrees > 0
            ? AppLocalizedKeys.qiblaTurnRight.value
            : AppLocalizedKeys.qiblaTurnLeft.value
    }

    var accessibilityLabel: String {
        "\(title), \(bearingText), \(distanceToKaabaText), \(turnGuidanceText)"
    }
}

// MARK: - Bindings

private extension QiblaCompassViewModel {

    func bindSelectedLocation() {
        locationStore.$selectedLocation
            .sink { [weak self] location in
                self?.recomputeBearing(for: location)
                self?.refreshReadinessState()
            }
            .store(in: &cancellables)
    }

    func bindDeviceHeading() {
        headingService.headingReadings
            .sink { [weak self] reading in
                self?.applyHeadingReading(reading)
            }
            .store(in: &cancellables)
    }

    func bindLocationAuthorization() {
        locationAuthorization.authorizationStatusChanges
            .sink { [weak self] _ in
                self?.refreshReadinessState()
            }
            .store(in: &cancellables)
    }

    func recomputeBearing(for location: SelectedLocation) {
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude,
                                                longitude: location.longitude)
        qiblaBearingDegrees = QiblaDirectionCalculator.bearingToKaaba(from: coordinate)
        distanceToKaabaMeters = QiblaDirectionCalculator.distanceToKaaba(from: coordinate)
        elevationMeters = location.altitudeMeters
        refreshFacingState(for: smoothedHeadingDegrees)
    }
}

// MARK: - Readiness Resolution

private extension QiblaCompassViewModel {

    func refreshReadinessState() {
        readinessState = resolvedReadinessState()
        refreshFacingState(for: smoothedHeadingDegrees)
    }

    func resolvedReadinessState() -> QiblaReadinessState {
        guard isCompassAvailable else { return .headingUnavailable }

        switch locationAuthorization.authorizationStatus {
        case .notDetermined:
            return .locationPermissionNotRequested
        case .denied, .restricted:
            return .locationPermissionDenied
        default:
            break
        }

        if locationStore.isUsingFallbackLocation { return .fallbackLocation }
        if locationAuthorization.isPreciseAccuracyReduced { return .approximateLocation }
        if headingAccuracy == .poor { return .lowHeadingAccuracy }
        return .ready
    }

    func openSystemSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

// MARK: - Heading Smoothing

private extension QiblaCompassViewModel {

    func applyHeadingReading(_ reading: DeviceHeadingReading) {
        headingAccuracy = reading.accuracy
        applyHeading(reading.degreesFromNorth)
        refreshReadinessState()
    }

    func applyHeading(_ rawHeading: Double) {
        guard hasReceivedHeading else {
            hasReceivedHeading = true
            smoothedHeadingDegrees = rawHeading
            refreshFacingState(for: rawHeading)
            return
        }

        let step = QiblaDirectionCalculator.shortestRotation(from: smoothedHeadingDegrees,
                                                            to: rawHeading)
        smoothedHeadingDegrees += step * QiblaCompassViewModel.headingSmoothingFactor
        refreshFacingState(for: smoothedHeadingDegrees)
    }

    func refreshFacingState(for heading: Double) {
        let offset = abs(QiblaDirectionCalculator.shortestRotation(from: heading,
                                                                  to: qiblaBearingDegrees))
        let isFacing = isCompassAvailable
            && readinessState.isBearingTrustworthy
            && headingAccuracy.isReliable
            && offset <= QiblaCompassViewModel.facingToleranceDegrees
        guard isFacing != isFacingQibla else { return }

        isFacingQibla = isFacing
        guard isFacing else { return }
        alignmentFeedbackGenerator.impactOccurred()
    }
}
