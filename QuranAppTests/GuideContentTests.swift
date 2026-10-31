//
//  GuideContentTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
import Core
@testable import QuranApp

final class GuideContentTests: XCTestCase {

    private var store: GuideContentStore!

    override func setUp() {
        super.setUp()
        store = GuideContentStore(bundle: .main)
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    private func content(_ key: GuideKey) throws -> GuideContent {
        try XCTUnwrap(store.content(for: key), "bundled guide pack missing: \(key.rawValue)")
    }
}

// MARK: - Bundled Resources

extension GuideContentTests {

    func testEveryGuideKeyResolvesToABundledPack() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)

            XCTAssertEqual(guide.key, key.rawValue)
            XCTAssertFalse(guide.dataVersion.isEmpty)
            XCTAssertTrue(store.isAvailable(key))
        }
    }

    func testUmrahPackShape() throws {
        let guide = try content(.umrah)

        XCTAssertEqual(guide.items.count, 73)
        XCTAssertEqual(guide.stages.count, 10)
        XCTAssertEqual(guide.headers.count, 4)
        XCTAssertTrue(guide.pages.isEmpty)
    }

    func testHajjPackShape() throws {
        let guide = try content(.hajj)

        XCTAssertEqual(guide.items.count, 105)
        XCTAssertEqual(guide.stages.count, 20)
        XCTAssertEqual(guide.headers.count, 5)
        XCTAssertEqual(guide.pages.count, 1)
    }

    func testMissingKeyResolvesToNil() {
        XCTAssertNil(store.content(forKey: "no_such_guide"))
    }

    func testPurgeKeepsContentResolvable() throws {
        _ = try content(.umrah)

        store.purge()

        XCTAssertNotNil(store.content(for: .umrah))
    }
}

// MARK: - Stage Coverage

extension GuideContentTests {

    func testNoItemPointsAtAMissingStage() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)
            let stageKeys = Set(guide.stages.map(\.key))
            let orphans = guide.items.filter { !stageKeys.contains($0.stageKey) }

            XCTAssertTrue(orphans.isEmpty,
                          "\(key.rawValue) has orphan items: \(orphans.map(\.id))")
        }
    }

    func testNoStageIsEmpty() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)
            let empty = guide.stages.filter { guide.items(forStage: $0.key).isEmpty }

            XCTAssertTrue(empty.isEmpty, "\(key.rawValue) has empty stages: \(empty.map(\.key))")
        }
    }

    func testStageKeysAreUnique() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)

            XCTAssertEqual(Set(guide.stages.map(\.key)).count, guide.stages.count)
        }
    }

    func testItemIdentifiersAreUnique() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)

            XCTAssertEqual(Set(guide.items.map(\.id)).count, guide.items.count)
        }
    }

    func testSectionListingExcludesSubstages() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)
            let listed = GuideSectionKind.allCases.flatMap { guide.stages(in: $0) }

            XCTAssertTrue(listed.allSatisfy { $0.parent == nil })
            XCTAssertEqual(listed.count, guide.stages.filter { $0.parent == nil }.count)
        }
    }

    func testEverySubstageIsReachableFromItsParent() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)
            let parents = guide.stages.filter { $0.parent == nil }
            let reachable = Set(parents.flatMap { guide.substages(of: $0) }.map(\.key))
            let declared = Set(guide.stages.filter { $0.parent != nil }.map(\.key))

            XCTAssertEqual(reachable, declared)
        }
    }

    func testUmrahMistakeStagesHangOffTheirRite() throws {
        let guide = try content(.umrah)
        let tawaf = try XCTUnwrap(guide.stages.first { $0.key == "tawaf" })

        XCTAssertEqual(guide.substages(of: tawaf).map(\.key), ["tawaf_mistakes"])
    }

    func testHajjSplitsJourneyAndLearnSections() throws {
        let guide = try content(.hajj)

        XCTAssertEqual(guide.stages(in: .journey).count, 13)
        XCTAssertEqual(guide.stages(in: .learn).count, 6)
    }

    func testUmrahSplitsJourneyAndLearnSections() throws {
        let guide = try content(.umrah)

        XCTAssertEqual(guide.stages(in: .journey).count, 4)
        XCTAssertEqual(guide.stages(in: .learn).count, 3)
    }
}

// MARK: - Headers And Pages

extension GuideContentTests {

