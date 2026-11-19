//
//  GlobalSearchTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import XCTest
import Core
@testable import QuranApp

// MARK: - Coordinator Double

final class GlobalSearchCoordinatorDouble: GlobalSearchCoordinating {

    private(set) var quranTargets: [GlobalSearchQuranTarget] = []
    private(set) var dhikrDestinations: [(packKey: String, itemID: Int)] = []
    private(set) var narrationCallCount = 0
    private(set) var backCallCount = 0

    func coordinateToQuran(target: GlobalSearchQuranTarget) {
        quranTargets.append(target)
    }

    func coordinateToNarration(hadiths: [HadithEntry],
                               startIndex: Int,
                               book: HadithBook,
                               chapter: HadithChapter,
                               chapters: [HadithChapter],
                               highlight: HadithSearchQuery?) {
        narrationCallCount += 1
    }

    func coordinateToDhikr(packKey: String, itemID: Int) {
        dhikrDestinations.append((packKey, itemID))
    }

    func coordinateBack() {
        backCallCount += 1
    }
}

// MARK: - Async Waiting

@MainActor
enum GlobalSearchWait {

    private static let timeout = Duration.seconds(5)
    private static let pollInterval = Duration.milliseconds(5)

    static func untilPhase(_ viewModel: GlobalSearchViewModel, is phase: GlobalSearchPhase) async {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if viewModel.phase == phase { return }
            try? await Task.sleep(for: pollInterval)
        }
    }
}

// MARK: - Scope

final class GlobalSearchScopeTests: XCTestCase {

    func testCorpusScopesExcludeTheAllScope() {
        XCTAssertFalse(GlobalSearchScope.corpusScopes.contains(.all))
        XCTAssertEqual(GlobalSearchScope.corpusScopes.count, GlobalSearchScope.allCases.count - 1)
    }

    func testAllScopeIncludesEveryCorpus() {
        for corpus in GlobalSearchScope.corpusScopes {
            XCTAssertTrue(GlobalSearchScope.all.includes(corpus))
        }
    }

    func testCorpusScopeIncludesOnlyItself() {
        XCTAssertTrue(GlobalSearchScope.verse.includes(.verse))
        XCTAssertFalse(GlobalSearchScope.verse.includes(.surah))
        XCTAssertFalse(GlobalSearchScope.verse.includes(.narration))
        XCTAssertFalse(GlobalSearchScope.verse.includes(.dhikr))
    }

    func testOnlyTheAllScopeIsNotACorpus() {
        XCTAssertFalse(GlobalSearchScope.all.isCorpus)
        for corpus in GlobalSearchScope.corpusScopes {
            XCTAssertTrue(corpus.isCorpus)
        }
    }
}

// MARK: - Query Validation

final class GlobalSearchQueryValidationTests: XCTestCase {

    func testSingleLetterQueryIsRejected() {
        XCTAssertFalse(GlobalSearchService.isQueryLongEnough("a"))
        XCTAssertFalse(GlobalSearchService.isQueryLongEnough("ن"))
    }

    func testTwoLetterQueryIsAccepted() {
        XCTAssertTrue(GlobalSearchService.isQueryLongEnough("al"))
        XCTAssertTrue(GlobalSearchService.isQueryLongEnough("نو"))
    }

    func testSingleDigitQueryIsAccepted() {
        XCTAssertTrue(GlobalSearchService.isQueryLongEnough("2"))
    }

    func testWhitespaceOnlyQueryIsRejected() {
        XCTAssertFalse(GlobalSearchService.isQueryLongEnough("   "))
        XCTAssertFalse(GlobalSearchService.isQueryLongEnough(""))
    }
}

// MARK: - Surah Name Index

final class SurahNameIndexTests: XCTestCase {

    private let index = SurahNameIndex()

    func testArabicSurahNameFindsTheSurah() {
        let matches = index.search("الفاتحة")
        XCTAssertEqual(matches.first?.surah.id, 1)
    }

