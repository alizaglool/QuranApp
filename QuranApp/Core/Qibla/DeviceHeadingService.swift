//
//  DeviceHeadingService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import CoreLocation

final class DeviceHeadingService: NSObject, ObservableObject {

    @Published private(set) var trueHeadingDegrees: Double?
    @Published private(set) var isHeadingAvailable: Bool = CLLocationManager.headingAvailable()

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1
        locationManager.headingOrientation = .portrait
    }
}

// MARK: - Lifecycle

extension DeviceHeadingService {

    func startTrackingHeading() {
        guard isHeadingAvailable else { return }
        locationManager.startUpdatingHeading()
    }

    func stopTrackingHeading() {
        locationManager.stopUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate

extension DeviceHeadingService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        trueHeadingDegrees = newHeading.trueHeading >= 0
            ? newHeading.trueHeading
            : newHeading.magneticHeading
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool { true }
}
