//
//  AppLocalizedKeys.swift
//  ChatRoom
//
//  Created by Ali M. Zaghloul on 23/10/2023.
//


import UIKit

enum AppLocalizedKeys: String {
    // MARK: - Splash
    case appName
    case appNameEnglish
    case downloadingQuran
    case allSurahs
    case search
    case searchSurahOrAyah
    case lastRead
    case progress
    case meccan
    case medinan
    case verses
    case juz
    case page
    case sort
    
    case home
    case assalamuAlaikum
    case welcomeToSanctuary
    case continueReading
    case resume
    case ayahOfTheDay
    case featuredLessons
    case quran
    case adhkar
    case hadith
    case lessons
    case settings
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha
    case seeAll
    
    // MARK: - Verse Action Sheet
    case edit
    case bookmarks
    case allBookmarks
    case redBookmark
    case yellowBookmark
    case greenBookmark
    case blueBookmark
    case recitation
    case playTo
    case play
    case tafsir
    case tafsirSummary
    case tafsirComingSoon
    case library
    case sharing
    case share
    case highlight
    case clearHighlight
    
    var value: String {
        return self.rawValue.localized
    }
}
