//
//  HadithChaptersViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import Foundation
import Core

@MainActor
final class HadithChaptersViewModel: MainViewModel {

    @Published var chapters: [HadithChapter] = []

    let book: HadithBook
    var isTabBarVisible: Bool { true }

    weak var coordinator: HadithCoordinating?
    private let service = HadithDatabaseService.shared

    init(coordinator: HadithCoordinating, book: HadithBook) {
        self.coordinator = coordinator
        self.book = book
    }

    func onAppear() {
        guard chapters.isEmpty else { return }
        chapters = service.fetchChapters(bookId: book.id)
    }

    func selectChapter(_ chapter: HadithChapter) {
        let hadiths = service.fetchHadiths(bookId: book.id, chapterId: chapter.id)
        guard !hadiths.isEmpty else { return }
        coordinator?.coordinateToReading(hadiths: hadiths, startIndex: 0, book: book, chapter: chapter, chapters: chapters)
    }

    func goBack() {
        coordinator?.coordinateBack()
    }
}