    func testEnglishSurahNameMatchesWithoutDiacritics() {
        let matches = index.search("fatihah")
        XCTAssertEqual(matches.first?.surah.id, 1)
    }

    func testEnglishSurahNameMatchesWithoutTheArticle() {
        let matches = index.search("Nas")
        XCTAssertTrue(matches.contains { $0.surah.id == 114 })
    }

    func testSurahNumberQueryFindsTheSurah() {
        let matches = index.search("114")
        XCTAssertEqual(matches.first?.surah.id, 114)
    }

    func testOutOfRangeSurahNumberFindsNothing() {
        XCTAssertTrue(index.search("115").isEmpty)
    }

    func testExactArabicNameOutranksPartialMatches() {
        let matches = index.search("النور")
        XCTAssertEqual(matches.first?.surah.id, 24)
    }

    func testPartialArabicNameMatchesSeveralSurahs() {
        XCTAssertGreaterThan(index.search("الم").count, 4)
    }

    func testLimitCapsTheMatchCount() {
        XCTAssertLessThanOrEqual(index.search("الم", limit: 3).count, 3)
    }

    func testShortQueryFindsNothing() {
        XCTAssertTrue(index.search("ا").isEmpty)
    }
}

// MARK: - Aggregating Service

final class GlobalSearchServiceTests: XCTestCase {

    private let service = GlobalSearchService()

    func testSurahScopeReturnsSurahsOnly() {
        let results = service.search("الفاتحة", scope: .surah)
        XCTAssertFalse(results.surahs.isEmpty)
        XCTAssertTrue(results.verses.isEmpty)
        XCTAssertTrue(results.dhikr.isEmpty)
        XCTAssertTrue(results.narrations.isEmpty)
    }

    func testVerseScopeReturnsVersesOnly() {
        let results = service.search("الرحمن", scope: .verse)
        XCTAssertFalse(results.verses.isEmpty)
        XCTAssertTrue(results.surahs.isEmpty)
        XCTAssertTrue(results.dhikr.isEmpty)
    }

    func testAllScopeReturnsSeveralCorpora() {
        let results = service.search("الرحمن", scope: .all)
        XCTAssertFalse(results.verses.isEmpty)
        XCTAssertFalse(results.isEmpty)
    }

    func testShortQueryReturnsEmptyResults() {
        let results = service.search("ا", scope: .all)
        XCTAssertTrue(results.isEmpty)
        XCTAssertEqual(results.query, "")
    }

    func testQueryIsTrimmedBeforeSearching() {
        let results = service.search("  الفاتحة  ", scope: .surah)
        XCTAssertEqual(results.query, "الفاتحة")
    }

    func testMatchCountsTrackReturnedResults() {
        let results = service.search("الفاتحة", scope: .surah)
        XCTAssertEqual(results.surahMatchCount, results.surahs.count)
    }
}

// MARK: - Result Model

final class GlobalSearchOutcomeTests: XCTestCase {

    private func hit(_ scope: GlobalSearchScope, id: String) -> GlobalSearchHit {
        GlobalSearchHit(id: id,
                        scope: scope,
                        title: "",
                        detail: "",
                        snippet: "",
                        isSnippetArabicScript: false,
                        destination: .surah(startPage: 1))
    }

    func testSectionIsTruncatedWhenHitsAreFewerThanMatches() {
        let section = GlobalSearchSection(scope: .surah, hits: [hit(.surah, id: "a")], matchCount: 9)
        XCTAssertTrue(section.isTruncated)
    }

    func testSectionIsNotTruncatedWhenEveryMatchIsShown() {
        let section = GlobalSearchSection(scope: .surah, hits: [hit(.surah, id: "a")], matchCount: 1)
        XCTAssertFalse(section.isTruncated)
    }

