//
//  QuranPageDownloadPromptViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import Foundation
import Combine
import Core

@MainActor
final class QuranPageDownloadPromptViewModel: ObservableObject {

    @Published private(set) var state: ContentDownloadState = .notDownloaded
    @Published private(set) var isRefreshingCatalog: Bool = false
    @Published private(set) var isWaitingForNetwork: Bool = false

    private let page: Int
    private let store: QuranImagePackStore
    private var cancellable: AnyCancellable?
    private var waitingCancellable: AnyCancellable?

    init(page: Int, store: QuranImagePackStore = .shared) {
        self.page = page
        self.store = store

        if let pack = store.pack(forPage: page) {
            state = store.state(for: pack)
        }

        cancellable = store.$states
            .receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                guard let self, let key = self.pack?.key else { return }
                let next = states[key] ?? .notDownloaded
                if next != self.state { self.state = next }
            }

        waitingCancellable = store.$waitingKeys
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keys in
                guard let self, let key = self.pack?.key else { return }
                let next = keys.contains(key)
                if next != self.isWaitingForNetwork { self.isWaitingForNetwork = next }
            }
    }

    private var pack: QuranImagePack? { store.pack(forPage: page) }
}

// MARK: - Presentation

extension QuranPageDownloadPromptViewModel {

    var title: String {
        pack == nil
            ? AppLocalizedKeys.quranPagePromptUnavailable.value
            : AppLocalizedKeys.quranPagePromptTitle.value
    }

    var detail: String {
        guard let pack else { return "" }
        let juz = AppLocalizedKeys.juzKey(pack.juz).value
        let pages = String(format: AppLocalizedKeys.quranDownloadsPagesFormat.value,
                           localizedNumber(pack.firstPage),
                           localizedNumber(pack.lastPage))
        return "\(juz) · \(pages)"
    }

    var message: String {
        guard pack != nil else { return "" }

        switch state {
        case .notDownloaded:      return AppLocalizedKeys.quranPagePromptBody.value
        case .downloading:        return isWaitingForNetwork
                                      ? AppLocalizedKeys.quranPagePromptWaitingNetwork.value
                                      : AppLocalizedKeys.quranPagePromptDownloading.value
        case .installing:         return AppLocalizedKeys.quranPagePromptInstalling.value
        case .downloaded:         return ""
        case let .failed(reason): return failureMessage(reason)
        }
    }

    var actionTitle: String {
        guard let pack else { return AppLocalizedKeys.quranPagePromptRetry.value }

        switch state {
        case .notDownloaded:
            return String(format: AppLocalizedKeys.quranPagePromptDownloadFormat.value,
                          pack.archiveSizeLabel)
        case .downloading:
            return AppLocalizedKeys.quranPagePromptCancel.value
        case .failed:
            return AppLocalizedKeys.quranPagePromptRetry.value
        case .installing, .downloaded:
            return ""
        }
    }

    var iconName: String {
        guard pack != nil else { return "book.closed" }

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

    private func failureMessage(_ reason: ContentDownloadFailure) -> String {
        switch reason {
        case .noSpace:
            return AppLocalizedKeys.quranPagePromptNoSpace.value
        case .unavailable, .corrupt, .transfer:
            return AppLocalizedKeys.quranPagePromptFailed.value
        }
    }

    private var isArabic: Bool { LocalizationManager.shared.currentLanguage == .Arabic }

    private func localizedNumber(_ value: Int) -> String {
        isArabic ? value.arabicNumerals : "\(value)"
    }
}

// MARK: - Actions

extension QuranPageDownloadPromptViewModel {

    func onAppear() {
        guard pack == nil else { return }
        refreshCatalog()
    }

    func onActionTapped() {
        guard let pack else {
            refreshCatalog()
            return
        }

        switch state {
        case .notDownloaded, .failed:
            store.download(pack)
        case .downloading:
            store.cancel(juz: pack.juz)
        case .installing, .downloaded:
            break
        }
    }

    private func refreshCatalog() {
        guard !isRefreshingCatalog else { return }
        isRefreshingCatalog = true

        Task { [weak self] in
            await self?.store.refreshCatalog()
            self?.isRefreshingCatalog = false
        }
    }
}
