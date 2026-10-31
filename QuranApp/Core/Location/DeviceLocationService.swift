//
//  DeviceLocationService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import Combine
import CoreLocation
import Core

// MARK: - Errors

enum DeviceLocationError: Error {
    case authorizationDenied
    case coordinateUnavailable
    case timedOut
}

// MARK: - Authorization

protocol DeviceLocationAuthorizing: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var isPreciseAccuracyReduced: Bool { get }
    var authorizationStatusChanges: AnyPublisher<CLAuthorizationStatus, Never> { get }

    func requestAuthorizationIfNotDetermined()
}

// MARK: - Service

final class DeviceLocationService: NSObject, ObservableObject, DeviceLocationAuthorizing {

    static let shared = DeviceLocationService()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let reverseGeocoder = CLGeocoder()
    private var pendingAuthorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []
    private var pendingCoordinateContinuations: [CheckedContinuation<CLLocation, Error>] = []
    private var coordinateTimeoutTask: Task<Void, Never>?

    private static let coordinateTimeoutInSeconds: UInt64 = 15
    private static let maxFixAgeInSeconds: TimeInterval = 300

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = locationManager.authorizationStatus
    }
}

// MARK: - Authorization State

extension DeviceLocationService {

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isAuthorizationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    var isPreciseAccuracyReduced: Bool {
        locationManager.accuracyAuthorization == .reducedAccuracy
    }

    var authorizationStatusChanges: AnyPublisher<CLAuthorizationStatus, Never> {
        $authorizationStatus.eraseToAnyPublisher()
    }

    func requestAuthorizationIfNotDetermined() {
        guard authorizationStatus == .notDetermined else { return }
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - Resolution

extension DeviceLocationService {

    func resolveCurrentLocation() async throws -> SelectedLocation {
        try await ensureAuthorizationGranted()
        let deviceLocation = try await requestDeviceLocation()
        return await resolvedLocation(from: deviceLocation)
    }
}

// MARK: - Authorization Flow

private extension DeviceLocationService {

    func ensureAuthorizationGranted() async throws {
        if isAuthorized { return }
        if isAuthorizationDenied { throw DeviceLocationError.authorizationDenied }

        let status = await requestWhenInUseAuthorization()
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw DeviceLocationError.authorizationDenied
        }
    }

    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            pendingAuthorizationContinuations.append(continuation)
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestDeviceLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            pendingCoordinateContinuations.append(continuation)
            locationManager.requestLocation()
            scheduleCoordinateTimeout()
        }
    }

    func scheduleCoordinateTimeout() {
        coordinateTimeoutTask?.cancel()
        coordinateTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: DeviceLocationService.coordinateTimeoutInSeconds * 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.failPendingCoordinateRequests(with: .timedOut)
        }
    }
}

// MARK: - Reverse Geocoding

private extension DeviceLocationService {

    func resolvedLocation(from deviceLocation: CLLocation) async -> SelectedLocation {
        let placemark = await nearestPlacemark(for: deviceLocation)

        return SelectedLocation(placemark: placemark,
                                coordinate: deviceLocation.coordinate,
                                isResolvedFromDevice: true,
                                altitudeMeters: DeviceLocationService.altitude(of: deviceLocation))
    }

    static func altitude(of deviceLocation: CLLocation) -> Double? {
        guard deviceLocation.verticalAccuracy >= 0 else { return nil }
        return deviceLocation.altitude
    }

    func nearestPlacemark(for deviceLocation: CLLocation) async -> CLPlacemark? {
        let activeLocale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        let placemarks = try? await reverseGeocoder.reverseGeocodeLocation(deviceLocation,
                                                                          preferredLocale: activeLocale)
        return placemarks?.first
    }
}

// MARK: - Pending Request Completion

private extension DeviceLocationService {

    func completePendingCoordinateRequests(with deviceLocation: CLLocation) {
        coordinateTimeoutTask?.cancel()
        coordinateTimeoutTask = nil
        let continuations = pendingCoordinateContinuations
        pendingCoordinateContinuations.removeAll()
        continuations.forEach { $0.resume(returning: deviceLocation) }
    }

    func failPendingCoordinateRequests(with error: DeviceLocationError) {
        coordinateTimeoutTask?.cancel()
        coordinateTimeoutTask = nil
        let continuations = pendingCoordinateContinuations
        pendingCoordinateContinuations.removeAll()
        continuations.forEach { $0.resume(throwing: error) }
    }

    func completePendingAuthorizationRequests(with status: CLAuthorizationStatus) {
        let continuations = pendingAuthorizationContinuations
        pendingAuthorizationContinuations.removeAll()
        continuations.forEach { $0.resume(returning: status) }
    }
}

// MARK: - CLLocationManagerDelegate

extension DeviceLocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authorizationStatus = status

        guard status != .notDetermined else { return }
        completePendingAuthorizationRequests(with: status)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let deviceLocation = locations.last(where: DeviceLocationService.isUsableFix) else {
            failPendingCoordinateRequests(with: .coordinateUnavailable)
            return
        }
        completePendingCoordinateRequests(with: deviceLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        failPendingCoordinateRequests(with: .coordinateUnavailable)
    }

    static func isUsableFix(_ deviceLocation: CLLocation) -> Bool {
        guard CLLocationCoordinate2DIsValid(deviceLocation.coordinate) else { return false }
        guard deviceLocation.horizontalAccuracy >= 0 else { return false }
        return abs(deviceLocation.timestamp.timeIntervalSinceNow) <= DeviceLocationService.maxFixAgeInSeconds
    }
}
