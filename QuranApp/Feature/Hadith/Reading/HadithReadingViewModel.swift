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
    @Published private(set) var presentations: [Int: HadithDetailPresentation] = [:]
    @Published private(set) var selectedTabs: [Int: HadithDetailTab] = [:]
    @Published var narrator: HadithNarratorPresentation?
    @Published var gloss: HadithGlossPresentation?

    let book: HadithBook
    let chapters: [HadithChapter]
    let highlight: HadithSearchQuery?
    var isTabBarVisible: Bool { false }

    weak var coordinator: HadithCoordinating?
    private let service = HadithDatabaseService.shared
    private var loading: Set<Int> = []

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
         book: HadithBook, chapter: HadithChapter, chapters: [HadithChapter],
         highlight: HadithSearchQuery? = nil) {
        self.coordinator = coordinator
        self.hadiths = hadiths
        self.book = book
        self.chapters = chapters
        self.highlight = highlight
        self.currentIndex = min(startIndex, max(0, hadiths.count - 1))
    }

    func onAppear() { moved() }

    func goBack() { coordinator?.coordinateBack() }

    func next() {
        guard canGoNext else { return }
        currentIndex += 1
        moved()
    }

    func previous() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        moved()
    }

    func toggleFavorite() { isFavorite.toggle() }

    func jumpToHadith(number: Int) {
        if let idx = hadiths.firstIndex(where: { $0.number == number }) {
            currentIndex = idx
            moved()
            return
        }
        guard let target = service.fetchHadith(bookId: book.id, number: number) else { return }
        let newHadiths = service.fetchHadiths(bookId: book.id, chapterId: target.chapterId)
        guard !newHadiths.isEmpty else { return }
        hadiths = newHadiths
        currentIndex = newHadiths.firstIndex(where: { $0.number == number }) ?? 0
        moved()
    }

    func show(index: Int) {
        guard hadiths.indices.contains(index), index != currentIndex else { return }
        currentIndex = index
        moved()
    }

    func jumpToChapter(_ chapter: HadithChapter) {
        if let idx = hadiths.firstIndex(where: { $0.chapterId == chapter.id }) {
            currentIndex = idx
            moved()
        }
    }

    // MARK: - Details

    func presentation(for hadith: HadithEntry) -> HadithDetailPresentation {
        presentations[hadith.id] ?? .empty
    }

    func selectedTab(for hadith: HadithEntry) -> HadithDetailTab? {
        selectedTabs[hadith.id] ?? presentations[hadith.id]?.tabs.first?.tab
    }

    func select(_ tab: HadithDetailTab, for hadith: HadithEntry) {
        selectedTabs[hadith.id] = tab
    }

    private func moved() {
        saveProgress()
        loadDetails(around: currentIndex)
    }

    private func loadDetails(around index: Int) {
        for offset in [0, 1, -1] {
            let target = index + offset
            guard hadiths.indices.contains(target) else { continue }
            loadDetail(for: hadiths[target])
        }
    }

    private func loadDetail(for hadith: HadithEntry) {
        guard presentations[hadith.id] == nil, loading.insert(hadith.id).inserted else { return }

        Task { [weak self] in
            let presentation = await Task.detached(priority: .userInitiated) {
                HadithDetailPresentation.make(from: HadithDatabaseService.shared.fetchDetail(for: hadith))
            }.value

            guard let self else { return }
            self.loading.remove(hadith.id)
            self.presentations[hadith.id] = presentation
        }
    }

    // MARK: - Links

    func handle(_ link: HadithBodyLink, in hadith: HadithEntry) {
        switch link {
        case let .narrator(id): openNarrator(id: id, in: hadith)
        case let .ghareeb(id):  openGhareeb(id: id, in: hadith)
        case let .note(id):     openNote(id: id, in: hadith)
        }
    }

    func openNarrator(_ row: HadithNarratorRow, in hadith: HadithEntry) {
        openNarrator(id: row.id, in: hadith, fallbackName: row.name)
    }

    func openGhareeb(_ meaning: HadithGhareebMeaning) {
        gloss = .ghareeb(meaning)
    }

    func openNote(_ note: HadithNoteItem) {
        gloss = .note(note)
    }

    func closeNarrator() { narrator = nil }

    func closeGloss() { gloss = nil }

    private func openNarrator(id: Int, in hadith: HadithEntry, fallbackName: String? = nil) {
        let name = fallbackName
            ?? hadith.markup.narrators.first(where: { $0.rwahID == id })?.name
            ?? ""
        let bookId = hadith.bookId

        Task { [weak self] in
            let profile = await Task.detached(priority: .userInitiated) {
                HadithDatabaseService.shared.fetchNarrator(bookId: bookId, narratorId: id)
            }.value

            guard let self else { return }
            self.narrator = HadithNarratorPresentation.make(profile, id: id, fallbackName: name)
        }
    }

    private func openGhareeb(id: Int, in hadith: HadithEntry) {
        guard let meaning = presentations[hadith.id]?.ghareeb.first(where: { $0.id == id }) else { return }
        openGhareeb(meaning)
    }

    private func openNote(id: Int, in hadith: HadithEntry) {
        guard let note = presentations[hadith.id]?.notes.first(where: { $0.id == id }) else { return }
        openNote(note)
    }

    // MARK: - Progress

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
