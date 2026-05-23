//
//  QuranBookmark.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-02.
//


import Foundation
import SwiftData

@Model
final class QuranBookmark {
    var page: Int
    var surahNumber: Int
    var surahName: String
    var ayahNumber: Int?
    var note: String?
    var createdAt: Date
    /// Bookmark category color — one of "red", "yellow", "green", "blue".
    /// Optional so existing rows from older builds (pre-color) remain valid.
    var color: String?

    init(
        page: Int,
        surahNumber: Int,
        surahName: String,
        ayahNumber: Int? = nil,
        note: String? = nil,
        color: String? = nil
    ) {
        self.page = page
        self.surahNumber = surahNumber
        self.surahName = surahName
        self.ayahNumber = ayahNumber
        self.note = note
        self.createdAt = Date()
        self.color = color
    }
}

// MARK: - Color category helpers

enum BookmarkColor: String, CaseIterable {
    case red, yellow, green, blue
}