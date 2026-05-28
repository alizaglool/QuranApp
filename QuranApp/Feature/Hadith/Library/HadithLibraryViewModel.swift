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
    @Published var searchResults: [HadithSearchResult] = []
    @Published var isSearching: Bool = false
    @Published var lastRead: LastReadPosition? = nil

    var isTabBarVisible: Bool { true }

    weak var coordinator: HadithCoordinating?
    private let service         = HadithDatabaseService.shared
    let downloadManager         = HadithDownloadManager.shared

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

    func resume() {
        guard let position = lastRead,
              downloadManager.isDownloaded(position.bookId) else { return }

        let hadiths = service.fetchHadiths(bookId: position.bookId, chapterId: position.chapterId)
        guard !hadiths.isEmpty else { return }

        let book = books.first(where: { $0.id == position.bookId })
            ?? HadithBook(id: position.bookId, titleAr: position.bookTitleAr,
                          titleEn: position.bookTitleEn, authorAr: "", authorEn: "",
                          hadithCount: position.bookHadithCount, chapterCount: 0,
                          colorHex: position.bookColorHex, downloadURL: "", fileSizeBytes: 0)

        let chapter = HadithChapter(id: position.chapterId, bookId: position.bookId,
                                    number: 0, titleAr: position.chapterTitleAr,
                                    titleEn: position.chapterTitleEn)
        let startIndex = min(position.hadithIndex, hadiths.count - 1)
        coordinator?.coordinateToReading(hadiths: hadiths, startIndex: startIndex,
                                         book: book, chapter: chapter, chapters: [])
    }

    func selectSearchResult(_ result: HadithSearchResult) {
        guard downloadManager.isDownloaded(result.book.id) else { return }
        let chapter = HadithChapter(id: result.hadith.chapterId, bookId: result.hadith.bookId,
                                    number: 0, titleAr: "", titleEn: "")
        coordinator?.coordinateToReading(hadiths: [result.hadith], startIndex: 0,
                                         book: result.book, chapter: chapter, chapters: [])
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
        let query = searchText.trimmingCharacters(in: .whitespaces)
        isSearching = !query.isEmpty
        guard isSearching else { searchResults = []; return }
        Task {
            let results = await Task.detached(priority: .userInitiated) {
                HadithDatabaseService.shared.search(query: query)
            }.value
            searchResults = results
        }
    }
}
