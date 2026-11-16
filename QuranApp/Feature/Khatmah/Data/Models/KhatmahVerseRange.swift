//
//  KhatmahVerseRange.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

// MARK: - KhatmahVersePoint

struct KhatmahVersePoint: Equatable {
    let surahNumber: Int
    let surahName: String
    let verseNumber: Int
    let page: Int
}

// MARK: - KhatmahVerseRange

struct KhatmahVerseRange: Equatable {
    let start: KhatmahVersePoint
    let end: KhatmahVersePoint
}