    func testOutcomeFindsSectionByScope() {
        let surahs = GlobalSearchSection(scope: .surah, hits: [hit(.surah, id: "a")], matchCount: 1)
        let verses = GlobalSearchSection(scope: .verse, hits: [hit(.verse, id: "b")], matchCount: 3)
        let outcome = GlobalSearchOutcome(query: "x",
                                          sections: [surahs, verses],
                                          narrationQuery: nil,
                                          uninstalledNarrationBooks: [])
        XCTAssertEqual(outcome.section(.verse)?.matchCount, 3)
        XCTAssertNil(outcome.section(.dhikr))
    }

    func testOutcomeSumsMatchCountsAcrossSections() {
        let surahs = GlobalSearchSection(scope: .surah, hits: [hit(.surah, id: "a")], matchCount: 1)
        let verses = GlobalSearchSection(scope: .verse, hits: [hit(.verse, id: "b")], matchCount: 3)
        let outcome = GlobalSearchOutcome(query: "x",
                                          sections: [surahs, verses],
                                          narrationQuery: nil,
                                          uninstalledNarrationBooks: [])
        XCTAssertEqual(outcome.matchCount, 4)
        XCTAssertEqual(outcome.hits.count, 2)
        XCTAssertFalse(outcome.isEmpty)
    }

    func testEmptyOutcomeHasNoHits() {
        XCTAssertTrue(GlobalSearchOutcome.empty.isEmpty)
        XCTAssertEqual(GlobalSearchOutcome.empty.matchCount, 0)
    }
}

// MARK: - View Model

@MainActor
final class GlobalSearchViewModelTests: XCTestCase {

    private var coordinator: GlobalSearchCoordinatorDouble!
    private var viewModel: GlobalSearchViewModel!

    override func setUp() async throws {
        try await super.setUp()
        coordinator = GlobalSearchCoordinatorDouble()
        viewModel = GlobalSearchViewModel(coordinator: coordinator)
    }

    override func tearDown() async throws {
        viewModel = nil
        coordinator = nil
        try await super.tearDown()
    }

    func testInitialPhaseIsIdle() {
        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertEqual(viewModel.scope, .all)
        XCTAssertTrue(viewModel.outcome.isEmpty)
    }

    func testShortQueryEntersTooShortPhase() {
        viewModel.searchText = "ا"
        viewModel.performSearch()
        XCTAssertEqual(viewModel.phase, .tooShort)
        XCTAssertFalse(viewModel.statusMessage.isEmpty)
    }

    func testEmptyQueryReturnsToIdlePhase() {
        viewModel.searchText = "الفاتحة"
        viewModel.performSearch()
        viewModel.searchText = ""
        viewModel.performSearch()
        XCTAssertEqual(viewModel.phase, .idle)
    }

    func testScopedSearchProducesSurahResults() async {
        viewModel.searchText = "الفاتحة"
        viewModel.selectScope(.surah)
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        XCTAssertEqual(viewModel.phase, .results)
        XCTAssertEqual(viewModel.scope, .surah)
        let section = viewModel.outcome.section(.surah)
        XCTAssertNotNil(section)
        XCTAssertFalse(section?.hits.first?.title.isEmpty ?? true)
    }

    func testCollapsedAllScopeLimitsHitsPerSection() async {
        viewModel.searchText = "الم"
        viewModel.performSearch()
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        for section in viewModel.outcome.sections {
            XCTAssertLessThanOrEqual(section.hits.count, 4)
        }
        XCTAssertTrue(viewModel.outcome.sections.contains { $0.isTruncated })
    }

    func testScopedSearchShowsEveryMatch() async {
        viewModel.searchText = "الم"
        viewModel.selectScope(.surah)
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        guard let section = viewModel.outcome.section(.surah) else {
            return XCTFail("missing surah section")
        }
        XCTAssertEqual(section.hits.count, section.matchCount)
        XCTAssertFalse(section.isTruncated)
    }

    func testClearSearchResetsEverything() async {
        viewModel.searchText = "الفاتحة"
        viewModel.selectScope(.surah)
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        viewModel.clearSearch()
        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertTrue(viewModel.searchText.isEmpty)
        XCTAssertTrue(viewModel.outcome.isEmpty)
    }

