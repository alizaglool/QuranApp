//
//  LocationPickerViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import Combine
import UIKit
import Core

struct LocationSearchResultItem: Identifiable {
    let id: String
    let cityName: String
    let countryName: String
    let isSelected: Bool
    let location: SelectedLocation
}

@MainActor
final class LocationPickerViewModel: MainViewModel {

    @Published var searchQuery: String = ""
    @Published private(set) var searchResults: [LocationSearchResultItem] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var hasNoSearchResults: Bool = false
    @Published private(set) var isResolvingDeviceLocation: Bool = false
    @Published private(set) var isDeviceLocationDenied: Bool = false
    @Published private(set) var selectedLocationLabel: String = ""

    private let cityLookupService = CityLookupService.shared
    private let deviceLocationService = DeviceLocationService.shared
    private let locationStore = SelectedLocationStore.shared
    private let prayerTimesStore = PrayerTimesStore.shared
    private let locationLabelFormatter = SelectedLocationLabelFormatter()
    private weak var coordinator: PrayerTimesCoordinating?
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    var isTabBarVisible: Bool { false }

    init(coordinator: PrayerTimesCoordinating) {
        self.coordinator = coordinator
        selectedLocationLabel = locationLabelFormatter.displayLabel(for: locationStore.selectedLocation)
        bindSearchQuery()
    }

    func onAppear() {
        isDeviceLocationDenied = deviceLocationService.isAuthorizationDenied
    }
}

// MARK: - Titles

extension LocationPickerViewModel {

    var screenTitle: String { AppLocalizedKeys.locationPickerTitle.value }
    var searchPlaceholder: String { AppLocalizedKeys.locationSearchPlaceholder.value }
    var useDeviceLocationTitle: String { AppLocalizedKeys.locationUseDevice.value }
    var noResultsTitle: String { AppLocalizedKeys.locationNoResults.value }
    var permissionDeniedTitle: String { AppLocalizedKeys.locationPermissionDenied.value }
    var openSettingsTitle: String { AppLocalizedKeys.locationOpenSettings.value }
    var currentLocationSectionTitle: String { AppLocalizedKeys.locationCurrentSection.value }
    var resultsSectionTitle: String { AppLocalizedKeys.locationResultsSection.value }
}

// MARK: - Actions

extension LocationPickerViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func onUseDeviceLocationTapped() {
        guard !isResolvingDeviceLocation else { return }
        isResolvingDeviceLocation = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let resolved = try await self.deviceLocationService.resolveCurrentLocation()
                self.isResolvingDeviceLocation = false
                self.commit(resolved)
            } catch {
                self.isResolvingDeviceLocation = false
                self.isDeviceLocationDenied = self.deviceLocationService.isAuthorizationDenied
            }
        }
    }

    func onSearchResultSelected(_ item: LocationSearchResultItem) {
        commit(item.location)
    }

    func onOpenDeviceSettingsTapped() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
}

// MARK: - Search

private extension LocationPickerViewModel {

    func bindSearchQuery() {
        $searchQuery
            .removeDuplicates()
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(for: query)
            }
            .store(in: &cancellables)
    }

    func performSearch(for query: String) {
        searchTask?.cancel()

        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else {
            searchResults = []
            isSearching = false
            hasNoSearchResults = false
            return
        }

        isSearching = true
        searchTask = Task { [weak self] in
            guard let self else { return }
            let cities = await self.cityLookupService.searchCities(matching: trimmedQuery)
            guard !Task.isCancelled else { return }

            self.searchResults = cities.map(self.resultItem(for:))
            self.isSearching = false
            self.hasNoSearchResults = cities.isEmpty
        }
    }

    func resultItem(for city: SelectedLocation) -> LocationSearchResultItem {
        let selected = locationStore.selectedLocation

        return LocationSearchResultItem(
            id: city.prayerTimesCacheIdentifier,
            cityName: city.cityName,
            countryName: locationLabelFormatter.localizedCountryName(for: city.countryCode),
            isSelected: city.prayerTimesCacheIdentifier == selected.prayerTimesCacheIdentifier,
            location: city
        )
    }
}

// MARK: - Commit

private extension LocationPickerViewModel {

    func commit(_ location: SelectedLocation) {
        locationStore.updateSelectedLocation(location)
        prayerTimesStore.reloadAfterSelectedLocationChange()
        selectedLocationLabel = locationLabelFormatter.displayLabel(for: location)
        coordinator?.coordinateBack()
    }
}
