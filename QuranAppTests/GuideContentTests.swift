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

// MARK: - Text Parser

final class GuideTextParserTests: XCTestCase {

    private var store: GuideContentStore!

    override func setUp() {
        super.setUp()
        store = GuideContentStore(bundle: .main)
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    private func normalised(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func everyBundledBody() throws -> [String] {
        var bodies: [String] = []
        for key in GuideKey.allCases {
            let content = try XCTUnwrap(store.content(for: key), key.rawValue)
            bodies += content.items.flatMap { [$0.titleAr, $0.titleEn, $0.bodyAr, $0.bodyEn] }
            bodies += content.headers.map(\.text)
            bodies += content.pages.flatMap { [$0.bodyAr, $0.bodyEn] }
        }
        return bodies.filter { !normalised($0).isEmpty }
    }

    func testEveryBundledBodySurvivesParsingWordForWord() throws {
        let bodies = try everyBundledBody()

        XCTAssertGreaterThan(bodies.count, 300)

        for body in bodies {
            let rebuilt = GuideTextParser.blocks(from: body)
                .map { block -> String in
                    switch block.segment {
                    case .revelation(let text, let reference): return text + " " + reference
                    default:                                   return block.segment.text
                    }
                }
                .joined(separator: " ")

            XCTAssertEqual(normalised(rebuilt), normalised(body))
        }
    }

    func testEveryBundledBodyProducesAtLeastOneBlock() throws {
        for body in try everyBundledBody() {
            XCTAssertFalse(GuideTextParser.blocks(from: body).isEmpty)
        }
    }

    func testBlockIndicesAreContiguous() throws {
        for body in try everyBundledBody() {
            let blocks = GuideTextParser.blocks(from: body)
            XCTAssertEqual(blocks.map(\.index), Array(0..<blocks.count))
        }
    }

    func testPlainProseIsASingleInstructionBlock() {
        let blocks = GuideTextParser.blocks(from: "اغتسل ثم ألبس الإحرام")

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks.first?.segment, .instruction("اغتسل ثم ألبس الإحرام"))
    }

    func testEmphasisedLineFollowedByProseIsAHeading() {
        let blocks = GuideTextParser.blocks(from: "**التكبير المطلق**\nيبدأ من أول ذي الحجة.")

        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks.first?.segment, .heading("التكبير المطلق"))
        XCTAssertEqual(blocks.last?.segment, .instruction("يبدأ من أول ذي الحجة."))
    }

    func testEmphasisedLineFollowedByABlankLineStaysASupplication() {
        let blocks = GuideTextParser.blocks(from: "**لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ**\n\nثم تطوف بالبيت.")

        XCTAssertEqual(blocks.count, 2)
        XCTAssertEqual(blocks.first?.segment, .supplication("لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ"))
        XCTAssertEqual(blocks.last?.segment, .instruction("ثم تطوف بالبيت."))
    }

    func testOnlyTheTakbeerSubheadingsAreClassifiedAsHeadingsInTheBundledPacks() throws {
        var headings: [String] = []

        for body in try everyBundledBody() {
            headings += GuideTextParser.blocks(from: body).compactMap { block in
                guard case .heading(let text) = block.segment else { return nil }
                return text
            }
        }

        XCTAssertEqual(headings, ["التكبير المطلق",
                                  "التكبير المقيّد",
                                  "Unrestricted Takbir",
                                  "Restricted Takbir"])
    }

    func testEveryBundledSupplicationKeepsItsSupplicationTreatment() throws {
        var supplications = 0

        for body in try everyBundledBody() {
            supplications += GuideTextParser.blocks(from: body).filter { block in
                if case .supplication = block.segment { return true }
                return false
            }.count
        }

        XCTAssertEqual(supplications, 41)
    }

