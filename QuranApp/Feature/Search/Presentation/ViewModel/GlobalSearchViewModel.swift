//
//  GlobalSearchViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation
import SwiftUI
import Core

@MainActor
final class GlobalSearchViewModel: MainViewModel {

    @Published var searchText: String = ""
    @Published private(set) var scope: GlobalSearchScope = .all
    @Published private(set) var outcome: GlobalSearchOutcome = .empty
    @Published private(set) var phase: GlobalSearchPhase = .idle

    var isTabBarVisible: Bool { false }

    weak var coordinator: GlobalSearchCoordinating?

    private static let searchDebounce = Duration.milliseconds(300)
    private static let collapsedSectionLimit = 4

    private let searchService: GlobalSearchService
    private let narrationService: HadithDatabaseService
    private let narrationDownloads: HadithDownloadManager
    private let localizationManager: LocalizationManager
    private var searchTask: Task<Void, Never>?
    private var rawResults: GlobalSearchRawResults = .empty

    init(coordinator: GlobalSearchCoordinating,
         searchService: GlobalSearchService = .shared,
         narrationService: HadithDatabaseService = .shared,
         narrationDownloads: HadithDownloadManager = .shared,
         localizationManager: LocalizationManager = .shared) {
        self.coordinator = coordinator
        self.searchService = searchService
        self.narrationService = narrationService
        self.narrationDownloads = narrationDownloads
        self.localizationManager = localizationManager
    }

    func onAppear() { }

    // MARK: - Search

    func performSearch() {
        runSearch(isDebounced: true)
    }

