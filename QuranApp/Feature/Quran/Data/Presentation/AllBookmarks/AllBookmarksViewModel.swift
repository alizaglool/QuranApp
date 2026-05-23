//
//  AllBookmarksViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-21.
//

import SwiftUI
import Core

// MARK: - Model

struct BookmarkType: Identifiable {
    let id = UUID()
    let titleKey: AppLocalizedKeys
    let color: Color
    /// Persistence key — matches BookmarkColor cases ("red"/"yellow"/"green"/"blue").
    let storageKey: String
}

// MARK: - ViewModel

@MainActor
final class AllBookmarksViewModel: ObservableObject {

    // Verse identity — needed to persist the bookmark.
    let page: Int
    let surahNumber: Int
    let surahName: String
    let verseNumber: Int

    /// The four bookmark categories shown in the list
    let bookmarks: [BookmarkType] = [
        BookmarkType(titleKey: .redBookmark,    color: .red,    storageKey: BookmarkColor.red.rawValue),
        BookmarkType(titleKey: .yellowBookmark, color: .yellow, storageKey: BookmarkColor.yellow.rawValue),
        BookmarkType(titleKey: .greenBookmark,  color: .green,  storageKey: BookmarkColor.green.rawValue),
        BookmarkType(titleKey: .blueBookmark,   color: .blue,   storageKey: BookmarkColor.blue.rawValue)
    ]

    /// The currently saved color for this verse (nil when no bookmark is set).
    /// Drives the active checkmark in the row UI.
    @Published private(set) var activeColor: String?

    private let storage = StorageManager.shared

    init(page: Int, surahNumber: Int, surahName: String, verseNumber: Int) {
        self.page = page
        self.surahNumber = surahNumber
        self.surahName = surahName
        self.verseNumber = verseNumber

        // Load existing color (if any) so the checkmark renders correctly on open.
        self.activeColor = storage
            .getBookmark(page: page, ayahNumber: verseNumber)?
            .color
    }

    /// Returns true when the given bookmark category is the saved one for this verse.
    func isActive(_ bookmark: BookmarkType) -> Bool {
        activeColor == bookmark.storageKey
    }

    /// Toggle/set the bookmark color via StorageManager. Refreshes `activeColor`
    /// so the View re-renders the active state.
    func selectBookmark(_ bookmark: BookmarkType) {
        let resulting = storage.setBookmarkColor(
            page: page,
            surahNumber: surahNumber,
            surahName: surahName,
            ayahNumber: verseNumber,
            color: bookmark.storageKey
        )
        activeColor = resulting
    }

    func navigateToVerse() {
        // TODO: dismiss sheet and jump to verse in QuranPagerView
        print("📖 Navigate to \(surahName): \(verseNumber)")
    }
}
