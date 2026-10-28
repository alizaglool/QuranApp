//
//  SelectedLocationStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation

@MainActor
final class SelectedLocationStore: ObservableObject {

    static let shared = SelectedLocationStore()

    @Published private(set) var selectedLocation: SelectedLocation

    private static let storageKey = "selected_location_v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        selectedLocation = SelectedLocationStore.restoredLocation(from: defaults) ?? .riyadhFallback
    }
}

// MARK: - Updates

extension SelectedLocationStore {

    var isUsingFallbackLocation: Bool {
        !hasStoredLocation
    }

    func updateSelectedLocation(_ location: SelectedLocation) {
        guard selectedLocation != location else { return }
        selectedLocation = location
        persist(location)
    }
}

// MARK: - Storage

private extension SelectedLocationStore {

    var hasStoredLocation: Bool {
        defaults.data(forKey: SelectedLocationStore.storageKey) != nil
    }

    func persist(_ location: SelectedLocation) {
        guard let encoded = try? JSONEncoder().encode(location) else { return }
        defaults.set(encoded, forKey: SelectedLocationStore.storageKey)
    }

    static func restoredLocation(from defaults: UserDefaults) -> SelectedLocation? {
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(SelectedLocation.self, from: data)
    }
}
