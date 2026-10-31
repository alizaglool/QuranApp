//
//  DeviceHeadingService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import Combine
import CoreLocation
import UIKit

// MARK: - Accuracy

enum DeviceHeadingAccuracy {
    case invalid
    case poor
    case good
}

extension DeviceHeadingAccuracy {

    static let goodAccuracyLimitInDegrees: Double = 15
    static let usableAccuracyLimitInDegrees: Double = 30

    init(headingAccuracyInDegrees: Double) {
        guard headingAccuracyInDegrees >= 0 else {
            self = .invalid
            return
        }

        if headingAccuracyInDegrees <= DeviceHeadingAccuracy.goodAccuracyLimitInDegrees {
            self = .good
        } else if headingAccuracyInDegrees <= DeviceHeadingAccuracy.usableAccuracyLimitInDegrees {
            self = .poor
        } else {
            self = .invalid
        }
    }

    var isUsable: Bool { self != .invalid }

    var isReliable: Bool { self == .good }
}

// MARK: - Reading

struct DeviceHeadingReading {
    let degreesFromNorth: Double
    let accuracy: DeviceHeadingAccuracy
}

// MARK: - Provider

protocol DeviceHeadingProviding: AnyObject {
    var isHeadingAvailable: Bool { get }
    var latestReading: DeviceHeadingReading? { get }
    var headingReadings: AnyPublisher<DeviceHeadingReading, Never> { get }

    func attachHeadingObserver()
    func detachHeadingObserver()
}

// MARK: - Service

final class DeviceHeadingService: NSObject, DeviceHeadingProviding {

    static let shared = DeviceHeadingService()

    private(set) var isHeadingAvailable: Bool
    private(set) var observerCount: Int = 0
    private(set) var isTrackingHeading: Bool = false

    var latestReading: DeviceHeadingReading? { readingSubject.value }

    var headingReadings: AnyPublisher<DeviceHeadingReading, Never> {
        readingSubject.compactMap { $0 }.eraseToAnyPublisher()
    }

    var headingOrientation: CLDeviceOrientation { locationManager.headingOrientation }

    private let locationManager = CLLocationManager()
    private let readingSubject = CurrentValueSubject<DeviceHeadingReading?, Never>(nil)
    private var isObservingOrientationChanges = false

    private static let headingFilterInDegrees: CLLocationDegrees = 1

    override init() {
        isHeadingAvailable = CLLocationManager.headingAvailable()
        super.init()
        configureLocationManager()
    }

    init(isHeadingAvailable: Bool) {
        self.isHeadingAvailable = isHeadingAvailable
        super.init()
        configureLocationManager()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Observation Lifecycle

extension DeviceHeadingService {

    func attachHeadingObserver() {
        observerCount += 1
        startTrackingHeadingIfNeeded()
    }

    func detachHeadingObserver() {
        guard observerCount > 0 else { return }
        observerCount -= 1
        guard observerCount == 0 else { return }
        stopTrackingHeading()
    }
}

// MARK: - Heading Orientation

extension DeviceHeadingService {

    func applyHeadingOrientation(for interfaceOrientation: UIInterfaceOrientation) {
        locationManager.headingOrientation = DeviceHeadingService.headingOrientation(for: interfaceOrientation)
    }

    static func headingOrientation(for interfaceOrientation: UIInterfaceOrientation) -> CLDeviceOrientation {
        switch interfaceOrientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        default:
            return .portrait
        }
    }
}

// MARK: - Tracking

private extension DeviceHeadingService {

    func configureLocationManager() {
        locationManager.delegate = self
        locationManager.headingFilter = DeviceHeadingService.headingFilterInDegrees
        locationManager.headingOrientation = .portrait
    }

    func startTrackingHeadingIfNeeded() {
        guard isHeadingAvailable, !isTrackingHeading else { return }
        isTrackingHeading = true
        synchronizeHeadingOrientation()
        startObservingOrientationChanges()
        locationManager.startUpdatingHeading()
    }

    func stopTrackingHeading() {
        guard isTrackingHeading else { return }
        isTrackingHeading = false
        stopObservingOrientationChanges()
        locationManager.stopUpdatingHeading()
    }

    func synchronizeHeadingOrientation() {
        applyHeadingOrientation(for: DeviceHeadingService.activeInterfaceOrientation())
    }

    static func activeInterfaceOrientation() -> UIInterfaceOrientation {
        MainActor.assumeIsolated {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let activeScene = windowScenes.first { $0.activationState == .foregroundActive } ?? windowScenes.first
            return activeScene?.interfaceOrientation ?? .portrait
        }
    }
}

// MARK: - Orientation Notifications

private extension DeviceHeadingService {

    func startObservingOrientationChanges() {
        guard !isObservingOrientationChanges else { return }
        isObservingOrientationChanges = true

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(interfaceOrientationDidChange),
                                              name: UIDevice.orientationDidChangeNotification,
                                              object: nil)
    }

    func stopObservingOrientationChanges() {
        guard isObservingOrientationChanges else { return }
        isObservingOrientationChanges = false

        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    @objc func interfaceOrientationDidChange() {
        guard isTrackingHeading else { return }
        synchronizeHeadingOrientation()
    }
}

// MARK: - Heading Updates

private extension DeviceHeadingService {

    func handleHeadingUpdate(_ newHeading: CLHeading, from manager: CLLocationManager) {
        let accuracy = DeviceHeadingAccuracy(headingAccuracyInDegrees: newHeading.headingAccuracy)
        guard accuracy.isUsable else { return }

        let degrees = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        readingSubject.send(DeviceHeadingReading(degreesFromNorth: degrees, accuracy: accuracy))

        guard accuracy.isReliable else { return }
        manager.dismissHeadingCalibrationDisplay()
    }

    func shouldDisplayHeadingCalibration() -> Bool {
        guard isTrackingHeading else { return false }
        guard let accuracy = latestReading?.accuracy else { return true }
        return !accuracy.isReliable
    }
}

// MARK: - CLLocationManagerDelegate

extension DeviceHeadingService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        handleHeadingUpdate(newHeading, from: manager)
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        shouldDisplayHeadingCalibration()
    }
}
