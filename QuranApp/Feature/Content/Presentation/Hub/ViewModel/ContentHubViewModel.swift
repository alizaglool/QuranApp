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
    let wash: ColorStyle
    let metrics: [GuideMetric]

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

    var screenTitle: String { AppLocalizedKeys.ritesTitle.value }

    var screenSubtitle: String { AppLocalizedKeys.ritesSubtitle.value }

    var screenIntro: String { AppLocalizedKeys.ritesIntro.value }

    var backAccessibilityLabel: String { AppLocalizedKeys.back.value }

    var emptyMessage: String { AppLocalizedKeys.ritesEmptyMessage.value }

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
                                   accent: accent(for: key),
                                   wash: wash(for: key),
                                   metrics: metrics(for: content))
        }
    }

    private func title(for key: GuideKey) -> String {
        switch key {
        case .umrah: return AppLocalizedKeys.ritesUmrahTitle.value
        case .hajj:  return AppLocalizedKeys.ritesHajjTitle.value
        }
    }

    private func subtitle(for key: GuideKey) -> String {
        switch key {
        case .umrah: return AppLocalizedKeys.ritesUmrahSubtitle.value
        case .hajj:  return AppLocalizedKeys.ritesHajjSubtitle.value
        }
    }

    private func icon(for key: GuideKey) -> String {
        switch key {
        case .umrah: return "figure.walk"
        case .hajj:  return "mountain.2.fill"
        }
    }

    private func accent(for key: GuideKey) -> ColorStyle {
        switch key {
        case .umrah: return .primary
        case .hajj:  return .secondary
        }
    }

    private func wash(for key: GuideKey) -> ColorStyle {
        switch key {
        case .umrah: return .washPrimary
        case .hajj:  return .washSecondaryCard
        }
    }

    private func metrics(for content: GuideContent) -> [GuideMetric] {
        let stages = content.stages(in: .journey).count
        return [metric(label: AppLocalizedKeys.ritesStagesLabel.value, count: stages),
                metric(label: AppLocalizedKeys.ritesTopicsLabel.value, count: content.items.count)]
    }

    private func metric(label: String, count: Int) -> GuideMetric {
        GuideMetric(label: label, value: GuideReaderPlan.numeral(count))
    }
}
