//
//  ContentHubViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - ContentHubEntry

struct ContentHubEntry: Identifiable {
    let key: GuideKey
    let title: String
    let subtitle: String
    let icon: String
    let accent: ColorStyle
    let topicsText: String

    var id: String { key.rawValue }
}

// MARK: - ContentHubViewModel

@MainActor
final class ContentHubViewModel: MainViewModel {

    // MARK: - Output

    @Published private(set) var entries: [ContentHubEntry] = []

    private let store: GuideContentStore

    weak var coordinator: ContentCoordinating?

    var isTabBarVisible: Bool { false }

    init(coordinator: ContentCoordinating?, store: GuideContentStore = .shared) {
        self.coordinator = coordinator
        self.store = store
    }

    // MARK: - Strings

    var screenTitle: String { AppLocalizedKeys.contentTitle.value }

    var screenSubtitle: String { AppLocalizedKeys.contentSubtitle.value }

    var backAccessibilityLabel: String { AppLocalizedKeys.back.value }

    var emptyMessage: String { AppLocalizedKeys.contentEmptyMessage.value }

    var hasEntries: Bool { !entries.isEmpty }

    // MARK: - Lifecycle

    func onAppear() {
        guard entries.isEmpty else { return }
        loadEntries()
    }

    // MARK: - Actions

    func onEntryTapped(_ entry: ContentHubEntry) {
        coordinator?.coordinateToGuide(entry.key)
    }

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    // MARK: - Loading

    private func loadEntries() {
        entries = GuideKey.allCases.compactMap { key in
            guard let content = store.content(for: key), !content.items.isEmpty else { return nil }
            return ContentHubEntry(key: key,
                                   title: title(for: key),
                                   subtitle: subtitle(for: key),
                                   icon: icon(for: key),
                                   accent: .quickAccentContent,
                                   topicsText: topicsText(count: content.items.count))
        }
    }

    private func title(for key: GuideKey) -> String {
        switch key {
        case .umrah: return AppLocalizedKeys.contentUmrahTitle.value
        case .hajj:  return AppLocalizedKeys.contentHajjTitle.value
        }
    }

    private func subtitle(for key: GuideKey) -> String {
        switch key {
        case .umrah: return AppLocalizedKeys.contentUmrahSubtitle.value
        case .hajj:  return AppLocalizedKeys.contentHajjSubtitle.value
        }
    }

    private func icon(for key: GuideKey) -> String {
        switch key {
        case .umrah: return "figure.walk"
        case .hajj:  return "mountain.2.fill"
        }
    }

    private func topicsText(count: Int) -> String {
        String(format: AppLocalizedKeys.contentTopicsCount.value, count)
    }
}
