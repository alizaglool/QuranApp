//
//  CityLookupService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import CoreLocation
import Core

final class CityLookupService {

    static let shared = CityLookupService()

    private let forwardGeocoder = CLGeocoder()
    private let minimumQueryLength = 2
}

// MARK: - Search

extension CityLookupService {

    func searchCities(matching query: String) async -> [SelectedLocation] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= minimumQueryLength else { return [] }

        forwardGeocoder.cancelGeocode()

        let activeLocale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        let placemarks = try? await forwardGeocoder.geocodeAddressString(trimmedQuery,
                                                                        in: nil,
                                                                        preferredLocale: activeLocale)

        return deduplicatedCities(placemarks?.compactMap(CityLookupService.city(from:)) ?? [])
    }
}

// MARK: - Mapping

private extension CityLookupService {

    static func city(from placemark: CLPlacemark) -> SelectedLocation? {
        guard let coordinate = placemark.location?.coordinate,
              SelectedLocation.cityName(from: placemark) != nil
        else { return nil }

        return SelectedLocation(placemark: placemark,
                                coordinate: coordinate,
                                isResolvedFromDevice: false,
                                altitudeMeters: nil)
    }

    func deduplicatedCities(_ cities: [SelectedLocation]) -> [SelectedLocation] {
        var seenCityKeys: Set<String> = []
        return cities.filter { seenCityKeys.insert("\($0.cityName)|\($0.countryCode)").inserted }
    }
}
