//
//  QuranViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-26.
//

import Foundation
import Core
import SwiftUI

@MainActor
final class QuranViewModel: MainViewModel {
    
    @Published var currentPage: Int
    @Published var showOverlay: Bool = false
    @Published var currentSurahName: String = ""
    @Published var currentSurahNumber: Int = 1
    @Published var currentJuz: Int = 1
    @Published var lastVisitedPage: Int = 1
    @Published var selectedVerseID: Int? = nil
    @Published var highlightRects: [VerseHighlightRect] = []
    @Published var selectedPage: Int? = nil
    @Published var showVerseActionSheet: Bool = false
    @Published var selectedVerseSurahName: String = ""
    @Published var selectedVerseSurahNumber: Int = 0
    @Published var selectedVerseNumber: Int = 0

    var isTabBarVisible: Bool { false }
    
    private let quranDB = QuranDatabase.shared
    private let storage = StorageManager.shared
    let totalPages = 604
    
    init(startPage: Int? = nil) {
        let progress = storage.getReadingProgress()
        let savedPage = progress?.lastPage ?? 1
        let savedVisited = progress?.lastVisitedPage ?? 1
        
        let page = startPage ?? savedPage
        self.currentPage = page
        self.lastVisitedPage = savedVisited
        updatePageInfo(page: page)
    }
    
    func onAppear() {}
    
    func updatePageInfo(page: Int) {
        currentPage = page
        
        let surahs = quranDB.getSurahsForPage(page)
        if let firstSurah = surahs.first {
            currentSurahName = firstSurah.arabicTitle
            currentSurahNumber = firstSurah.id
        }
        
        if selectedPage != page {
            clearSelection()
        }
        
        currentJuz = quranDB.getJuz(forPage: page)
        
        storage.updateReadingProgress { progress in
            progress.lastPage = page
            progress.lastSurahNumber = self.currentSurahNumber
            progress.lastReadDate = Date()
        }
    }
    
    func toggleOverlay() {
        showOverlay.toggle()
    }
    
    func goToPage(_ page: Int) {
        guard page >= 1 && page <= totalPages else { return }
        if page != currentPage {
            let previousPage = currentPage
            lastVisitedPage = previousPage
            currentPage = page

            storage.updateReadingProgress { progress in
                progress.lastVisitedPage = previousPage
            }

            updatePageInfo(page: page)
        }
    }
    
    func goToSurah(_ surahNumber: Int) {
        let page = quranDB.getStartPage(forSurah: surahNumber)
        goToPage(page)
    }

    func goToVerse(surah: Int, verse: Int) {
        let page = quranDB.getPage(forSurah: surah, verse: verse)
        goToPage(page)
    }
    
    func swapLastVisitedPage() {
        let temp = currentPage
        let target = lastVisitedPage
        lastVisitedPage = temp
        currentPage = target

        storage.updateReadingProgress { progress in
            progress.lastVisitedPage = temp
        }

        updatePageInfo(page: target)
    }
    
    var currentFirstVerseNumber: Int {
        quranDB.getVersesForPage(currentPage).first?.number ?? 1
    }

    var progressRatio: CGFloat {
        CGFloat(currentPage - 1) / CGFloat(totalPages - 1)
    }
    
    func pageFromDragRatio(_ ratio: CGFloat) -> Int {
        let clamped = max(0, min(1, ratio))
        let page = Int(clamped * CGFloat(totalPages - 1)) + 1
        return max(1, min(totalPages, page))
    }
    
    func selectVerse(atLine line: Int, normalizedX: CGFloat, pageNumber: Int) {
        let highlights = quranDB.getAllHighlightsForPage(pageNumber)
        let verses = quranDB.getVersesForPage(pageNumber)

        for highlight in highlights {
            if highlight.line == line &&
               normalizedX >= CGFloat(highlight.leftVal) &&
               normalizedX <= CGFloat(highlight.rightVal) {

                let verseID = highlight.verseID

                selectedVerseID = verseID
                selectedPage = pageNumber
                highlightRects = highlights.filter { $0.verseID == verseID }

                if let verse = verses.first(where: { $0.verseID == verseID }) {
                    let surahs = quranDB.getSurahsForPage(pageNumber)
                    selectedVerseSurahName = surahs.first(where: { $0.id == verse.chapterNumber })?.arabicTitle ?? ""
                    selectedVerseSurahNumber = verse.chapterNumber
                    selectedVerseNumber = verse.number
                }

                showVerseActionSheet = true
                return
            }
        }
    }

    func clearSelection() {
        selectedVerseID = nil
        selectedPage = nil
        highlightRects = []
    }
    
    func clearTemporaryHighlight() {
        highlightRects = []
        selectedPage = nil
    }
}