    func testFullyEmphasisedLineIsASupplication() {
        let blocks = GuideTextParser.blocks(from: "**لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ**")

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks.first?.segment, .supplication("لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ"))
    }

    func testInlineEmphasisStaysInsideTheInstruction() {
        let blocks = GuideTextParser.blocks(from: "قل **لبيك** ثم امض")

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks.first?.segment, .instruction("قل **لبيك** ثم امض"))
    }

    func testRevelationKeepsItsReferenceSeparately() {
        let blocks = GuideTextParser.blocks(from: "﴿وَأَتِمُّوا الْحَجَّ﴾ «البقرة:١٩٦»")

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks.first?.segment, .revelation(text: "﴿وَأَتِمُّوا الْحَجَّ﴾",
                                                          reference: "«البقرة:١٩٦»"))
    }

    func testRevelationWithoutAReferenceKeepsAnEmptyReference() {
        let blocks = GuideTextParser.blocks(from: "﴿وَأَتِمُّوا الْحَجَّ﴾")

        XCTAssertEqual(blocks.first?.segment, .revelation(text: "﴿وَأَتِمُّوا الْحَجَّ﴾", reference: ""))
    }

    func testQuotedLineIsNarration() {
        let blocks = GuideTextParser.blocks(from: "«خذوا عني مناسككم»")

        XCTAssertEqual(blocks.first?.segment, .narration("«خذوا عني مناسككم»"))
    }

    func testAdjacentLinesOfTheSameKindMerge() {
        let blocks = GuideTextParser.blocks(from: "**سبحان الله**\n**والحمد لله**")

        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks.first?.segment, .supplication("سبحان الله\nوالحمد لله"))
    }

    func testMixedLinesSplitInSourceOrder() {
        let blocks = GuideTextParser.blocks(from: "ثم قل:\n**لبيك اللهم لبيك**\n\nثم امض إلى الحرم")

        XCTAssertEqual(blocks.count, 3)
        XCTAssertEqual(blocks[0].segment, .instruction("ثم قل:"))
        XCTAssertEqual(blocks[1].segment, .supplication("لبيك اللهم لبيك"))
        XCTAssertEqual(blocks[2].segment, .instruction("ثم امض إلى الحرم"))
    }

    func testMarkdownIsRenderedWithoutLosingNewlines() {
        XCTAssertEqual(String(GuideTextParser.attributed("one **two**\nthree").characters),
                       "one two\nthree")
    }

    func testPlainArabicTextPassesThroughUnchanged() {
        let raw = "plain ﴿ ayah ﴾ text"

        XCTAssertEqual(String(GuideTextParser.attributed(raw).characters), raw)
    }

    func testSelfNumberedTextIsDetected() {
        XCTAssertTrue(GuideTextParser.carriesOwnNumbering(["1. الإحرام من الميقات:"]))
        XCTAssertTrue(GuideTextParser.carriesOwnNumbering(["لا رقم هنا", "2) الحلق أو التقصير"]))
        XCTAssertFalse(GuideTextParser.carriesOwnNumbering(["الإحرام من الميقات"]))
        XCTAssertFalse(GuideTextParser.carriesOwnNumbering(["١٩٦ البقرة"]))
    }

    func testUmrahDutiesCarryTheirOwnNumbering() throws {
        let content = try XCTUnwrap(store.content(for: .umrah))
        let texts = content.items(forStage: "duties").flatMap { [$0.displayTitle, $0.displayBody] }

        XCTAssertTrue(GuideTextParser.carriesOwnNumbering(texts))
    }
}

