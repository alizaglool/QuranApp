//
//  GuideDetailViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import SwiftUI
import Core

struct GuideDetailStage: Identifiable {
    let key: String
    let title: String
    let header: GuideHeader?
    let items: [GuideItem]
    let substages: [GuideDetailStage]

    var id: String { key }

    var isEmpty: Bool { items.isEmpty && substages.allSatisfy(\.isEmpty) }
}

struct GuideDetailSection: Identifiable {
    let kind: GuideSectionKind
    let title: String
    let header: GuideHeader?
    let stages: [GuideDetailStage]

    var id: String { kind.rawValue }
}

@MainActor
final class GuideDetailViewModel: MainViewModel {

    // MARK: - Output

    @Published private(set) var overview: GuideHeader?
    @Published private(set) var sections: [GuideDetailSection] = []
    @Published private(set) var pages: [GuidePage] = []

    private let key: GuideKey
    private let store: GuideContentStore

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
        case .umrah:    return AppLocalizedKeys.contentUmrahTitle.value
        case .hajj:     return AppLocalizedKeys.contentHajjTitle.value
        }
    }

    var screenSubtitle: String {
        switch key {
        case .umrah:    return AppLocalizedKeys.contentUmrahSubtitle.value
        case .hajj:     return AppLocalizedKeys.contentHajjSubtitle.value
        }
    }

    var backAccessibilityLabel: String { AppLocalizedKeys.back.value }

    var emptyMessage: String { AppLocalizedKeys.contentEmptyMessage.value }

    var hasContent: Bool { overview != nil || !sections.isEmpty || !pages.isEmpty }

    // MARK: - Lifecycle

    func onAppear() {
        guard sections.isEmpty, pages.isEmpty, overview == nil else { return }
        load()
    }

    // MARK: - Actions

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    // MARK: - Markdown

    func attributed(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        guard let parsed = try? AttributedString(markdown: text, options: options) else {
            return AttributedString(text)
        }
        return parsed
    }

    // MARK: - Loading

    private func load() {
        guard let content = store.content(for: key) else { return }

        overview = content.overviewHeader
        sections = GuideSectionKind.allCases.compactMap { section(kind: $0, in: content) }
        pages = content.pages
    }

    private func section(kind: GuideSectionKind, in content: GuideContent) -> GuideDetailSection? {
        let stages = content.stages(in: kind).map { stage(from: $0, in: content) }
            .filter { !$0.isEmpty }
        guard !stages.isEmpty else { return nil }

        return GuideDetailSection(kind: kind,
                                  title: title(for: kind),
                                  header: content.header(forStage: kind.rawValue),
                                  stages: stages)
    }

    private func stage(from stage: GuideStage, in content: GuideContent) -> GuideDetailStage {
        GuideDetailStage(key: stage.key,
                         title: stage.displayTitle,
                         header: content.header(forStage: stage.key),
                         items: content.items(forStage: stage.key),
                         substages: content.substages(of: stage).map {
                             GuideDetailStage(key: $0.key,
                                              title: $0.displayTitle,
                                              header: content.header(forStage: $0.key),
                                              items: content.items(forStage: $0.key),
                                              substages: [])
                         })
    }

    private func title(for kind: GuideSectionKind) -> String {
        switch kind {
        case .journey:  return AppLocalizedKeys.contentSectionJourney.value
        case .learn:    return AppLocalizedKeys.contentSectionLearn.value
        }
    }
}
