//
//  HadithLibraryViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import Foundation
import Core

@MainActor
final class HadithLibraryViewModel: MainViewModel {

    @Published var books: [HadithBook] = []
    @Published var searchText: String = ""
    @Published private(set) var searchOutcome: HadithSearchOutcome = .empty
    @Published private(set) var searchPhase: HadithSearchPhase = .idle
    @Published private(set) var expandedBookIds: Set<Int> = []
    @Published var lastRead: LastReadPosition? = nil

    var isTabBarVisible: Bool { true }
    var isSearching: Bool { searchPhase != .idle }

    weak var coordinator: HadithCoordinating?
    private let service         = HadithDatabaseService.shared
    let downloadManager         = HadithDownloadManager.shared

    private static let searchDebounce = Duration.milliseconds(300)
    private var searchTask: Task<Void, Never>?

    init(coordinator: HadithCoordinating) {
        self.coordinator = coordinator
    }

    func onAppear() {
        if books.isEmpty {
            books = service.loadManifest()
        }
        lastRead = HadithLastReadManager.shared.load()
    }

    // MARK: - Navigation

    func selectBook(_ book: HadithBook) {
        guard downloadManager.isDownloaded(book.id) else { return }
        let chapters = service.fetchChapters(bookId: book.id)
        guard let firstChapter = chapters.first else { return }
        let hadiths = service.fetchHadiths(bookId: book.id, chapterId: firstChapter.id)
        guard !hadiths.isEmpty else { return }
        coordinator?.coordinateToReading(hadiths: hadiths, startIndex: 0,
                                         book: book, chapter: firstChapter, chapters: chapters)
    }

    /// Picks the reading back up, repairing the position when it no longer
    /// points at a chapter that exists.
    ///
    /// A position carried over from the old corpus has no chapter: the two
    /// numberings shared nothing a chapter id could be translated through. The
    /// hadith number is enough to find where it sits now, and the repaired
    /// position is written back so the lookup is paid once rather than on
    /// every launch.
    func resume() {
        guard let position = lastRead,
              downloadManager.isDownloaded(position.bookId) else { return }

        let chapters = service.fetchChapters(bookId: position.bookId)
        var chapterId = position.chapterId
        var hadiths = service.fetchHadiths(bookId: position.bookId, chapterId: chapterId)
        var resolvedId: Int?

        if hadiths.isEmpty {
            guard let entry = service.fetchHadith(bookId: position.bookId,
                                                  number: position.hadithNumber) else { return }
            chapterId = entry.chapterId
            hadiths = service.fetchHadiths(bookId: position.bookId, chapterId: chapterId)
            resolvedId = entry.id
        }
        guard !hadiths.isEmpty else { return }

        // The stored index belongs to the chapter the reader was in. Once the
        // chapter has been re-resolved it means nothing, so the hadith itself
        // is what the position is restored from.
        let startIndex = resolvedId.flatMap { id in hadiths.firstIndex(where: { $0.id == id }) }
            ?? min(max(position.hadithIndex, 0), hadiths.count - 1)

        let book = books.first(where: { $0.id == position.bookId })
            ?? HadithBook(id: position.bookId, titleAr: position.bookTitleAr,
                          titleEn: position.bookTitleEn, authorAr: "", authorEn: "",
                          hadithCount: position.bookHadithCount, chapterCount: 0,
                          colorHex: position.bookColorHex, downloadURL: "", fileSizeBytes: 0)

        let chapter = chapters.first(where: { $0.id == chapterId })
            ?? HadithChapter(id: chapterId, bookId: position.bookId, number: 0,
                             titleAr: position.chapterTitleAr, titleEn: position.chapterTitleEn)

        if chapterId != position.chapterId {
            repairLastRead(position, chapter: chapter, index: startIndex)
        }

        coordinator?.coordinateToReading(hadiths: hadiths, startIndex: startIndex,
                                         book: book, chapter: chapter, chapters: chapters)
    }

    /// Stores the chapter the position was resolved to.
    private func repairLastRead(_ position: LastReadPosition,
                                chapter: HadithChapter,
                                index: Int) {
        let repaired = LastReadPosition(
            bookId: position.bookId,
            bookTitleEn: position.bookTitleEn,
            bookTitleAr: position.bookTitleAr,
            bookColorHex: position.bookColorHex,
            chapterId: chapter.id,
            chapterTitleEn: chapter.titleEn,
            chapterTitleAr: chapter.titleAr,
            hadithIndex: index,
            hadithNumber: position.hadithNumber,
            bookHadithCount: position.bookHadithCount,
            chapterHadithCount: chapter.hadithCount
        )
        HadithLastReadManager.shared.save(repaired)
        lastRead = repaired
    }

    func selectSearchResult(_ result: HadithSearchResult) {
        guard downloadManager.isDownloaded(result.book.id) else { return }

        let chapters = service.fetchChapters(bookId: result.book.id)
        let chapter = chapters.first { $0.id == result.hadith.chapterId }
            ?? HadithChapter(id: result.hadith.chapterId, bookId: result.book.id,
                             number: 0, titleAr: "", titleEn: "")

        let siblings = service.fetchHadiths(bookId: result.book.id,
                                            chapterId: result.hadith.chapterId)
        let hadiths = siblings.isEmpty ? [result.hadith] : siblings
        let startIndex = hadiths.firstIndex { $0.id == result.hadith.id } ?? 0

        coordinator?.coordinateToReading(hadiths: hadiths, startIndex: startIndex,
                                         book: result.book, chapter: chapter,
                                         chapters: chapters, highlight: searchOutcome.query)
    }