// MARK: - Journey Index View Model

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
        XCTAssertFalse(viewModel.canStart)
    }

    func testUmrahIndexSplitsJourneyAndLearnOnly() {
        let viewModel = makeViewModel(.umrah)

        viewModel.onAppear()

        XCTAssertTrue(viewModel.hasContent)
        XCTAssertTrue(viewModel.canStart)
        XCTAssertNotNil(viewModel.overview)
        XCTAssertEqual(viewModel.sections.map(\.id), ["journey", "learn"])
    }

    func testHajjIndexAddsAnExtrasSectionForItsStandalonePage() {
        let viewModel = makeViewModel(.hajj)

        viewModel.onAppear()

        XCTAssertEqual(viewModel.sections.map(\.id), ["journey", "learn", "extras"])
        XCTAssertEqual(viewModel.sections.last?.rows.map(\.id), ["page.dhul_hijjah_takbeer"])
    }

    func testEveryRowIsFullyPopulated() {
        let viewModel = makeViewModel(.hajj)

        viewModel.onAppear()

        for section in viewModel.sections {
            XCTAssertFalse(section.title.isEmpty)
            XCTAssertFalse(section.rows.isEmpty)

            for row in section.rows {
                XCTAssertFalse(row.id.isEmpty)
                XCTAssertFalse(row.title.isEmpty)
                XCTAssertNotNil(row.detail)
                XCTAssertGreaterThanOrEqual(row.pageIndex, 0)
            }
        }
    }

    func testOnlyJourneyRowsAreNumbered() {
        let viewModel = makeViewModel(.umrah)

        viewModel.onAppear()

        let journey = viewModel.sections.first { $0.id == "journey" }
        let learn = viewModel.sections.first { $0.id == "learn" }

        XCTAssertEqual(journey?.rows.map(\.marker), (1...4).map(GuideReaderPlan.numeral))
        XCTAssertEqual(learn?.rows.allSatisfy { !$0.hasMarker }, true)
    }

    func testSubstagesAreNotPromotedToRows() {
        let viewModel = makeViewModel(.umrah)

        viewModel.onAppear()

        let ids = viewModel.sections.flatMap(\.rows).map(\.id)

        XCTAssertEqual(viewModel.sections.first?.rows.count, 4)
        XCTAssertFalse(ids.contains { $0.hasSuffix("_mistakes") })
    }

    func testRowPageIndicesAreUniqueAndContiguous() {
        for key in GuideKey.allCases {
            let viewModel = makeViewModel(key)
            viewModel.onAppear()

            let indices = viewModel.sections.flatMap(\.rows).map(\.pageIndex)

            XCTAssertEqual(indices, Array(0..<indices.count), key.rawValue)
        }
    }

    func testRepeatedOnAppearDoesNotDuplicateRows() {
        let viewModel = makeViewModel(.hajj)

        viewModel.onAppear()
        let first = viewModel.sections.flatMap(\.rows).count
        viewModel.onAppear()

        XCTAssertEqual(viewModel.sections.flatMap(\.rows).count, first)
    }

    func testLabelsAreLocalizedNotRawKeys() {
        let viewModel = makeViewModel(.hajj)

        XCTAssertFalse(viewModel.screenTitle.isEmpty)
        XCTAssertFalse(viewModel.screenSubtitle.isEmpty)
        XCTAssertNotEqual(viewModel.screenTitle, AppLocalizedKeys.ritesHajjTitle.rawValue)
        XCTAssertNotEqual(viewModel.screenSubtitle, AppLocalizedKeys.ritesHajjSubtitle.rawValue)
        XCTAssertNotEqual(viewModel.emptyMessage, AppLocalizedKeys.ritesEmptyMessage.rawValue)
        XCTAssertNotEqual(viewModel.startTitle, AppLocalizedKeys.ritesStartJourney.rawValue)
        XCTAssertNotEqual(viewModel.overviewTitle, AppLocalizedKeys.ritesOverviewTitle.rawValue)
    }

    func testNoUserFacingLabelMentionsTheInternalContentName() {
        for key in GuideKey.allCases {
            let viewModel = makeViewModel(key)

            for label in [viewModel.screenTitle, viewModel.screenSubtitle,
                          viewModel.emptyMessage, viewModel.startTitle, viewModel.overviewTitle] {
                XCTAssertFalse(label.lowercased().contains("content"), label)
                XCTAssertFalse(label.contains("المحتوى"), label)
            }
        }
    }

    func testTabBarIsHiddenOnThisScreen() {
        XCTAssertFalse(makeViewModel(.umrah).isTabBarVisible)
    }
}

// MARK: - Stage Reader View Model

@MainActor
final class GuideStageReaderViewModelTests: XCTestCase {

    private func makeViewModel(_ key: GuideKey, pageIndex: Int = 0) -> GuideStageReaderViewModel {
        GuideStageReaderViewModel(key: key, pageIndex: pageIndex, coordinator: nil)
    }

    private func loaded(_ key: GuideKey, pageIndex: Int = 0) -> GuideStageReaderViewModel {
        let viewModel = makeViewModel(key, pageIndex: pageIndex)
        viewModel.onAppear()
        return viewModel
    }

    func testLoadIsDeferredUntilOnAppear() {
        let viewModel = makeViewModel(.umrah)

        XCTAssertTrue(viewModel.pages.isEmpty)
        XCTAssertFalse(viewModel.hasContent)
        XCTAssertEqual(viewModel.positionText, "")
    }

