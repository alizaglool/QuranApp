//
//  EgyptianRadioViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - EgyptianRadioPlaybackState

enum EgyptianRadioPlaybackState {
    case idle
    case connecting
    case playing
    case paused
    case failed
}

// MARK: - EgyptianRadioPlaybackSource

@MainActor
protocol EgyptianRadioPlaybackSource: AnyObject {
    var currentStation: RadioStation? { get }
    var isPlaying: Bool { get }
    var isLoading: Bool { get }
    var failure: RadioPlayerFailure? { get }

    func play(station: RadioStation, title: String)
    func toggle()
    func stop()
}

extension RadioPlayer: EgyptianRadioPlaybackSource {}

// MARK: - EgyptianRadioViewModel

@MainActor
final class EgyptianRadioViewModel: MainViewModel {

    @Published private(set) var station: RadioStation = EgyptianRadioStationReference.fallback

    private weak var coordinator: RadioCoordinating?
    private let player: any EgyptianRadioPlaybackSource
    private let offline: OfflineRadioService
    private let reachability: NetworkReachability

    var isTabBarVisible: Bool { false }

    init(coordinator: RadioCoordinating? = nil,
         player: (any EgyptianRadioPlaybackSource)? = nil,
         offline: OfflineRadioService? = nil,
         reachability: NetworkReachability? = nil) {
        self.coordinator = coordinator
        self.player = player ?? RadioPlayer.shared
        self.offline = offline ?? OfflineRadioService.shared
        self.reachability = reachability ?? NetworkReachability.shared
    }

    func onAppear() {
        Task { [weak self] in
            let resolved = await Self.resolveStation()
            self?.station = resolved
        }
    }
}

// MARK: - State

extension EgyptianRadioViewModel {

    var isOnline: Bool { reachability.isOnline }

    var isCurrentStation: Bool { player.currentStation?.id == station.id }

    var playbackState: EgyptianRadioPlaybackState {
        guard isCurrentStation else { return .idle }
        if player.failure != nil { return .failed }
        if player.isLoading { return .connecting }
        if player.isPlaying { return .playing }
        return .paused
    }

    var isPlaying: Bool { playbackState == .playing }

    var isConnecting: Bool { playbackState == .connecting }

    var isStopAvailable: Bool { isCurrentStation }
}

// MARK: - Labels

extension EgyptianRadioViewModel {

    var screenTitle: String { AppLocalizedKeys.egyptianRadioTitle.value }
    var screenSubtitle: String { AppLocalizedKeys.egyptianRadioSubtitle.value }
    var liveBadgeTitle: String { AppLocalizedKeys.radioLive.value }
    var liveNoteText: String { AppLocalizedKeys.egyptianRadioLiveNote.value }
    var offlineBannerText: String { AppLocalizedKeys.radioOffline.value }
    var stopActionTitle: String { AppLocalizedKeys.close.value }

    var stationName: String { isArabic ? station.nameAr : station.nameEn }

    var statusText: String {
        switch playbackState {
        case .idle, .paused:
            return AppLocalizedKeys.egyptianRadioIdleHint.value
        case .connecting:
            return AppLocalizedKeys.egyptianRadioConnecting.value
        case .playing:
            return AppLocalizedKeys.nowPlaying.value
        case .failed:
            return failureMessage ?? AppLocalizedKeys.radioStreamFailed.value
        }
    }

    var toggleActionTitle: String {
        isPlaying || isConnecting ? AppLocalizedKeys.pause.value : AppLocalizedKeys.play.value
    }

    var toggleActionIcon: String {
        isPlaying || isConnecting ? "pause.fill" : "play.fill"
    }

    var failureMessage: String? {
        guard isCurrentStation, let failure = player.failure else { return nil }
        switch failure {
        case .offline:      return AppLocalizedKeys.radioOfflineMessage.value
        case .timedOut:     return AppLocalizedKeys.radioTimedOut.value
        case .streamFailed: return AppLocalizedKeys.radioStreamFailed.value
        }
    }
}

// MARK: - Actions

extension EgyptianRadioViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func onPlaybackToggled() {
        guard isCurrentStation else {
            offline.stop()
            player.play(station: station, title: stationName)
            return
        }
        player.toggle()
    }

    func onStopTapped() {
        guard isCurrentStation else { return }
        player.stop()
    }
}

// MARK: - Private

private extension EgyptianRadioViewModel {

    nonisolated static func resolveStation() async -> RadioStation {
        EgyptianRadioStationReference.station(in: RadioCatalogService.shared.currentStations())
    }

    var isArabic: Bool {
        LocalizationManager.shared.currentLanguage == .Arabic
    }
}