    func selectScope(_ scope: GlobalSearchScope) {
        guard scope != self.scope else { return }
        self.scope = scope
        runSearch(isDebounced: false)
    }

    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
        rawResults = .empty
        outcome = .empty
        phase = .idle
    }

    private func runSearch(isDebounced: Bool) {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            rawResults = .empty
            outcome = .empty
            phase = .idle
            return
        }
        guard GlobalSearchService.isQueryLongEnough(query) else {
            rawResults = .empty
            outcome = .empty
            phase = .tooShort
            return
        }

        phase = .running
        let requestedScope = scope
        let service = searchService

        searchTask = Task { [weak self] in
            if isDebounced {
                try? await Task.sleep(for: Self.searchDebounce)
            }
            guard !Task.isCancelled else { return }

            let results = await Task.detached(priority: .userInitiated) {
                service.search(query, scope: requestedScope)
            }.value

            guard !Task.isCancelled, let self else { return }
            self.rawResults = results
            self.outcome = self.makeOutcome(results)
            self.phase = self.outcome.isEmpty ? .noResults : .results
        }
    }

    // MARK: - Outcome assembly

    private func makeOutcome(_ results: GlobalSearchRawResults) -> GlobalSearchOutcome {
        var sections: [GlobalSearchSection] = []

        for corpus in GlobalSearchScope.corpusScopes where scope.includes(corpus) {
            let hits = makeHits(corpus, results: results)
            guard !hits.isEmpty else { continue }
            sections.append(GlobalSearchSection(scope: corpus,
                                                hits: Array(hits.prefix(displayLimit)),
                                                matchCount: matchCount(corpus, results: results)))
        }

        return GlobalSearchOutcome(query: results.query,
                                   sections: sections,
                                   narrationQuery: results.narrations.query,
                                   uninstalledNarrationBooks: results.narrations.notInstalled)
    }

    private var displayLimit: Int {
        scope == .all ? Self.collapsedSectionLimit : Int.max
    }

    private func matchCount(_ corpus: GlobalSearchScope, results: GlobalSearchRawResults) -> Int {
        switch corpus {
        case .surah:     return results.surahMatchCount
        case .verse:     return results.verseMatchCount
        case .narration: return results.narrations.totalMatches
        case .dhikr:     return results.dhikrMatchCount
        case .all:       return 0
        }
    }

    private func makeHits(_ corpus: GlobalSearchScope, results: GlobalSearchRawResults) -> [GlobalSearchHit] {
        switch corpus {
        case .surah:     return results.surahs.map(makeSurahHit)
        case .verse:     return results.verses.map(makeVerseHit)
        case .narration: return results.narrations.books.flatMap { $0.results }.map(makeNarrationHit)
        case .dhikr:     return results.dhikr.map(makeDhikrHit)
        case .all:       return []
        }
    }

    private func makeSurahHit(_ match: SurahNameMatch) -> GlobalSearchHit {
        let surah = match.surah
        let revelation = surah.isMeccan ? AppLocalizedKeys.meccan.value : AppLocalizedKeys.medinan.value
        let detail = String(format: AppLocalizedKeys.globalSearchSurahDetail.value,
                            revelation,
                            number(surah.versesCount))
        return GlobalSearchHit(id: "surah-\(surah.id)",
                               scope: .surah,
                               title: isArabic ? surah.arabicTitle : surah.englishTitle,
                               detail: detail,
                               snippet: "",
                               isSnippetArabicScript: false,
                               destination: .surah(startPage: surah.startPage))
    }

    private func makeVerseHit(_ result: QuranSearchResult) -> GlobalSearchHit {
        let title = String(format: AppLocalizedKeys.globalSearchVerseLocation.value,
                           result.surahName,
                           number(result.verseNumber))
        let detail = "\(AppLocalizedKeys.page.value) \(number(result.page))"
        let reference = QuranVerseReference(surahNumber: result.surahNumber,
                                            verseNumber: result.verseNumber)
        return GlobalSearchHit(id: "verse-\(result.id)",
                               scope: .verse,
                               title: title,
                               detail: detail,
                               snippet: result.text,
                               isSnippetArabicScript: true,
                               destination: .verse(reference))
    }

    private func makeNarrationHit(_ result: HadithSearchResult) -> GlobalSearchHit {
        let detail = String(format: AppLocalizedKeys.globalSearchNarrationNumber.value,
                            number(result.hadith.number))
        return GlobalSearchHit(id: "narration-\(result.book.id)-\(result.hadith.id)",
                               scope: .narration,
                               title: result.book.title,
                               detail: detail,
                               snippet: result.hadith.arabicText,
                               isSnippetArabicScript: true,
                               destination: .narration(result))
    }

    private func makeDhikrHit(_ hit: AthkarSearchHit) -> GlobalSearchHit {
        let isArabicScript = hit.field == .title || hit.field == .body || hit.field == .note
        return GlobalSearchHit(id: "dhikr-\(hit.id)",
                               scope: .dhikr,
                               title: hit.packName,
                               detail: "",
                               snippet: hit.snippet,
                               isSnippetArabicScript: isArabicScript,
                               destination: .dhikr(packKey: hit.packKey, itemID: hit.itemID))
    }

    // MARK: - Navigation

    func select(_ hit: GlobalSearchHit) {
        switch hit.destination {
        case .surah(let startPage):
            coordinator?.coordinateToQuran(target: .page(startPage))
        case .verse(let reference):
            coordinator?.coordinateToQuran(target: .verse(reference))
        case .narration(let result):
            openNarration(result)
        case .dhikr(let packKey, let itemID):
            coordinator?.coordinateToDhikr(packKey: packKey, itemID: itemID)
        }
    }

    func coordinateBack() {
        coordinator?.coordinateBack()
    }

    private func openNarration(_ result: HadithSearchResult) {
        guard narrationDownloads.isDownloaded(result.book.id) else { return }

        let chapters = narrationService.fetchChapters(bookId: result.book.id)
        let chapter = chapters.first { $0.id == result.hadith.chapterId }
            ?? HadithChapter(id: result.hadith.chapterId,
                             bookId: result.book.id,
                             number: 0,
                             titleAr: "",
                             titleEn: "")

        let siblings = narrationService.fetchHadiths(bookId: result.book.id,
                                                     chapterId: result.hadith.chapterId)
        let hadiths = siblings.isEmpty ? [result.hadith] : siblings
        let startIndex = hadiths.firstIndex { $0.id == result.hadith.id } ?? 0

        coordinator?.coordinateToNarration(hadiths: hadiths,
                                           startIndex: startIndex,
                                           book: result.book,
                                           chapter: chapter,
                                           chapters: chapters,
                                           highlight: outcome.narrationQuery)
    }

    // MARK: - Labels

    var navigationTitle: String { AppLocalizedKeys.globalSearchTitle.value }

    var searchPlaceholder: String { AppLocalizedKeys.globalSearchPlaceholder.value }

    var promptMessage: String { AppLocalizedKeys.globalSearchPrompt.value }

    var showAllTitle: String { AppLocalizedKeys.globalSearchShowAll.value }

    var statusMessage: String {
        switch phase {
        case .tooShort:  return AppLocalizedKeys.searchKeepTyping.value
        case .noResults: return AppLocalizedKeys.noResults.value
        default:         return ""
        }
    }

    var uninstalledNarrationTitle: String {
        guard !outcome.uninstalledNarrationBooks.isEmpty else { return "" }
        return String(format: AppLocalizedKeys.searchBooksNotInstalled.value,
                      outcome.uninstalledNarrationBooks.count)
    }

    var uninstalledNarrationSubtitle: String { AppLocalizedKeys.searchDownloadToInclude.value }

    var isUninstalledNarrationNoticeVisible: Bool {
        (phase == .results || phase == .noResults)
            && scope.includes(.narration)
            && !outcome.uninstalledNarrationBooks.isEmpty
    }

    var scopes: [GlobalSearchScope] { GlobalSearchScope.allCases }

    func scopeTitle(_ scope: GlobalSearchScope) -> String {
        switch scope {
        case .all:       return AppLocalizedKeys.globalSearchScopeAll.value
        case .surah:     return AppLocalizedKeys.globalSearchScopeSurahs.value
        case .verse:     return AppLocalizedKeys.globalSearchScopeVerses.value
        case .narration: return AppLocalizedKeys.globalSearchScopeNarrations.value
        case .dhikr:     return AppLocalizedKeys.globalSearchScopeAdhkar.value
        }
    }

    func matchCountText(_ section: GlobalSearchSection) -> String {
        String(format: AppLocalizedKeys.globalSearchMatchCount.value, section.matchCount)
    }

    func highlightedSnippet(_ hit: GlobalSearchHit) -> AttributedString {
        var attributed = AttributedString(hit.snippet)
        guard !hit.snippet.isEmpty, !outcome.query.isEmpty else { return attributed }

        for range in QuranSearchService.highlightRanges(in: hit.snippet, query: outcome.query) {
            guard let lower = AttributedString.Index(range.lowerBound, within: attributed),
                  let upper = AttributedString.Index(range.upperBound, within: attributed)
            else { continue }
            attributed[lower ..< upper].foregroundColor = Color.searchMatch
        }
        return attributed
    }

    // MARK: - Formatting

    private var isArabic: Bool { localizationManager.currentLanguage == .Arabic }

    private func number(_ value: Int) -> String {
        isArabic ? value.arabicNumerals : String(value)
    }
}
