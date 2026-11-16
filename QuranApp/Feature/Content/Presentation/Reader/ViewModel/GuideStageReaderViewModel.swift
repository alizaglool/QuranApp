//
//  GuideStageReaderViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

@MainActor
final class GuideStageReaderViewModel: MainViewModel {

    // MARK: - Output

    @Published var pageIndex: Int

    private let key: GuideKey
    private let store: GuideContentStore

    @Published private(set) var plan = GuideReaderPlan()

    weak var coordinator: ContentCoordinating?

    var isTabBarVisible: Bool { false }

    init(key: GuideKey,
         pageIndex: Int = 0,
         coordinator: ContentCoordinating?,
         store: GuideContentStore = .shared) {
        self.key = key
        self.pageIndex = pageIndex
        self.coordinator = coordinator
        self.store = store
    }

    // MARK: - Pages

    var pages: [GuideReaderPage] { plan.pages }

    var currentPage: GuideReaderPage? {
        guard plan.pages.indices.contains(pageIndex) else { return nil }
        return plan.pages[pageIndex]
    }

    // MARK: - Strings

    var screenTitle: String {
        switch key {
        case .umrah:    return AppLocalizedKeys.ritesUmrahTitle.value
        case .hajj:     return AppLocalizedKeys.ritesHajjTitle.value
        }
    }

    var backAccessibilityLabel: String { AppLocalizedKeys.back.value }

    var previousTitle: String { AppLocalizedKeys.ritesPrevious.value }

    var nextTitle: String { AppLocalizedKeys.ritesNext.value }

    var emptyMessage: String { AppLocalizedKeys.ritesEmptyMessage.value }

    var positionText: String {
        guard !plan.pages.isEmpty else { return "" }
        return String(format: AppLocalizedKeys.ritesPagePosition.value,
                      GuideReaderPlan.numeral(pageIndex + 1),
                      GuideReaderPlan.numeral(plan.pages.count))
    }

    var progress: Double {
        guard !plan.pages.isEmpty else { return 0 }
        return Double(pageIndex + 1) / Double(plan.pages.count)
    }

    var hasContent: Bool { !plan.pages.isEmpty }

    var canGoPrevious: Bool { pageIndex > 0 }

    var canGoNext: Bool { pageIndex + 1 < plan.pages.count }

    // MARK: - Lifecycle

    func onAppear() {
        guard plan.isEmpty else { return }
        load()
    }

    // MARK: - Actions

    func onPreviousTapped() {
        guard canGoPrevious else { return }
        pageIndex -= 1
    }

    func onNextTapped() {
        guard canGoNext else { return }
        pageIndex += 1
    }

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    // MARK: - Loading

    private func load() {
        guard let content = store.content(for: key) else { return }
        plan = GuideReaderPlan(content: content)
        pageIndex = min(max(pageIndex, 0), max(plan.pages.count - 1, 0))
    }
}