    // MARK: - Download

    func download(_ book: HadithBook) {
        downloadManager.download(book: book)
    }

    func cancelDownload(_ book: HadithBook) {
        downloadManager.cancel(bookId: book.id)
    }

    func deleteBook(_ book: HadithBook) {
        downloadManager.delete(bookId: book.id)
    }

    // MARK: - Search

    func performSearch() {
        searchTask?.cancel()
        expandedBookIds = []

        guard let query = HadithSearchQuery(searchText) else {
            searchOutcome = .empty
            searchPhase = searchText.trimmingCharacters(in: .whitespaces).isEmpty ? .idle : .tooShort
            return
        }

        searchPhase = .running
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: Self.searchDebounce)
            guard !Task.isCancelled else { return }

            let outcome = await Task.detached(priority: .userInitiated) {
                HadithDatabaseService.shared.searchAllBooks(query)
            }.value

            guard !Task.isCancelled, let self else { return }
            self.searchOutcome = outcome
            self.searchPhase = outcome.isEmpty ? .noResults : .results
        }
    }

    func expandResults(for matches: HadithBookMatches) {
        guard let query = searchOutcome.query,
              !expandedBookIds.contains(matches.id) else { return }
        expandedBookIds.insert(matches.id)
        let book = matches.book

        Task { [weak self] in
            let expanded = await Task.detached(priority: .userInitiated) {
                HadithDatabaseService.shared.searchResults(in: book, searchQuery: query)
            }.value
            guard let self, let expanded else { return }
            self.searchOutcome = self.searchOutcome.replacing(expanded)
        }
    }

    // MARK: - Search labels

    var searchPlaceholder: String { AppLocalizedKeys.searchNarrations.value }

    var searchStatusMessage: String {
        switch searchPhase {
        case .tooShort:  return AppLocalizedKeys.searchKeepTyping.value
        case .noResults: return AppLocalizedKeys.noResults.value
        default:         return ""
        }
    }

    var searchSummary: String {
        guard searchPhase == .results else { return "" }
        let format = searchOutcome.isTotalApproximate
            ? AppLocalizedKeys.searchResultsCountApprox.value
            : AppLocalizedKeys.searchResultsCount.value
        return String(format: format, searchOutcome.totalMatches, searchOutcome.books.count)
    }

    func matchCountLabel(for matches: HadithBookMatches) -> String {
        let format = matches.isTotalApproximate
            ? AppLocalizedKeys.searchBookCountApprox.value
            : AppLocalizedKeys.searchBookCount.value
        return String(format: format, matches.totalMatches)
    }

    func expandLabel(for matches: HadithBookMatches) -> String {
        String(format: AppLocalizedKeys.searchSeeAllInBook.value,
               matches.totalMatches - matches.results.count)
    }

    var notInstalledTitle: String {
        String(format: AppLocalizedKeys.searchBooksNotInstalled.value,
               searchOutcome.notInstalled.count)
    }

    var notInstalledSubtitle: String { AppLocalizedKeys.searchDownloadToInclude.value }

    func numberLabel(for result: HadithSearchResult) -> String {
        "\(AppLocalizedKeys.hadithNumber.value) \(result.hadith.number)"
    }

    func snippet(for result: HadithSearchResult) -> AttributedString {
        highlighted(result.hadith.arabicText)
    }

    func translationSnippet(for result: HadithSearchResult) -> AttributedString? {
        guard result.hadith.hasTranslation else { return nil }
        return highlighted(result.hadith.translation)
    }

    private func highlighted(_ text: String) -> AttributedString {
        let query = searchOutcome.query
        return HadithHighlightedText.make(HadithSnippet.around(query, in: text), matching: query)
    }
}

// MARK: - Book Sections

extension HadithLibraryViewModel {

    private static let nineBookIdentifiers: Set<Int> = [7, 5, 6, 4, 1, 2, 9, 8, 11]

    var nineBooks: [HadithBook] {
        books.filter { Self.nineBookIdentifiers.contains($0.id) }
    }

    var otherCollections: [HadithBook] {
        books.filter { !Self.nineBookIdentifiers.contains($0.id) }
    }

    var nineBooksSectionTitle: String {
        AppLocalizedKeys.hadithSectionNineBooks.value
    }

    var otherCollectionsSectionTitle: String {
        AppLocalizedKeys.hadithSectionOtherCollections.value
    }

    func metaText(for book: HadithBook) -> String {
        let hadiths = localizedCount(AppLocalizedKeys.hadithCount, book.hadithCount)
        let chapters = localizedCount(AppLocalizedKeys.hadithChapterCount, book.chapterCount)
        return "\(hadiths) · \(chapters)"
    }

    func readingProgressText(for position: LastReadPosition) -> String {
        "\(groupedNumber(position.hadithIndex + 1)) / \(groupedNumber(position.bookHadithCount))"
    }

    private func localizedCount(_ key: AppLocalizedKeys, _ value: Int) -> String {
        key.value.replacingOccurrences(of: "%d", with: groupedNumber(value))
    }

    private func groupedNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

// MARK: - Library Titles

extension HadithLibraryViewModel {

    var authenticTraditionsTitle: String {
        AppLocalizedKeys.theAuthenticTraditions.value.uppercased()
    }

    var continueReadingTitle: String {
        AppLocalizedKeys.continueReading.value.uppercased()
    }

    var resumeTitle: String {
        AppLocalizedKeys.resume.value.uppercased()
    }

    var propheticNarrationTitle: String {
        AppLocalizedKeys.propheticNarration.value.uppercased()
    }
}
