//
//  HadithReadingViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import Foundation
import Core

@MainActor
final class HadithReadingViewModel: MainViewModel {

    @Published var currentIndex: Int
    @Published var isFavorite: Bool = false
    @Published var showTOC: Bool = false
    @Published var showJumpInput: Bool = false
    @Published var jumpInput: String = ""

    @Published var hadiths: [HadithEntry]
    let book: HadithBook
    let chapters: [HadithChapter]
    var isTabBarVisible: Bool { false }

    weak var coordinator: HadithCoordinating?
    private let service = HadithDatabaseService.shared

    var currentHadith: HadithEntry? {
        guard currentIndex < hadiths.count else { return nil }
        return hadiths[currentIndex]
    }

    var currentChapter: HadithChapter? {
        guard let hadith = currentHadith, !chapters.isEmpty else { return nil }
        return chapters.first { $0.id == hadith.chapterId }
    }

    var progress: Double {
        guard hadiths.count > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(hadiths.count)
    }

    var canGoNext: Bool { currentIndex < hadiths.count - 1 }
    var canGoPrevious: Bool { currentIndex > 0 }

    init(coordinator: HadithCoordinating, hadiths: [HadithEntry], startIndex: Int,
         book: HadithBook, chapter: HadithChapter, chapters: [HadithChapter]) {
        self.coordinator = coordinator
        self.hadiths = hadiths
        self.book = book
        self.chapters = chapters
        self.currentIndex = min(startIndex, max(0, hadiths.count - 1))
    }

    func onAppear() { saveProgress() }

    func goBack() { coordinator?.coordinateBack() }

    func next() {
        guard canGoNext else { return }
        currentIndex += 1
        saveProgress()
    }

    func previous() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        saveProgress()
    }

    func toggleFavorite() { isFavorite.toggle() }

    func jumpToHadith(number: Int) {
        if let idx = hadiths.firstIndex(where: { $0.number == number }) {
            currentIndex = idx
            saveProgress()
            return
        }
        guard let target = service.fetchHadith(bookId: book.id, number: number) else { return }
        let newHadiths = service.fetchHadiths(bookId: book.id, chapterId: target.chapterId)
        guard !newHadiths.isEmpty else { return }
        hadiths = newHadiths
        currentIndex = newHadiths.firstIndex(where: { $0.number == number }) ?? 0
        saveProgress()
    }

    func jumpToChapter(_ chapter: HadithChapter) {
        if let idx = hadiths.firstIndex(where: { $0.chapterId == chapter.id }) {
            currentIndex = idx
            saveProgress()
        }
    }

    private func saveProgress() {
        guard let hadith = currentHadith else { return }
        let chap = currentChapter
        let position = LastReadPosition(
            bookId: book.id,
            bookTitleEn: book.titleEn,
            bookTitleAr: book.titleAr,
            bookColorHex: book.colorHex,
            chapterId: chap?.id ?? hadith.chapterId,
            chapterTitleEn: chap?.titleEn ?? "",
            chapterTitleAr: chap?.titleAr ?? "",
            hadithIndex: currentIndex,
            hadithNumber: hadith.number,
            bookHadithCount: book.hadithCount,
            chapterHadithCount: hadiths.count
        )
        HadithLastReadManager.shared.save(position)
    }
}
