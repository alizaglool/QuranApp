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

    var isTabBarVisible: Bool { true }

    weak var coordinator: HadithCoordinating?
    private let service = HadithDatabaseService.shared

    init(coordinator: HadithCoordinating) {
        self.coordinator = coordinator
    }

    func onAppear() {
        guard books.isEmpty else { return }
        books = service.fetchBooks()
    }

    func selectBook(_ book: HadithBook) {
        coordinator?.coordinateToChapters(book: book)
    }

    func selectSearchResult(_ result: HadithSearchResult) {
        coordinator?.coordinateToReading(hadiths: [result.hadith], startIndex: 0, book: result.book)
    }

    func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        isSearching = !query.isEmpty
        guard isSearching else {
            searchResults = []
            return
        }
        Task {
            let results = await Task.detached(priority: .userInitiated) {
                HadithDatabaseService.shared.search(query: query)
            }.value
            searchResults = results
        }
    }
}