    func testUmrahReaderPagesAreItsParentStages() {
        let viewModel = loaded(.umrah)

        XCTAssertEqual(viewModel.pages.map(\.id),
                       ["miqat", "ihram", "tawaf", "sai", "conditions", "duties", "rulings"])
    }

    func testHajjReaderEndsWithItsStandalonePage() {
        let viewModel = loaded(.hajj)

        XCTAssertEqual(viewModel.pages.count, 20)
        XCTAssertEqual(viewModel.pages.last?.id, "page.dhul_hijjah_takbeer")
    }

    func testEveryBundledItemIsRenderedExactlyOnce() throws {
        let store = GuideContentStore(bundle: .main)

        for key in GuideKey.allCases {
            let content = try XCTUnwrap(store.content(for: key), key.rawValue)
            let viewModel = loaded(key)

            let rendered = viewModel.pages.flatMap { page in
                page.steps.map(\.id) + page.groups.flatMap { $0.steps.map(\.id) }
            }

            XCTAssertEqual(Set(rendered).count, rendered.count, key.rawValue)
            XCTAssertEqual(rendered.count - content.pages.count, content.items.count, key.rawValue)
        }
    }

    func testSubstagesAreRenderedAsGroupsOnTheirParentPage() throws {
        let viewModel = loaded(.umrah)
        let tawaf = try XCTUnwrap(viewModel.pages.first { $0.id == "tawaf" })

        XCTAssertEqual(tawaf.groups.map(\.id), ["tawaf_mistakes"])
        XCTAssertFalse(viewModel.pages.contains { $0.id.hasSuffix("_mistakes") })
    }

    func testStepCountIncludesNestedGroups() throws {
        let viewModel = loaded(.umrah)
        let tawaf = try XCTUnwrap(viewModel.pages.first { $0.id == "tawaf" })

        XCTAssertEqual(tawaf.steps.count, 9)
        XCTAssertEqual(tawaf.groups.first?.steps.count, 8)
        XCTAssertEqual(tawaf.stepCount, 17)
    }

    func testStepsAreNumberedInSourceOrder() throws {
        let viewModel = loaded(.umrah)
        let miqat = try XCTUnwrap(viewModel.pages.first { $0.id == "miqat" })

        XCTAssertEqual(miqat.steps.map(\.marker), (1...6).map(GuideReaderPlan.numeral))
    }

    func testNumberingIsSuppressedWhereTheSourceNumbersItself() throws {
        let viewModel = loaded(.umrah)
        let duties = try XCTUnwrap(viewModel.pages.first { $0.id == "duties" })

        XCTAssertEqual(duties.steps.allSatisfy { !$0.hasMarker }, true)
        XCTAssertFalse(duties.steps.isEmpty)
    }

    func testJourneyPagesCarryAMarkerAndLearnPagesDoNot() throws {
        let viewModel = loaded(.umrah)

        XCTAssertEqual(viewModel.pages.prefix(4).map(\.marker), (1...4).map(GuideReaderPlan.numeral))
        XCTAssertEqual(viewModel.pages.dropFirst(4).allSatisfy { !$0.hasMarker }, true)
    }

    func testEveryPageIsHeadedAndNonEmpty() {
        for key in GuideKey.allCases {
            let viewModel = loaded(key)

            for page in viewModel.pages {
                XCTAssertFalse(page.isEmpty, page.id)
                XCTAssertFalse(page.title.isEmpty, page.id)
                XCTAssertFalse(page.sectionTitle.isEmpty, page.id)
            }
        }
    }

    func testNavigationStopsAtBothEnds() {
        let viewModel = loaded(.umrah)

        XCTAssertFalse(viewModel.canGoPrevious)
        viewModel.onPreviousTapped()
        XCTAssertEqual(viewModel.pageIndex, 0)

        while viewModel.canGoNext { viewModel.onNextTapped() }

        XCTAssertEqual(viewModel.pageIndex, viewModel.pages.count - 1)
        viewModel.onNextTapped()
        XCTAssertEqual(viewModel.pageIndex, viewModel.pages.count - 1)
    }

