//
//  HadithModels.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation

struct HadithBook: Identifiable, Hashable {
    let id: Int
    let titleAr: String
    let titleEn: String
    let authorAr: String
    let authorEn: String
    let hadithCount: Int
    let colorHex: String
}

struct HadithChapter: Identifiable, Hashable {
    let id: Int
    let bookId: Int
    let number: Int
    let titleAr: String
    let titleEn: String
}

struct HadithEntry: Identifiable, Hashable {
    let id: Int
    let bookId: Int
    let chapterId: Int
    let number: Int
    let arabicText: String
    let translation: String
    let narrator: String
    let grade: String
}

struct HadithSearchResult: Identifiable {
    let id: Int
    let hadith: HadithEntry
    let book: HadithBook
}
