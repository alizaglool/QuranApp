//
//  AthkarAudioPromptViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import Foundation
import Combine
import Core

@MainActor
final class AthkarAudioPromptViewModel: ObservableObject {

    // MARK: - Output

    @Published private(set) var state: AthkarAudioState = .notDownloaded
    @Published private(set) var isWaitingForNetwork = false
    @Published private(set) var isOnline = true

    let pack: AthkarPack

    private let downloads: AthkarAudioDownloadManager
    private let reachability = NetworkReachability.shared
    private var installedState: AthkarAudioState = .notDownloaded
    private var cancellables = Set<AnyCancellable>()

    init(pack: AthkarPack, downloads: AthkarAudioDownloadManager = .shared) {
        self.pack = pack
        self.downloads = downloads

        installedState = downloads.state(for: pack)
        state = installedState
        isWaitingForNetwork = downloads.isWaitingForNetwork(pack.key)
        isOnline = reachability.isOnline

        observe()
    }

    // MARK: - Observation

    private func observe() {
        downloads.$states
            .receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                guard let self else { return }
                let next = states[self.pack.key] ?? self.installedState
                if next != self.state { self.state = next }
            }
            .store(in: &cancellables)

        downloads.$waitingKeys
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keys in
                guard let self else { return }
                let next = keys.contains(self.pack.key)
                if next != self.isWaitingForNetwork { self.isWaitingForNetwork = next }
            }
            .store(in: &cancellables)

        reachability.$isOnline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] online in
                guard let self, self.isOnline != online else { return }
                self.isOnline = online
            }
            .store(in: &cancellables)
    }
}

// MARK: - Presentation

extension AthkarAudioPromptViewModel {

    var title: String { AppLocalizedKeys.athkarAudioPromptTitle.value }

    var detail: String {
        let countKey: AppLocalizedKeys = pack.kind == .list ? .athkarDuaaCount : .adhkarCount
        let count = String(format: countKey.value, pack.itemCount)
        return "\(pack.name) · \(count)"
    }

    var message: String {
        switch state {
        case .notDownloaded:
            return isOnline
                ? AppLocalizedKeys.athkarAudioPromptBody.value
                : AppLocalizedKeys.athkarAudioPromptOffline.value
        case .downloading:
            return isWaitingForNetwork
                ? AppLocalizedKeys.athkarAudioPromptWaitingNetwork.value
                : AppLocalizedKeys.athkarAudioPromptDownloading.value
        case .installing:
            return AppLocalizedKeys.athkarAudioPromptInstalling.value
        case .downloaded:
            return ""
        case let .failed(reason):
            return failureMessage(reason)
        }
    }

    var actionTitle: String {
        switch state {
        case .notDownloaded:
            return String(format: AppLocalizedKeys.athkarAudioPromptDownloadFormat.value,
                          pack.archiveSizeLabel)
        case .downloading:
            return AppLocalizedKeys.cancelDownload.value
        case .failed:
            return AppLocalizedKeys.retryAction.value
        case .installing, .downloaded:
            return ""
        }
    }

    var secondaryTitle: String { AppLocalizedKeys.athkarAudioPromptReadWithout.value }

    var iconName: String {
        if !isOnline, !state.isBusy { return "wifi.slash" }
        if isWaitingForNetwork, state.isBusy { return "wifi.slash" }

        switch state {
        case .failed: return "exclamationmark.triangle"
        default:      return "arrow.down.circle"
        }
    }

    var progress: Double? {
        guard case let .downloading(value) = state, !isWaitingForNetwork else { return nil }
        return value
    }

    var isInstalling: Bool { state == .installing }

    var isActionVisible: Bool { !isInstalling && !actionTitle.isEmpty }

    var isActionEnabled: Bool { isOnline || state.isBusy }

    var isSecondaryVisible: Bool { state != .downloaded }

    private func failureMessage(_ reason: AthkarAudioFailure) -> String {
        switch reason {
        case .noSpace:
            return AppLocalizedKeys.athkarAudioPromptNoSpace.value
        case .unavailable, .corrupt, .transfer:
            return isOnline
                ? AppLocalizedKeys.athkarAudioPromptFailed.value
                : AppLocalizedKeys.athkarAudioPromptOffline.value
        }
    }
}

// MARK: - Actions

extension AthkarAudioPromptViewModel {

    func onActionTapped() {
        switch state {
        case .notDownloaded, .failed:
            guard isOnline else { return }
            downloads.download(pack: pack)
        case .downloading:
            downloads.cancel(key: pack.key)
        case .installing, .downloaded:
            break
        }
    }
}