    func testEveryGuideCarriesAnOverviewHeader() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)
            let overview = try XCTUnwrap(guide.overviewHeader, key.rawValue)

            XCTAssertEqual(overview.stage, "overview")
            XCTAssertFalse(overview.text.isEmpty)
            XCTAssertFalse(overview.source.isEmpty)
        }
    }

    func testHeaderLookupMatchesByStage() throws {
        let guide = try content(.umrah)
        let header = try XCTUnwrap(guide.header(forStage: "miqat"))

        XCTAssertEqual(header.stage, "miqat")
        XCTAssertFalse(header.subtitle.isEmpty)
    }

    func testHeaderLookupReturnsNilForAnUnheadedStage() throws {
        let guide = try content(.umrah)

        XCTAssertNil(guide.header(forStage: "sai_mistakes"))
    }

    func testHajjJourneySectionHeaderIsReachableBySectionName() throws {
        let guide = try content(.hajj)

        XCTAssertNotNil(guide.header(forStage: GuideSectionKind.journey.rawValue))
    }

    func testHajjTakbeerPageDecodes() throws {
        let guide = try content(.hajj)
        let page = try XCTUnwrap(guide.pages.first)

        XCTAssertEqual(page.slug, "dhul_hijjah_takbeer")
        XCTAssertEqual(page.id, page.slug)
        XCTAssertFalse(page.titleAr.isEmpty)
        XCTAssertFalse(page.bodyAr.isEmpty)
        XCTAssertFalse(page.displayTitle.isEmpty)
        XCTAssertFalse(page.displayBody.isEmpty)
    }
}

// MARK: - Item Decoding

extension GuideContentTests {

    func testEveryItemCarriesArabicBody() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)
            let blank = guide.items.filter { $0.bodyAr.isEmpty }

            XCTAssertTrue(blank.isEmpty, "\(key.rawValue) has empty bodies: \(blank.map(\.id))")
        }
    }

    func testSegmentsAreFlattenedWithoutLeakingMarkers() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)

            for item in guide.items {
                XCTAssertFalse(item.bodyAr.contains("\"k\""))
                XCTAssertFalse(item.bodyAr.hasPrefix("\n"))
                XCTAssertFalse(item.bodyAr.hasSuffix("\n"))
            }
        }
    }

    func testDisplayBodyFallsBackToArabicWhenEnglishIsMissing() throws {
        let guide = try content(.umrah)
        let item = try XCTUnwrap(guide.items.first { $0.bodyEn.isEmpty })

        XCTAssertEqual(item.displayBody, item.bodyAr)
    }

    func testDisplayBodyPrefersTheCurrentLanguage() throws {
        let guide = try content(.hajj)
        let item = try XCTUnwrap(guide.items.first { !$0.bodyEn.isEmpty && $0.bodyEn != $0.bodyAr })
        let arabic = LocalizationManager.shared.currentLanguage == .Arabic

        XCTAssertEqual(item.displayBody, arabic ? item.bodyAr : item.bodyEn)
    }

    func testStageTitleFallsBackToArabicWhenEnglishIsMissing() throws {
        let guide = try content(.hajj)

        for stage in guide.stages where stage.titleEn.isEmpty {
            XCTAssertEqual(stage.displayTitle, stage.titleAr)
        }
    }

    func testStageTitlesAreNeverBlank() throws {
        for key in GuideKey.allCases {
            let guide = try content(key)

            XCTAssertTrue(guide.stages.allSatisfy { !$0.displayTitle.isEmpty })
        }
    }

    func testUntitledItemsReportNoTitle() throws {
        let guide = try content(.umrah)
        let untitled = guide.items.filter { $0.titleAr.isEmpty && $0.titleEn.isEmpty }

        XCTAssertFalse(untitled.isEmpty)
        XCTAssertTrue(untitled.allSatisfy { !$0.hasTitle })
    }

    func testTitledItemsReportATitle() throws {
        let guide = try content(.umrah)
        let titled = guide.items.filter { !$0.titleAr.isEmpty }

        XCTAssertFalse(titled.isEmpty)
        XCTAssertTrue(titled.allSatisfy(\.hasTitle))
    }
}

// MARK: - Decoder Robustness

extension GuideContentTests {

