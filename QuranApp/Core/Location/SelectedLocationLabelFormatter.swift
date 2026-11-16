//
//  SelectedLocationLabelFormatter.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import Core

struct SelectedLocationLabelFormatter {

    func displayLabel(for location: SelectedLocation) -> String {
        let countryName = localizedCountryName(for: location.countryCode)

        guard location.hasResolvedCityName else {
            return unresolvedCityLabel(for: location, countryName: countryName)
        }
        guard !countryName.isEmpty else { return location.cityName }

        return String(format: AppLocalizedKeys.locationLabelFormat.value,
                      location.cityName,
                      countryName)
    }

    func displayLabelWithDistrict(for location: SelectedLocation) -> String {
        let countryName = localizedCountryName(for: location.countryCode)

        guard location.hasResolvedCityName else {
            return unresolvedCityLabel(for: location, countryName: countryName)
        }

        return joinedLabel(from: [location.districtName ?? "", location.cityName, countryName])
    }

    func localizedCountryName(for countryCode: String) -> String {
        guard !countryCode.isEmpty else { return "" }

        let activeLanguageCode = LocalizationManager.shared.currentLanguage.rawValue
        return Locale(identifier: activeLanguageCode).localizedString(forRegionCode: countryCode) ?? ""
    }
}

// MARK: - Unresolved City

private extension SelectedLocationLabelFormatter {

    func unresolvedCityLabel(for location: SelectedLocation, countryName: String) -> String {
        guard location.isResolvedFromDevice else { return AppLocalizedKeys.homeLocation.value }
        return countryName.isEmpty ? AppLocalizedKeys.locationCurrentPlace.value : countryName
    }
}

// MARK: - Joining

private extension SelectedLocationLabelFormatter {

    func joinedLabel(from components: [String]) -> String {
        var kept: [String] = []

        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard !kept.contains(where: { $0.localizedLowercase == trimmed.localizedLowercase }) else { continue }
            kept.append(trimmed)
        }

        guard let first = kept.first else { return "" }

        return kept.dropFirst().reduce(first) { joined, next in
            String(format: AppLocalizedKeys.locationLabelFormat.value, joined, next)
        }
    }
}
