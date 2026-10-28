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

        guard location.hasResolvedCityName else { return AppLocalizedKeys.homeLocation.value }
        guard !countryName.isEmpty else { return location.cityName }

        return String(format: AppLocalizedKeys.locationLabelFormat.value,
                      location.cityName,
                      countryName)
    }

    func localizedCountryName(for countryCode: String) -> String {
        guard !countryCode.isEmpty else { return "" }

        let activeLanguageCode = LocalizationManager.shared.currentLanguage.rawValue
        return Locale(identifier: activeLanguageCode).localizedString(forRegionCode: countryCode) ?? ""
    }
}
