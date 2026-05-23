//
//  StorageManager.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-02.
//


import Foundation
import SwiftData

@MainActor
final class StorageManager: ObservableObject {

    static let shared = StorageManager()

    let container: ModelContainer
    let context: ModelContext

    /// Bumped every time a bookmark is added, removed, or its color changes.
    /// Views that render per-page bookmark indicators observe this so they
    /// re-render automatically after a save.
    @Published private(set) var bookmarksRevision: Int = 0
    
    private init() {
        do {
            let schema = Schema([
                AppSettings.self,
                QuranBookmark.self,
                ReadingProgress.self,
                AdhkarProgress.self
            ])
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            context = container.mainContext
            
            initializeDefaults()
            print("✅ StorageManager initialized")
        } catch {
            fatalError("❌ Failed to create ModelContainer: \(error)")
        }
    }
    
    private func initializeDefaults() {
        if getSettings() == nil {
            let settings = AppSettings()
            context.insert(settings)
            try? context.save()
        }
        
        if getReadingProgress() == nil {
            let progress = ReadingProgress()
            context.insert(progress)
            try? context.save()
        }
    }
    
    // MARK: - Settings
    
    func getSettings() -> AppSettings? {
        let descriptor = FetchDescriptor<AppSettings>()
        return try? context.fetch(descriptor).first
    }
    
    func updateSettings(_ update: (AppSettings) -> Void) {
        guard let settings = getSettings() else { return }
        update(settings)
        try? context.save()
    }
    
    // MARK: - Reading Progress
    
    func getReadingProgress() -> ReadingProgress? {
        let descriptor = FetchDescriptor<ReadingProgress>()
        return try? context.fetch(descriptor).first
    }
    
    func updateReadingProgress(_ update: (ReadingProgress) -> Void) {
        guard let progress = getReadingProgress() else { return }
        update(progress)
        do {
            try context.save()
        } catch {
            print("❌ SwiftData save failed: \(error)")
        }
    }
    
    func forceSave() {
        do {
            try context.save()
        } catch {
            print("❌ Force save failed: \(error)")
        }
    }
    
    // MARK: - Bookmarks
    
    func getAllBookmarks() -> [QuranBookmark] {
        let descriptor = FetchDescriptor<QuranBookmark>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func addBookmark(
        page: Int,
        surahNumber: Int,
        surahName: String,
        ayahNumber: Int? = nil,
        note: String? = nil,
        color: String? = nil
    ) {
        let bookmark = QuranBookmark(
            page: page,
            surahNumber: surahNumber,
            surahName: surahName,
            ayahNumber: ayahNumber,
            note: note,
            color: color
        )
        context.insert(bookmark)
        try? context.save()
        bookmarksRevision &+= 1
    }

    func removeBookmark(_ bookmark: QuranBookmark) {
        context.delete(bookmark)
        try? context.save()
        bookmarksRevision &+= 1
    }

    func isPageBookmarked(_ page: Int) -> Bool {
        let descriptor = FetchDescriptor<QuranBookmark>(
            predicate: #Predicate { $0.page == page }
        )
        return ((try? context.fetch(descriptor))?.count ?? 0) > 0
    }

    /// Returns the existing bookmark matching this verse (page + ayahNumber), if any.
    /// Used to drive "active state" in AllBookmarksView so the user sees which
    /// color is currently set on the verse.
    func getBookmark(page: Int, ayahNumber: Int?) -> QuranBookmark? {
        let descriptor = FetchDescriptor<QuranBookmark>(
            predicate: #Predicate { $0.page == page }
        )
        let matches = (try? context.fetch(descriptor)) ?? []
        return matches.first { $0.ayahNumber == ayahNumber }
    }

    /// Toggle/set a bookmark color for a verse.
    ///
    /// Single-bookmark policy: the app keeps at most ONE bookmark in the
    /// database at any time. Saving a bookmark on a new verse removes any
    /// bookmark that previously existed elsewhere.
    ///
    /// - Same verse + same color → remove (toggle off, zero bookmarks).
    /// - Same verse + different color → update color (still one bookmark).
    /// - Different verse → wipe all existing bookmarks, then insert this one.
    ///
    /// Returns the resulting active color (nil when toggled off).
    @discardableResult
    func setBookmarkColor(
        page: Int,
        surahNumber: Int,
        surahName: String,
        ayahNumber: Int?,
        color: String
    ) -> String? {
        // Case 1 — bookmark already on THIS verse. Toggle / recolor in place.
        if let existing = getBookmark(page: page, ayahNumber: ayahNumber) {
            if existing.color == color {
                context.delete(existing)
                try? context.save()
                bookmarksRevision &+= 1
                return nil
            } else {
                existing.color = color
                try? context.save()
                bookmarksRevision &+= 1
                return color
            }
        }

        // Case 2 — bookmark on a DIFFERENT verse (or no bookmark at all).
        // Enforce "only one bookmark globally" by deleting every existing
        // bookmark before inserting the new one. This is what makes the
        // previous highlight on another page disappear automatically.
        let allDescriptor = FetchDescriptor<QuranBookmark>()
        let existingBookmarks = (try? context.fetch(allDescriptor)) ?? []
        for bm in existingBookmarks {
            context.delete(bm)
        }
        if !existingBookmarks.isEmpty {
            try? context.save()
        }

        // addBookmark already bumps bookmarksRevision and saves.
        addBookmark(
            page: page,
            surahNumber: surahNumber,
            surahName: surahName,
            ayahNumber: ayahNumber,
            color: color
        )
        return color
    }

    /// All bookmarks tied to a given Mushaf page (used to render per-verse markers).
    func getBookmarks(forPage page: Int) -> [QuranBookmark] {
        let descriptor = FetchDescriptor<QuranBookmark>(
            predicate: #Predicate { $0.page == page }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// The single most recently created bookmark across all pages.
    /// Used to drive the "default color" inline shortcut in VerseActionSheet —
    /// whichever color the user picked last becomes the new quick-action default.
    func getMostRecentBookmark() -> QuranBookmark? {
        var descriptor = FetchDescriptor<QuranBookmark>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }
    
    // MARK: - Adhkar
    
    func getAdhkarProgress(for adhkarId: String) -> AdhkarProgress? {
        let descriptor = FetchDescriptor<AdhkarProgress>(
            predicate: #Predicate { $0.adhkarId == adhkarId }
        )
        return try? context.fetch(descriptor).first
    }
    
    func updateAdhkarCount(adhkarId: String, count: Int) {
        if let progress = getAdhkarProgress(for: adhkarId) {
            progress.currentCount = count
            progress.lastUpdated = Date()
        } else {
            let progress = AdhkarProgress(adhkarId: adhkarId, currentCount: count)
            context.insert(progress)
        }
        try? context.save()
    }
}