    func testDecoderToleratesAMinimalPayload() throws {
        let json = Data(#"{"key":"tiny"}"#.utf8)

        let guide = try JSONDecoder().decode(GuideContent.self, from: json)

        XCTAssertEqual(guide.key, "tiny")
        XCTAssertTrue(guide.stages.isEmpty)
        XCTAssertTrue(guide.items.isEmpty)
        XCTAssertTrue(guide.headers.isEmpty)
        XCTAssertTrue(guide.pages.isEmpty)
        XCTAssertNil(guide.overviewHeader)
    }

    func testDecoderJoinsTextAndQuranSegmentsOnly() throws {
        let json = Data("""
        {"key":"tiny","items":[{"id":1,"variant":"s","segments":[
        {"k":"text","t":"first"},{"k":"note","t":"skipped"},
        {"k":"quran","t":"second"},{"k":"text","t":""}]}]}
        """.utf8)

        let guide = try JSONDecoder().decode(GuideContent.self, from: json)
        let item = try XCTUnwrap(guide.items.first)

        XCTAssertEqual(item.bodyAr, "first\n\nsecond")
        XCTAssertEqual(item.stageKey, "s")
    }

    func testStoreIgnoresABundleWithoutGuidePacks() {
        let empty = GuideContentStore(bundle: Bundle(for: GuideContentTests.self))

        XCTAssertNil(empty.content(for: .umrah))
        XCTAssertFalse(empty.isAvailable(.hajj))
    }
}

// MARK: - Detail View Model

@MainActor
final class GuideDetailViewModelTests: XCTestCase {

    private func makeViewModel(_ key: GuideKey) -> GuideDetailViewModel {
        GuideDetailViewModel(key: key, coordinator: nil)
    }

    func testLoadIsDeferredUntilOnAppear() {
        let viewModel = makeViewModel(.umrah)

        XCTAssertTrue(viewModel.sections.isEmpty)
        XCTAssertNil(viewModel.overview)
        XCTAssertFalse(viewModel.hasContent)
    }

    func testOnAppearBuildsBothSections() {
        let viewModel = makeViewModel(.umrah)

        viewModel.onAppear()

        XCTAssertTrue(viewModel.hasContent)
        XCTAssertNotNil(viewModel.overview)
        XCTAssertEqual(viewModel.sections.map(\.kind), [.journey, .learn])
    }

    func testEveryRenderedStageHasContent() {
        let viewModel = makeViewModel(.hajj)

        viewModel.onAppear()

        for section in viewModel.sections {
            XCTAssertFalse(section.title.isEmpty)
            XCTAssertFalse(section.stages.isEmpty)

            for stage in section.stages {
                XCTAssertFalse(stage.isEmpty)
                XCTAssertFalse(stage.title.isEmpty)
            }
        }
    }

    func testHajjExposesItsTakbeerPage() {
        let viewModel = makeViewModel(.hajj)

        viewModel.onAppear()

        XCTAssertEqual(viewModel.pages.map(\.slug), ["dhul_hijjah_takbeer"])
    }

    func testUmrahHasNoStandalonePages() {
        let viewModel = makeViewModel(.umrah)

        viewModel.onAppear()

        XCTAssertTrue(viewModel.pages.isEmpty)
    }

    func testSubstagesAreNestedNotPromoted() {
        let viewModel = makeViewModel(.umrah)

        viewModel.onAppear()

        let journey = viewModel.sections.first { $0.kind == .journey }
        let nested = journey?.stages.flatMap(\.substages).map(\.key) ?? []

        XCTAssertEqual(Set(nested), ["ihram_mistakes", "tawaf_mistakes", "sai_mistakes"])
        XCTAssertEqual(journey?.stages.count, 4)
        XCTAssertFalse(journey?.stages.contains { $0.key.hasSuffix("_mistakes") } ?? true)
    }

    func testRepeatedOnAppearDoesNotDuplicateSections() {
        let viewModel = makeViewModel(.hajj)

        viewModel.onAppear()
        let first = viewModel.sections.flatMap(\.stages).count
        viewModel.onAppear()

        XCTAssertEqual(viewModel.sections.flatMap(\.stages).count, first)
    }

    func testMarkdownIsRenderedWithoutLosingNewlines() {
        let viewModel = makeViewModel(.umrah)

        let rendered = viewModel.attributed("one **two**\nthree")

        XCTAssertEqual(String(rendered.characters), "one two\nthree")
    }

    func testPlainArabicTextPassesThroughUnchanged() {
        let viewModel = makeViewModel(.umrah)
        let raw = "plain ﴿ ayah ﴾ text"

        XCTAssertEqual(String(viewModel.attributed(raw).characters), raw)
    }

