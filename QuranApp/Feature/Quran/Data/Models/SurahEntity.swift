//
//  SurahEntity.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation
import SwiftData

@Model
final class SurahEntity {
    @Attribute(.unique) var id: Int
    var nameArabic: String
    var nameEnglish: String
    var meaning: String
    var versesCount: Int
    var isMeccan: Bool
    var startPage: Int
    var endPage: Int
    
    init(
        id: Int,
        nameArabic: String,
        nameEnglish: String,
        meaning: String,
        versesCount: Int,
        isMeccan: Bool,
        startPage: Int,
        endPage: Int
    ) {
        self.id = id
        self.nameArabic = nameArabic
        self.nameEnglish = nameEnglish
        self.meaning = meaning
        self.versesCount = versesCount
        self.isMeccan = isMeccan
        self.startPage = startPage
        self.endPage = endPage
    }
}
