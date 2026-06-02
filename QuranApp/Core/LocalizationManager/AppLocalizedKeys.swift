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

    // MARK: - Adhkar
    case allahNamesTitle
    case allahNamesSubtitle
    case myAdhkarTitle
    case myAdhkarSubtitle
    case dailyAdhkar
    case adhkarCount
    case tapToCount
    case remaining
    case reciter
    case adhkarCompleted
    case adhkarCompletedMessage
    case repeatAction
    case back

    // MARK: - Hadith
    case hadithCount
    case noResults
    case bookmark
    case hadithGrade
    case narratorChain
    case takhrij
    case commentary
    case marfu
    case hadithNumber
    case hadithLibrary
    case theAuthenticTraditions
    case exploringLegacy
    case searchNarrations
    case propheticNarration
    case authenticCollection
    case resumeReading
    case hadithLibraryQuote
    case originalText
    case scholarlyDetails
    case jumpToHadith
    case go
    case hadithIndexTitle
    case goToHadith
    case tableOfContents
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
    case pause
    case tafsir
    case tafsirSummary
    case tafsirComingSoon
    case library
    case seeMore
    case seeLess
    case sharing
    case share
    case highlight
    case clearHighlight
    case done
    case reciterSelection
    case recitations
    case tafsirAudio
    case downloadJuz
    case repeatSettings
    case rangeSection
    case fromLabel
    case toLabel
    case repeatSection
    case rangeRepeat
    case verseRepeat
    case repetitions
    case chooseVerse
    case endOfPage
    case endOfSurah
    case continuousPlay

    // MARK: - Quran Page Settings Sheet
    case pageSettings
    case mushafOption
    case mushafMadinahSubtitle
    case textMushaf
    case textMushafSubtitle
    case chooseBook
    case chooseBookTitle
    case scrollDirection
    case horizontal
    case vertical
    case theme
    case classicTheme
    case coloredTheme
    case systemAppearance
    case lightAppearance
    case darkAppearance
    case mushafSettings
    case appearance
    case arabicTafsirSection
    case translationsSection

    // MARK: - Surah List Sheet
    case surahIndex
    case surahs
    case quarters
    case pagePrefix
    case versesCount
    case juz1, juz2, juz3, juz4, juz5
    case juz6, juz7, juz8, juz9, juz10
    case juz11, juz12, juz13, juz14, juz15
    case juz16, juz17, juz18, juz19, juz20
    case juz21, juz22, juz23, juz24, juz25
    case juz26, juz27, juz28, juz29, juz30

    static func juzKey(_ number: Int) -> AppLocalizedKeys {
        let keys: [AppLocalizedKeys] = [
            .juz1, .juz2, .juz3, .juz4, .juz5,
            .juz6, .juz7, .juz8, .juz9, .juz10,
            .juz11, .juz12, .juz13, .juz14, .juz15,
            .juz16, .juz17, .juz18, .juz19, .juz20,
            .juz21, .juz22, .juz23, .juz24, .juz25,
            .juz26, .juz27, .juz28, .juz29, .juz30
        ]
        guard number >= 1, number <= 30 else { return .juz1 }
        return keys[number - 1]
    }

    var value: String {
        return self.rawValue.localized
    }
}
