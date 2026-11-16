//
//  GuideDetailViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - GuideIndexRow

struct GuideIndexRow: Identifiable {
    let id: String
    let pageIndex: Int
    let marker: String
    let title: String
    let detail: GuideMetric?

    var hasMarker: Bool { !marker.isEmpty }
}

// MARK: - GuideIndexSection

struct GuideIndexSection: Identifiable {
    let id: String
    let title: String
    let rows: [GuideIndexRow]
}

// MARK: - GuideDetailViewModel

@MainActor
final class GuideDetailViewModel: MainViewModel {

    // MARK: - Output

    @Published private(set) var overview: GuideReaderNote?
    @Published private(set) var sections: [GuideIndexSection] = []

    private let key: GuideKey
    private let store: GuideContentStore

    private var plan = GuideReaderPlan()

    var isTabBarVisible: Bool { false }

    weak var coordinator: ContentCoordinating?

    init(key: GuideKey, coordinator: ContentCoordinating?, store: GuideContentStore = .shared) {
        self.key = key
        self.coordinator = coordinator
        self.store = store
    }

    // MARK: - Strings

    var screenTitle: String {
        switch key {
        case .umrah:    return AppLocalizedKeys.ritesUmrahTitle.value
        case .hajj:     return AppLocalizedKeys.ritesHajjTitle.value
        }
    }

    var screenSubtitle: String {
        switch key {
        case .umrah:    return AppLocalizedKeys.ritesUmrahSubtitle.value
        case .hajj:     return AppLocalizedKeys.ritesHajjSubtitle.value
        }
    }

    var overviewTitle: String { AppLocalizedKeys.ritesOverviewTitle.value }

    var startTitle: String { AppLocalizedKeys.ritesStartJourney.value }

    var backAccessibilityLabel: String { AppLocalizedKeys.back.value }

    var emptyMessage: String { AppLocalizedKeys.ritesEmptyMessage.value }

    var hasContent: Bool { overview != nil || !sections.isEmpty }

    var canStart: Bool { !plan.pages.isEmpty }

    // MARK: - Lifecycle

    func onAppear() {
        guard plan.isEmpty else { return }
        load()
    }

    // MARK: - Actions

    func onStartTapped() {
        guard canStart else { return }
        coordinator?.coordinateToReader(key: key, pageIndex: 0)
    }

    func onRowTapped(_ row: GuideIndexRow) {
        coordinator?.coordinateToReader(key: key, pageIndex: row.pageIndex)
    }

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    // MARK: - Loading

    private func load() {
        guard let content = store.content(for: key) else { return }

        plan = GuideReaderPlan(content: content)
        overview = plan.overviewNote
        sections = plan.sections.map { section in
            GuideIndexSection(id: section.id,
                              title: section.title,
                              rows: section.pageIndices.map(row(atPage:)))
        }
    }

    private func row(atPage index: Int) -> GuideIndexRow {
        let page = plan.pages[index]
        return GuideIndexRow(id: page.id,
                             pageIndex: index,
                             marker: page.marker,
                             title: page.title,
                             detail: stepsDetail(count: page.stepCount))
    }

    private func stepsDetail(count: Int) -> GuideMetric? {
        guard count > 0 else { return nil }
        return GuideMetric(label: AppLocalizedKeys.ritesStepsLabel.value,
                           value: GuideReaderPlan.numeral(count))
    }
}
