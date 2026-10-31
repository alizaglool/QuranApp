//
//  QiblaTestDoubles.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import Foundation
import Combine
import CoreLocation
@testable import QuranApp

// MARK: - Fixtures

enum QiblaFixture {

    static func defaults(_ name: String = UUID().uuidString) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    static func cairo() -> SelectedLocation {
        SelectedLocation(cityName: "Cairo",
                         countryCode: "EG",
                         latitude: 30.0444,
                         longitude: 31.2357,
                         timeZoneIdentifier: "Africa/Cairo",
                         isResolvedFromDevice: true,
                         altitudeMeters: nil)
    }

    static func istanbul() -> SelectedLocation {
        SelectedLocation(cityName: "Istanbul",
                         countryCode: "TR",
                         latitude: 41.0082,
                         longitude: 28.9784,
                         timeZoneIdentifier: "Europe/Istanbul",
                         isResolvedFromDevice: true,
                         altitudeMeters: 40)
    }

    static func reading(degreesFromNorth: Double,
                        accuracy: DeviceHeadingAccuracy = .good) -> DeviceHeadingReading {
        DeviceHeadingReading(degreesFromNorth: degreesFromNorth, accuracy: accuracy)
    }
}

// MARK: - Heading Provider Double

final class DeviceHeadingProviderDouble: DeviceHeadingProviding {

    var isHeadingAvailable: Bool
    private(set) var latestReading: DeviceHeadingReading?
    private(set) var attachCallCount = 0
    private(set) var detachCallCount = 0

    var activeObserverCount: Int { attachCallCount - detachCallCount }

    var headingReadings: AnyPublisher<DeviceHeadingReading, Never> {
        readingSubject.eraseToAnyPublisher()
    }

    private let readingSubject = PassthroughSubject<DeviceHeadingReading, Never>()

    init(isHeadingAvailable: Bool = true) {
        self.isHeadingAvailable = isHeadingAvailable
    }

    func attachHeadingObserver() {
        attachCallCount += 1
    }

    func detachHeadingObserver() {
        detachCallCount += 1
    }

    func emit(_ reading: DeviceHeadingReading) {
        latestReading = reading
        readingSubject.send(reading)
    }
}

// MARK: - Location Authorization Double

final class DeviceLocationAuthorizationDouble: DeviceLocationAuthorizing {

    var isPreciseAccuracyReduced: Bool
    private(set) var requestAuthorizationCallCount = 0

    var authorizationStatus: CLAuthorizationStatus { statusSubject.value }

    var authorizationStatusChanges: AnyPublisher<CLAuthorizationStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    private let statusSubject: CurrentValueSubject<CLAuthorizationStatus, Never>

    init(authorizationStatus: CLAuthorizationStatus = .authorizedWhenInUse,
         isPreciseAccuracyReduced: Bool = false) {
        statusSubject = CurrentValueSubject(authorizationStatus)
        self.isPreciseAccuracyReduced = isPreciseAccuracyReduced
    }

    func requestAuthorizationIfNotDetermined() {
        requestAuthorizationCallCount += 1
    }

    func update(authorizationStatus: CLAuthorizationStatus) {
        statusSubject.send(authorizationStatus)
    }
}
