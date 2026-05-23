//
//  LastReadEntity.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation
import SwiftData

@Model
final class LastReadEntity {
    @Attribute(.unique) var id: String = "lastRead"
    var surahId: Int
    var surahNameArabic: String
    var surahNameEnglish: String
    var ayahNumber: Int
    var page: Int
    var juz: Int
    var versesCount: Int
    var timestamp: Date
    
    init(
        surahId: Int,
        surahNameArabic: String,
        surahNameEnglish: String,
        ayahNumber: Int,
        page: Int,
        juz: Int,
        versesCount: Int
    ) {
        self.surahId = surahId
        self.surahNameArabic = surahNameArabic
        self.surahNameEnglish = surahNameEnglish
        self.ayahNumber = ayahNumber
        self.page = page
        self.juz = juz
        self.versesCount = versesCount
        self.timestamp = Date()
    }
}
