//
//  GuideReaderPlan.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - GuideMetric

struct GuideMetric: Hashable {
    let label: String
    let value: String
}

// MARK: - GuideReaderNote

struct GuideReaderNote: Hashable {
    let subtitle: String
    let blocks: [GuideTextBlock]
    let source: String

    var hasSubtitle: Bool { !subtitle.isEmpty }
    var hasSource: Bool { !source.isEmpty }

    init(header: GuideHeader) {
        subtitle = header.subtitle
        blocks = GuideTextParser.blocks(from: header.text)
        source = header.source
    }
}

// MARK: - GuideReaderStep

struct GuideReaderStep: Identifiable, Hashable {
    let id: String
    let marker: String
    let title: String
    let blocks: [GuideTextBlock]
    let source: String

    var hasMarker: Bool { !marker.isEmpty }
    var hasTitle: Bool { !title.isEmpty }
    var hasSource: Bool { !source.isEmpty }
}

// MARK: - GuideReaderGroup

struct GuideReaderGroup: Identifiable, Hashable {
    let id: String
    let title: String
    let note: GuideReaderNote?
    let steps: [GuideReaderStep]
}

// MARK: - GuideReaderPage

struct GuideReaderPage: Identifiable, Hashable {
    let id: String
    let sectionTitle: String
    let marker: String
    let title: String
    let note: GuideReaderNote?
    let steps: [GuideReaderStep]
    let groups: [GuideReaderGroup]

    var hasMarker: Bool { !marker.isEmpty }

    var stepCount: Int {
        steps.count + groups.reduce(0) { $0 + $1.steps.count }
    }

    var isEmpty: Bool {
        note == nil && steps.isEmpty && groups.allSatisfy { $0.steps.isEmpty }
    }
}

// MARK: - GuideReaderSection

struct GuideReaderSection: Identifiable, Hashable {
    let id: String
    let title: String
    let pageIndices: [Int]
}

// MARK: - GuideReaderPlan

struct GuideReaderPlan {

    let overviewNote: GuideReaderNote?
    let pages: [GuideReaderPage]
    let sections: [GuideReaderSection]

    var isEmpty: Bool { overviewNote == nil && pages.isEmpty }

    // MARK: - Init

    init() {
        overviewNote = nil
        pages = []
        sections = []
    }

    init(content: GuideContent) {
        overviewNote = content.overviewHeader.map(GuideReaderNote.init)

        var pages: [GuideReaderPage] = []
        var sections: [GuideReaderSection] = []

        for kind in GuideSectionKind.allCases {
            let first = pages.count
            for (offset, stage) in content.stages(in: kind).enumerated() {
                let page = Self.page(for: stage,
                                     in: content,
                                     sectionTitle: Self.title(for: kind),
                                     marker: kind == .journey ? Self.numeral(offset + 1) : "")
                guard !page.isEmpty else { continue }
                pages.append(page)
            }
            guard pages.count > first else { continue }
            sections.append(GuideReaderSection(id: kind.rawValue,
                                               title: Self.title(for: kind),
                                               pageIndices: Array(first..<pages.count)))
        }

        let firstExtra = pages.count
        for page in content.pages {
            pages.append(Self.page(for: page, sectionTitle: Self.extrasTitle))
        }
        if pages.count > firstExtra {
            sections.append(GuideReaderSection(id: "extras",
                                               title: Self.extrasTitle,
                                               pageIndices: Array(firstExtra..<pages.count)))
        }

        self.pages = pages
        self.sections = sections
    }

    // MARK: - Pages

    private static func page(for stage: GuideStage,
                             in content: GuideContent,
                             sectionTitle: String,
                             marker: String) -> GuideReaderPage {
        let substages = content.substages(of: stage)
        return GuideReaderPage(id: stage.key,
                               sectionTitle: sectionTitle,
                               marker: marker,
                               title: stage.displayTitle,
                               note: content.header(forStage: stage.key).map(GuideReaderNote.init),
                               steps: steps(forStage: stage.key, in: content),
                               groups: substages.map { substage in
                                   GuideReaderGroup(id: substage.key,
                                                    title: substage.displayTitle,
                                                    note: content.header(forStage: substage.key).map(GuideReaderNote.init),
                                                    steps: steps(forStage: substage.key, in: content))
                               })
    }

    private static func page(for page: GuidePage, sectionTitle: String) -> GuideReaderPage {
        GuideReaderPage(id: "page.\(page.slug)",
                        sectionTitle: sectionTitle,
                        marker: "",
                        title: page.displayTitle,
                        note: nil,
                        steps: [GuideReaderStep(id: page.slug,
                                                marker: "",
                                                title: "",
                                                blocks: GuideTextParser.blocks(from: page.displayBody),
                                                source: "")],
                        groups: [])
    }

    // MARK: - Steps

    private static func steps(forStage stage: String, in content: GuideContent) -> [GuideReaderStep] {
        let items = content.items(forStage: stage)
        let numbered = !GuideTextParser.carriesOwnNumbering(items.flatMap { [$0.displayTitle, $0.displayBody] })

        return items.enumerated().map { offset, item in
            GuideReaderStep(id: "\(stage).\(item.id)",
                            marker: numbered ? numeral(offset + 1) : "",
                            title: item.displayTitle,
                            blocks: GuideTextParser.blocks(from: item.displayBody),
                            source: item.source)
        }
    }

    // MARK: - Strings

    private static var extrasTitle: String { AppLocalizedKeys.ritesSectionExtras.value }

    private static func title(for kind: GuideSectionKind) -> String {
        switch kind {
        case .journey:  return AppLocalizedKeys.ritesSectionJourney.value
        case .learn:    return AppLocalizedKeys.ritesSectionLearn.value
        }
    }

    static func numeral(_ value: Int) -> String {
        LocalizationManager.shared.currentLanguage == .Arabic ? value.arabicNumerals : "\(value)"
    }
}
