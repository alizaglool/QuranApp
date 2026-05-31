//
//  TafsirViewModel.swift
//  QuranApp
//

import SwiftUI
import Core

private let kSelectedBookId = "selectedTafsirBookId"

@MainActor
final class TafsirViewModel: ObservableObject {

    @Published var text: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedBook: TafsirBook {
        didSet {
            UserDefaults.standard.set(selectedBook.id, forKey: kSelectedBookId)
            if let surah, let verse { load(surah: surah, verse: verse) }
        }
    }

    private var surah: Int?
    private var verse: Int?

    init() {
        let savedId = UserDefaults.standard.string(forKey: kSelectedBookId) ?? ""
        selectedBook = TafsirBook.find(id: savedId) ?? TafsirBook.default
    }

    // MARK: - Load

    func load(surah: Int, verse: Int) {
        self.surah = surah
        self.verse = verse
        errorMessage = nil
        text = ""

        // Try local or downloaded data first — instant, no spinner, no network call.
        if let local = TafsirService.shared.fetchSync(bookId: selectedBook.id, surah: surah, verse: verse) {
            text = local
            isLoading = false
            return
        }

        // Remote books — async network fetch.
        isLoading = true
        Task {
            do {
                text = try await TafsirService.shared.fetch(
                    bookId: selectedBook.id, surah: surah, verse: verse
                )
            } catch {
                errorMessage = "تعذّر تحميل التفسير"
            }
            isLoading = false
        }
    }

    func retry() {
        guard let s = surah, let v = verse else { return }
        load(surah: s, verse: v)
    }
}
