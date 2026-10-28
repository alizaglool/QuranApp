//
//  RadioStationsViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation
import Core

// MARK: - RadioStationsViewModel

@MainActor
final class RadioStationsViewModel: MainViewModel {

    @Published var searchText: String = ""
    @Published var showReciterLibrary: Bool = false
    @Published private(set) var stations: [RadioStation] = []
    @Published private(set) var isLoadingCatalog: Bool = false
    @Published private(set) var catalogFailed: Bool = false

    weak var coordinator: RadioCoordinating?

    private let catalog = RadioCatalogService.shared
    private let player = RadioPlayer.shared
    private let offline = OfflineRadioService.shared
    private let reachability = NetworkReachability.shared
    private let defaults = UserDefaults.standard

    private static let lastStationKey = "radio.lastStationID"

    init(coordinator: RadioCoordinating? = nil) {
        self.coordinator = coordinator
    }

    func onAppear() {
        loadCatalog()
        Task { [weak self] in
            guard let self else { return }
            let seeded = await Self.seedStations()
            if self.stations.isEmpty { self.stations = seeded }
            self.offline.refreshStations()
        }
    }

    private nonisolated static func seedStations() async -> [RadioStation] {
        RadioCatalogService.shared.currentStations()
    }

    // MARK: - Catalog

    private func loadCatalog() {
        guard !isLoadingCatalog else { return }
        isLoadingCatalog = stations.isEmpty
        catalogFailed = false

        Task { [weak self] in
            guard let self else { return }
            do {
                let stations = try await catalog.refresh()
                self.stations = stations
                self.catalogFailed = false
            } catch {
                self.catalogFailed = self.stations.isEmpty
            }
            self.isLoadingCatalog = false
        }
    }

    func retry() {
        loadCatalog()
    }

    // MARK: - Sections

    var liveStations: [RadioStation] {
        filteredStations.filter { $0.isLive }
    }

    var audioStations: [RadioStation] {
        filteredStations.filter { !$0.isLive }
    }

    var filteredOfflineStations: [OfflineRadioStation] {
        let query = trimmedQuery
        guard !query.isEmpty else { return offline.stations }
        return offline.stations.filter {
            $0.nameAr.localizedCaseInsensitiveContains(query)
            || $0.nameEn.localizedCaseInsensitiveContains(query)
        }
    }

    var hasDownloads: Bool { !offline.stations.isEmpty }

    var hasVisibleContent: Bool {
        !liveStations.isEmpty || !audioStations.isEmpty || !filteredOfflineStations.isEmpty
    }

    var hasAnyContent: Bool { !stations.isEmpty || hasDownloads }

    var hasSearchQuery: Bool { !trimmedQuery.isEmpty }

    private var filteredStations: [RadioStation] {
        let query = trimmedQuery
        guard !query.isEmpty else { return stations }
        return stations.filter {
            $0.nameAr.localizedCaseInsensitiveContains(query)
            || $0.nameEn.localizedCaseInsensitiveContains(query)
        }
    }

    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Playback

    var isOnline: Bool { reachability.isOnline }

    func isEnabled(_ station: RadioStation) -> Bool { isOnline }

    func isCurrent(_ station: RadioStation) -> Bool {
        player.currentStation?.id == station.id
    }

    func isCurrent(_ station: OfflineRadioStation) -> Bool {
        offline.currentStation?.id == station.id
    }

    func play(_ station: RadioStation) {
        guard isOnline else { return }
        offline.stop()
        player.play(station: station, title: name(for: station))
        defaults.set(station.id, forKey: Self.lastStationKey)
    }

    func play(_ station: OfflineRadioStation) {
        player.stop()
        offline.play(station: station)
        defaults.set(station.reciterSlug, forKey: Self.lastStationKey)
    }

    func openLiveChannel(_ station: RadioStation) {
        guard isOnline else { return }
        stopAll()
        coordinator?.coordinateToLiveChannel(station, title: name(for: station))
    }

    func toggleCurrent() {
        isOfflineActive ? offline.toggle() : player.toggle()
    }

    func stopCurrent() {
        stopAll()
    }

    private func stopAll() {
        player.stop()
        offline.stop()
    }

    func openReciterLibrary() {
        showReciterLibrary = true
    }

    // MARK: - Player State

    private var isOfflineActive: Bool { offline.currentStation != nil }

    var isPlayerVisible: Bool { isOfflineActive || player.hasActiveStation }

    var isPlayerPlaying: Bool { isOfflineActive ? offline.isPlaying : player.isPlaying }

    var isPlayerLoading: Bool { isOfflineActive ? offline.isLoading : player.isLoading }

    var playerTitle: String {
        guard isOfflineActive else { return player.currentTitle }
        return offline.currentStation.map { name(for: $0) } ?? ""
    }

    var playerSubtitle: String {
        AppLocalizedKeys.nowPlaying.value
    }

    var playerToggleLabel: String {
        isPlayerPlaying ? AppLocalizedKeys.pause.value : AppLocalizedKeys.play.value
    }

    var playerStopLabel: String {
        AppLocalizedKeys.close.value
    }

    // MARK: - Localized Copy

    var title: String { AppLocalizedKeys.radioTitle.value }
    var subtitle: String { AppLocalizedKeys.radioSubtitle.value }
    var searchPlaceholder: String { AppLocalizedKeys.search.value }
    var liveBadge: String { AppLocalizedKeys.radioLive.value }
    var offlineBanner: String { AppLocalizedKeys.radioOffline.value }
    var noResultsText: String { AppLocalizedKeys.noResults.value }
    var retryTitle: String { AppLocalizedKeys.retryAction.value }
    var emptyOfflineTitle: String { AppLocalizedKeys.noDownloadsTitle.value }
    var emptyOfflineMessage: String { AppLocalizedKeys.noDownloadsMessage.value }
    var downloadActionTitle: String { AppLocalizedKeys.downloadRecitersAction.value }
    var liveSectionTitle: String { AppLocalizedKeys.radioSectionLive.value }
    var stationsSectionTitle: String { AppLocalizedKeys.radioSectionStations.value }
    var downloadedSectionTitle: String { AppLocalizedKeys.radioSectionDownloaded.value }
    var needsConnectionText: String { AppLocalizedKeys.radioNeedsConnection.value }

    var failureMessage: String? {
        guard !isOfflineActive, let failure = player.failure else { return nil }
        switch failure {
        case .offline:      return AppLocalizedKeys.radioOfflineMessage.value
        case .timedOut:     return AppLocalizedKeys.radioTimedOut.value
        case .streamFailed: return AppLocalizedKeys.radioStreamFailed.value
        }
    }

    func name(for station: RadioStation) -> String {
        isArabic ? station.nameAr : station.nameEn
    }

    func name(for station: OfflineRadioStation) -> String {
        isArabic ? station.nameAr : station.nameEn
    }

    func detail(for station: OfflineRadioStation) -> String {
        String(format: AppLocalizedKeys.surahsDownloaded.value, station.surahCount)
    }

    private var isArabic: Bool {
        LocalizationManager.shared.currentLanguage == .Arabic
    }
}