    func testSelectingSurahHitOpensQuranPage() async {
        viewModel.searchText = "الفاتحة"
        viewModel.selectScope(.surah)
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        guard let hit = viewModel.outcome.section(.surah)?.hits.first else {
            return XCTFail("missing surah hit")
        }
        viewModel.select(hit)

        XCTAssertEqual(coordinator.quranTargets.count, 1)
        guard case .page(let page) = coordinator.quranTargets[0] else {
            return XCTFail("expected a page target")
        }
        XCTAssertEqual(page, 1)
    }

    func testSelectingVerseHitOpensVerseReference() async {
        viewModel.searchText = "الرحمن"
        viewModel.selectScope(.verse)
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        guard let hit = viewModel.outcome.section(.verse)?.hits.first else {
            return XCTFail("missing verse hit")
        }
        viewModel.select(hit)

        XCTAssertEqual(coordinator.quranTargets.count, 1)
        guard case .verse(let reference) = coordinator.quranTargets[0] else {
            return XCTFail("expected a verse target")
        }
        XCTAssertGreaterThan(reference.surahNumber, 0)
        XCTAssertGreaterThan(reference.verseNumber, 0)
    }

    func testVerseHitCarriesArabicSnippetAndHighlight() async {
        viewModel.searchText = "الرحمن"
        viewModel.selectScope(.verse)
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        guard let hit = viewModel.outcome.section(.verse)?.hits.first else {
            return XCTFail("missing verse hit")
        }
        XCTAssertTrue(hit.isSnippetArabicScript)
        XCTAssertFalse(hit.snippet.isEmpty)
        XCTAssertFalse(String(viewModel.highlightedSnippet(hit).characters).isEmpty)
    }

    func testBackNavigationReachesTheCoordinator() {
        viewModel.coordinateBack()
        XCTAssertEqual(coordinator.backCallCount, 1)
    }

    func testEveryScopeHasALocalizedTitle() {
        for scope in viewModel.scopes {
            XCTAssertFalse(viewModel.scopeTitle(scope).isEmpty)
        }
        XCTAssertEqual(viewModel.scopes.count, GlobalSearchScope.allCases.count)
    }

    func testStaticLabelsAreLocalized() {
        XCTAssertFalse(viewModel.navigationTitle.isEmpty)
        XCTAssertFalse(viewModel.searchPlaceholder.isEmpty)
        XCTAssertFalse(viewModel.promptMessage.isEmpty)
        XCTAssertFalse(viewModel.showAllTitle.isEmpty)
        XCTAssertFalse(viewModel.uninstalledNarrationSubtitle.isEmpty)
    }

    func testLocalizedLabelsResolveToTheActiveLanguage() {
        let manager = LocalizationManager.shared
        let original = manager.currentLanguage
        defer { manager.currentLanguage = original }

        manager.currentLanguage = .English
        let english = viewModel.scopeTitle(.verse)
        manager.currentLanguage = .Arabic
        let arabic = viewModel.scopeTitle(.verse)

        XCTAssertFalse(english.isEmpty)
        XCTAssertFalse(arabic.isEmpty)
        XCTAssertNotEqual(english, arabic)
    }

    func testUninstalledNoticeIsHiddenBeforeSearching() {
        XCTAssertFalse(viewModel.isUninstalledNarrationNoticeVisible)
        XCTAssertTrue(viewModel.uninstalledNarrationTitle.isEmpty)
    }

    func testSurahScopeNeverShowsTheNarrationNotice() async {
        viewModel.searchText = "الفاتحة"
        viewModel.selectScope(.surah)
        await GlobalSearchWait.untilPhase(viewModel, is: .results)

        XCTAssertFalse(viewModel.isUninstalledNarrationNoticeVisible)
    }

    func testSelectingTheSameScopeDoesNotRestartTheSearch() {
        viewModel.selectScope(.all)
        XCTAssertEqual(viewModel.phase, .idle)
    }
}
