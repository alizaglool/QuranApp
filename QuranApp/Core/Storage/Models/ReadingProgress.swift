//
//  ReadingProgress.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-02.
//


import Foundation
import SwiftData

@Model
final class ReadingProgress {
    var lastPage: Int
    var lastVisitedPage: Int
    var lastSurahNumber: Int
    var lastAyahNumber: Int
    var lastReadDate: Date?
    
    init(
        lastPage: Int = 1,
        lastVisitedPage: Int = 1,
        lastSurahNumber: Int = 1,
        lastAyahNumber: Int = 1
    ) {
        self.lastPage = lastPage
        self.lastVisitedPage = lastVisitedPage
        self.lastSurahNumber = lastSurahNumber
        self.lastAyahNumber = lastAyahNumber
        self.lastReadDate = nil
    }
}