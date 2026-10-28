//
//  RecitersListViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation
import Core

final class RecitersListViewModel: MainViewModel {

    @Published var reciters: [ReciterInfo] = []
    @Published var isLoading: Bool = false

    let title: String = AppLocalizedKeys.recitations.value
    let subtitle: String = AppLocalizedKeys.recitationsSubtitle.value

    private weak var coordinator: RecitationsCoordinating?
    private var didRequestRefresh = false

    init(coordinator: RecitationsCoordinating) {
        self.coordinator = coordinator
    }

    // MARK: - Lifecycle

    func onAppear() {
        reciters = ReciterLibrary.all
        isLoading = reciters.isEmpty

        guard !didRequestRefresh else { return }
        didRequestRefresh = true
        Task { await refresh() }
    }

    // MARK: - Actions

    func onReciterTapped(_ reciter: ReciterInfo) {
        coordinator?.coordinateToReciterSurahs(reciter: reciter)
    }

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    // MARK: - Labels

    func detailText(for reciter: ReciterInfo) -> String {
        "\(reciter.bitrateKbps) kbps"
    }

    // MARK: - Loading

    @MainActor
    private func refresh() async {
        let fresh = await ReciterLibrary.refreshFromRemote()
        if !fresh.isEmpty { reciters = fresh }
        isLoading = false
    }
}
