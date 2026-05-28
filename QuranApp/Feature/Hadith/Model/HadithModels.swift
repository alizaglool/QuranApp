//
//  HadithModels.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import Core

struct HadithBook: Identifiable, Hashable, Codable {
    let id: Int
    let titleAr: String
    let titleEn: String
    let authorAr: String
    let authorEn: String
    let hadithCount: Int
    let chapterCount: Int
    let colorHex: String
    let downloadURL: String
    let fileSizeBytes: Int

    var fileSizeLabel: String {
        guard fileSizeBytes > 0 else { return "" }
        let mb = Double(fileSizeBytes) / 1_048_576
        return String(format: "%.1f MB", mb)
    }

    var title: String  { LocalizationManager.shared.currentLanguage == .Arabic ? titleAr  : titleEn  }
    var author: String { LocalizationManager.shared.currentLanguage == .Arabic ? authorAr : authorEn }
}

struct LastReadPosition: Codable {
    let bookId: Int
    let bookTitleEn: String
    let bookTitleAr: String
    let bookColorHex: String
    let chapterId: Int
    let chapterTitleEn: String
    let chapterTitleAr: String
    let hadithIndex: Int
    let hadithNumber: Int
    let bookHadithCount: Int
    let chapterHadithCount: Int

    var bookTitle: String    { LocalizationManager.shared.currentLanguage == .Arabic ? bookTitleAr    : bookTitleEn    }
    var chapterTitle: String { LocalizationManager.shared.currentLanguage == .Arabic ? chapterTitleAr : chapterTitleEn }
}

struct HadithChapter: Identifiable, Hashable {
    let id: Int
    let bookId: Int
    let number: Int
    let titleAr: String
    let titleEn: String

    var title: String { LocalizationManager.shared.currentLanguage == .Arabic ? titleAr : titleEn }
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
    let gradeEn: String
    let isMarfu: Bool
    let narratorChain: String
    let takhrij: String
    let commentary: String
    let volume: Int
    let pageNo: Int
}

struct HadithSearchResult: Identifiable {
    let id: Int
    let hadith: HadithEntry
    let book: HadithBook
}
