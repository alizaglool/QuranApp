//
//  DeviceLocationService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import CoreLocation
import Core

// MARK: - Errors

enum DeviceLocationError: Error {
    case authorizationDenied
    case coordinateUnavailable
}

// MARK: - Service

final class DeviceLocationService: NSObject, ObservableObject {

    static let shared = DeviceLocationService()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let locationManager = CLLocationManager()
    private let reverseGeocoder = CLGeocoder()
    private var pendingAuthorizationContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []
    private var pendingCoordinateContinuations: [CheckedContinuation<CLLocation, Error>] = []

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
        let continuations = pendingCoordinateContinuations
        pendingCoordinateContinuations.removeAll()
        continuations.forEach { $0.resume(returning: deviceLocation) }
    }

    func failPendingCoordinateRequests(with error: DeviceLocationError) {
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
        guard let deviceLocation = locations.last else {
            failPendingCoordinateRequests(with: .coordinateUnavailable)
            return
        }
        completePendingCoordinateRequests(with: deviceLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        failPendingCoordinateRequests(with: .coordinateUnavailable)
    }
}