    func testLabelsAreLocalizedNotRawKeys() {
        let viewModel = makeViewModel(.hajj)

        XCTAssertFalse(viewModel.screenTitle.isEmpty)
        XCTAssertFalse(viewModel.screenSubtitle.isEmpty)
        XCTAssertNotEqual(viewModel.screenTitle, AppLocalizedKeys.contentHajjTitle.rawValue)
        XCTAssertNotEqual(viewModel.screenSubtitle, AppLocalizedKeys.contentHajjSubtitle.rawValue)
        XCTAssertNotEqual(viewModel.emptyMessage, AppLocalizedKeys.contentEmptyMessage.rawValue)
    }

    func testTabBarIsHiddenOnThisScreen() {
        XCTAssertFalse(makeViewModel(.umrah).isTabBarVisible)
    }
}

// MARK: - Hub View Model

@MainActor
final class ContentHubViewModelTests: XCTestCase {

    final class ContentCoordinatorSpy: ContentCoordinating {

        enum Call: Equatable {
            case guide(GuideKey)
            case back
        }

        private(set) var calls: [Call] = []

        func coordinateToGuide(_ key: GuideKey) { calls.append(.guide(key)) }

        func coordinateBack() { calls.append(.back) }
    }

    private var coordinator: ContentCoordinatorSpy!
    private var viewModel: ContentHubViewModel!

    override func setUp() {
        super.setUp()
        coordinator = ContentCoordinatorSpy()
        viewModel = ContentHubViewModel(coordinator: coordinator)
    }

    override func tearDown() {
        viewModel = nil
        coordinator = nil
        super.tearDown()
    }

    func testEntriesAreLoadedOnAppearOnly() {
        XCTAssertTrue(viewModel.entries.isEmpty)
        XCTAssertFalse(viewModel.hasEntries)

        viewModel.onAppear()

        XCTAssertEqual(viewModel.entries.map(\.key), [.umrah, .hajj])
        XCTAssertTrue(viewModel.hasEntries)
    }

    func testRepeatedOnAppearDoesNotDuplicateEntries() {
        viewModel.onAppear()
        viewModel.onAppear()

        XCTAssertEqual(viewModel.entries.count, 2)
    }

    func testEveryEntryIsFullyPopulated() {
        viewModel.onAppear()

        for entry in viewModel.entries {
            XCTAssertEqual(entry.id, entry.key.rawValue)
            XCTAssertFalse(entry.title.isEmpty)
            XCTAssertFalse(entry.subtitle.isEmpty)
            XCTAssertFalse(entry.icon.isEmpty)
            XCTAssertFalse(entry.topicsText.isEmpty)
        }
    }

    func testTopicCountReflectsTheBundledPack() throws {
        viewModel.onAppear()
        let umrah = try XCTUnwrap(viewModel.entries.first { $0.key == .umrah })

        XCTAssertTrue(umrah.topicsText.contains("73"))
    }

    func testEntryTapRoutesToThatGuide() {
        viewModel.onAppear()

        for entry in viewModel.entries {
            viewModel.onEntryTapped(entry)
        }

        XCTAssertEqual(coordinator.calls, [.guide(.umrah), .guide(.hajj)])
    }

    func testBackTapRoutesBackOnce() {
        viewModel.onBackTapped()

        XCTAssertEqual(coordinator.calls, [.back])
    }

    func testInitPerformsNoNavigation() {
        viewModel.onAppear()

        XCTAssertTrue(coordinator.calls.isEmpty)
    }

    func testAnEmptyStoreProducesNoDeadNavigation() {
        let empty = GuideContentStore(bundle: Bundle(for: ContentHubViewModelTests.self))
        let model = ContentHubViewModel(coordinator: coordinator, store: empty)

        model.onAppear()

        XCTAssertTrue(model.entries.isEmpty)
        XCTAssertFalse(model.hasEntries)
        XCTAssertFalse(model.emptyMessage.isEmpty)
    }

    func testLabelsAreLocalizedNotRawKeys() {
        XCTAssertNotEqual(viewModel.screenTitle, AppLocalizedKeys.contentTitle.rawValue)
        XCTAssertNotEqual(viewModel.screenSubtitle, AppLocalizedKeys.contentSubtitle.rawValue)
        XCTAssertNotEqual(viewModel.emptyMessage, AppLocalizedKeys.contentEmptyMessage.rawValue)
        XCTAssertFalse(viewModel.backAccessibilityLabel.isEmpty)
    }

    func testTabBarIsHiddenOnThisScreen() {
        XCTAssertFalse(viewModel.isTabBarVisible)
    }
}
