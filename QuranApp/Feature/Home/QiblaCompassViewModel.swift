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

@MainActor
final class QiblaCompassViewModel: ObservableObject {

    @Published private(set) var qiblaBearingDegrees: Double = 0
    @Published private(set) var smoothedHeadingDegrees: Double = 0
    @Published private(set) var isFacingQibla: Bool = false
    @Published private(set) var isCompassAvailable: Bool = true
    @Published private(set) var distanceToKaabaMeters: Double = 0
    @Published private(set) var elevationMeters: Double?

    private let headingService = DeviceHeadingService()
    private let locationStore = SelectedLocationStore.shared
    private let alignmentFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    private var cancellables = Set<AnyCancellable>()
    private var hasReceivedHeading = false

    private static let headingSmoothingFactor: Double = 0.25
    private static let facingToleranceDegrees: Double = 5

    init() {
        isCompassAvailable = headingService.isHeadingAvailable
        recomputeBearing(for: locationStore.selectedLocation)
        bindSelectedLocation()
        bindDeviceHeading()
    }
}

// MARK: - Lifecycle

extension QiblaCompassViewModel {

    func onAppear() {
        headingService.startTrackingHeading()
    }

    func onDisappear() {
        headingService.stopTrackingHeading()
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

// MARK: - Presentation Strings

extension QiblaCompassViewModel {

    var title: String { AppLocalizedKeys.qiblaTitle.value }

    var bearingText: String {
        String(format: AppLocalizedKeys.qiblaDegreesFormat.value, Int(qiblaBearingDegrees.rounded()))
    }

    var statusText: String {
        guard isCompassAvailable else { return AppLocalizedKeys.qiblaUnavailable.value }
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
        guard isCompassAvailable else { return AppLocalizedKeys.qiblaUnavailable.value }
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
            }
            .store(in: &cancellables)
    }

    func bindDeviceHeading() {
        headingService.$trueHeadingDegrees
            .compactMap { $0 }
            .sink { [weak self] heading in
                self?.applyHeading(heading)
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

// MARK: - Heading Smoothing

private extension QiblaCompassViewModel {

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
        let isFacing = isCompassAvailable && offset <= QiblaCompassViewModel.facingToleranceDegrees
        guard isFacing != isFacingQibla else { return }

        isFacingQibla = isFacing
        guard isFacing else { return }
        alignmentFeedbackGenerator.impactOccurred()
    }
}