    func testProgressRunsFromTheFirstPageToOne() {
        let viewModel = loaded(.umrah)

        XCTAssertEqual(viewModel.progress, 1.0 / 7.0, accuracy: 0.0001)

        while viewModel.canGoNext { viewModel.onNextTapped() }

        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.0001)
    }

    func testDeepLinkedPageIndexIsKept() {
        let viewModel = loaded(.umrah, pageIndex: 3)

        XCTAssertEqual(viewModel.pageIndex, 3)
        XCTAssertEqual(viewModel.currentPage?.id, "sai")
    }

    func testOutOfRangeDeepLinkIsClamped() {
        let viewModel = loaded(.umrah, pageIndex: 99)

        XCTAssertEqual(viewModel.pageIndex, viewModel.pages.count - 1)
        XCTAssertNotNil(viewModel.currentPage)
    }

    func testPositionTextNamesBothEnds() {
        let viewModel = loaded(.umrah)

        XCTAssertFalse(viewModel.positionText.isEmpty)
        XCTAssertNotEqual(viewModel.positionText, AppLocalizedKeys.ritesPagePosition.rawValue)
        XCTAssertFalse(viewModel.previousTitle.isEmpty)
        XCTAssertFalse(viewModel.nextTitle.isEmpty)
    }

    func testAnEmptyStoreProducesNoPages() {
        let empty = GuideContentStore(bundle: Bundle(for: GuideStageReaderViewModelTests.self))
        let viewModel = GuideStageReaderViewModel(key: .umrah, coordinator: nil, store: empty)

        viewModel.onAppear()

        XCTAssertTrue(viewModel.pages.isEmpty)
        XCTAssertFalse(viewModel.hasContent)
        XCTAssertNil(viewModel.currentPage)
        XCTAssertEqual(viewModel.progress, 0)
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
            case reader(GuideKey, Int)
            case back
        }

        private(set) var calls: [Call] = []

        func coordinateToGuide(_ key: GuideKey) { calls.append(.guide(key)) }

        func coordinateToReader(key: GuideKey, pageIndex: Int) {
            calls.append(.reader(key, pageIndex))
        }

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
            XCTAssertEqual(entry.metrics.count, 2)
            XCTAssertTrue(entry.metrics.allSatisfy { !$0.label.isEmpty && !$0.value.isEmpty })
        }
    }

    func testTheTwoJourneysAreVisuallyDistinct() {
        viewModel.onAppear()

        XCTAssertEqual(viewModel.entries.map(\.icon).count, Set(viewModel.entries.map(\.icon)).count)
        XCTAssertNotEqual(viewModel.entries.first?.accent.color,
                          viewModel.entries.last?.accent.color)
    }

    func testMetricsReflectTheBundledPack() throws {
        viewModel.onAppear()
        let umrah = try XCTUnwrap(viewModel.entries.first { $0.key == .umrah })

        XCTAssertEqual(umrah.metrics[0].value, GuideReaderPlan.numeral(4))
        XCTAssertEqual(umrah.metrics[1].value, GuideReaderPlan.numeral(73))
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
        XCTAssertNotEqual(viewModel.screenTitle, AppLocalizedKeys.ritesTitle.rawValue)
        XCTAssertNotEqual(viewModel.screenSubtitle, AppLocalizedKeys.ritesSubtitle.rawValue)
        XCTAssertNotEqual(viewModel.screenIntro, AppLocalizedKeys.ritesIntro.rawValue)
        XCTAssertNotEqual(viewModel.emptyMessage, AppLocalizedKeys.ritesEmptyMessage.rawValue)
        XCTAssertFalse(viewModel.backAccessibilityLabel.isEmpty)
    }

    func testNoUserFacingLabelMentionsTheInternalContentName() {
        viewModel.onAppear()

        var labels = [viewModel.screenTitle, viewModel.screenSubtitle,
                      viewModel.screenIntro, viewModel.emptyMessage]
        labels += viewModel.entries.flatMap { [$0.title, $0.subtitle] + $0.metrics.flatMap { [$0.label, $0.value] } }

        for label in labels {
            XCTAssertFalse(label.lowercased().contains("content"), label)
            XCTAssertFalse(label.contains("المحتوى"), label)
        }
    }

    func testTabBarIsHiddenOnThisScreen() {
        XCTAssertFalse(viewModel.isTabBarVisible)
    }
}
