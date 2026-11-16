//
//  SelectedLocation.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import CoreLocation

struct SelectedLocation: Codable, Equatable {

    let districtName: String?
    let cityName: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String?
    let isResolvedFromDevice: Bool
    let altitudeMeters: Double?

    init(districtName: String? = nil,
         cityName: String,
         countryCode: String,
         latitude: Double,
         longitude: Double,
         timeZoneIdentifier: String?,
         isResolvedFromDevice: Bool,
         altitudeMeters: Double?) {
        self.districtName = districtName
        self.cityName = cityName
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isResolvedFromDevice = isResolvedFromDevice
        self.altitudeMeters = altitudeMeters
    }
}

// MARK: - Fallback

extension SelectedLocation {

    static let riyadhFallback = SelectedLocation(cityName: "",
                                                 countryCode: "SA",
                                                 latitude: 24.7136,
                                                 longitude: 46.6753,
                                                 timeZoneIdentifier: DayPrayerTimes.fallbackTimeZoneIdentifier,
                                                 isResolvedFromDevice: false,
                                                 altitudeMeters: nil)
}

// MARK: - Identity

extension SelectedLocation {

    var prayerTimesCacheIdentifier: String {
        String(format: "%.3f,%.3f", latitude, longitude)
    }

    var hasResolvedCityName: Bool {
        !cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasResolvedDistrictName: Bool {
        guard let districtName else { return false }
        return !districtName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Placemark Mapping

extension SelectedLocation {

    init(placemark: CLPlacemark?,
         coordinate: CLLocationCoordinate2D,
         isResolvedFromDevice: Bool,
         altitudeMeters: Double?) {
        self.init(districtName: placemark.flatMap(SelectedLocation.districtName(from:)),
                  cityName: placemark.flatMap(SelectedLocation.cityName(from:)) ?? "",
                  countryCode: placemark?.isoCountryCode ?? "",
                  latitude: coordinate.latitude,
                  longitude: coordinate.longitude,
                  timeZoneIdentifier: placemark?.timeZone?.identifier,
                  isResolvedFromDevice: isResolvedFromDevice,
                  altitudeMeters: altitudeMeters)
    }

    static func cityName(from placemark: CLPlacemark) -> String? {
        placemark.locality
            ?? placemark.subAdministrativeArea
            ?? placemark.administrativeArea
            ?? placemark.country
    }

    static func districtName(from placemark: CLPlacemark) -> String? {
        guard let subLocality = placemark.subLocality?.trimmingCharacters(in: .whitespacesAndNewlines),
              !subLocality.isEmpty
        else { return nil }

        return subLocality
    }
}
