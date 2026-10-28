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
    case today
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
    case radio
    case settings

    // MARK: - Adhkar
    case allahNamesTitle
    case allahNamesSubtitle
    case myAdhkarTitle
    case myAdhkarSubtitle
    case dailyAdhkar
    case moreAdhkar
    case adhkarCount
    case tapToCount
    case remaining
    case reciter
    case adhkarCompleted
    case adhkarCompletedMessage
    case repeatAction
    case back

    // MARK: - Athkar hub
    case athkarHubDailyTitle
    case athkarHubDailySubtitle
    case athkarHubCountTitle
    case athkarHubCountSubtitle
    case athkarHubDuaaTitle
    case athkarHubDuaaSubtitle
    case athkarDownloadAll
    case athkarDuaaCount

    // MARK: - Athkar reader
    case athkarReaderPosition
    case athkarReaderProgress
    case athkarReaderTimes
    case athkarReaderTapHint
    case athkarReaderDoneHint
    case athkarReaderMeaning
    case athkarReaderPronunciation
    case athkarReaderSource
    case athkarReaderAddFavorite
    case athkarReaderRemoveFavorite
    case athkarReaderCopy
    case athkarReaderReadAgain
    case athkarReaderCompletedTitle
    case athkarCopied
    case athkarAudioFailed
    case athkarSettingsTitle
    case athkarSettingsTextSize
    case athkarSettingsSizeValue
    case athkarSettingsShowTranslation
    case athkarSettingsStartOver

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
    case searchKeepTyping
    case searchResultsCount
    case searchResultsCountApprox
    case searchBookCount
    case searchBookCountApprox
    case searchSeeAllInBook
    case searchBooksNotInstalled
    case searchDownloadToInclude
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
    case sunrise
    case seeAll
    case hadithSectionNineBooks
    case hadithSectionOtherCollections
    case hadithChapterCount

    // MARK: - Hadith Details
    case hadithTabRulings
    case hadithTabGhareeb
    case hadithTabNotes
    case hadithTabSubjects
    case hadithTabTranslation
    case hadithTabInfo
    case hadithTakhrijSameBook
    case hadithTakhrijCorroborations
    case hadithTakhrijWitnesses
    case hadithTakhrijOther
    case hadithNarratorLayer
    case hadithNarratorKunya
    case hadithNarratorLineage
    case hadithNarratorEpithet
    case hadithNarratorKnownAs
    case hadithNarratorGeneration
    case hadithNarratorCountry
    case hadithNarratorLifespan
    case hadithNarratorBirthPlace
    case hadithNarratorDeathPlace
    case hadithNarratorIbnHajar
    case hadithNarratorVerdictsSummary
    case hadithNarratorVerdicts
    case hadithNarratorSources
    case hadithNarratorNotes
    case hadithNarratorUnknown
    case hadithSource
    case hadithInfoCitation
    case hadithInfoKind
    case hadithInfoBrief
    case hadithInfoChapter
    case hadithInfoNarratedBy
    case hadithGhareebWord
    case hadithNoteTitle
    case hadithDetailsEmpty
    
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

    // MARK: - Reciter / Audio Library
    case reciters
    case close
    case cancel
    case deleteRecitation
    case deleteReciterMessage
    case selectedLabel
    case cancelDownload
    case deleteButton
    case tafsirAudioTitle
    case tafsirAudioSubtitle
    case surahFallback
    case storageManagement
    case downloadedRecitations
    case totalStorageUsed
    case surahsDownloaded
    case noDownloadsTitle
    case noDownloadsMessage
    case minimizePlayer
    case previousVerse
    case nextVerse
    case playbackSpeed
    case pausePlayer

    // MARK: - Lessons Feature
    case islamicLessonsTitle
    case exploreThe
    case wisdomWord
    case searchSheikh
    case filterAllSheikhs
    case filterTafsir
    case filterFiqh
    case filterHadith
    case filterSeerah
    case lessonsCount
    case retryAction
    case lessonsLoadError
    case emptySpecialty

    // MARK: - Sheikh Detail Tabs
    case detailTabPlaylists
    case detailTabVideos
    case detailTabShorts
    case detailTabPodcasts
    case detailTabLive
    case emptyPlaylists
    case emptyVideos
    case emptyShorts
    case emptyPodcasts
    case emptyLive
    case lessonsContentLoadError
    case lessonsQuotaError
    case lessonsLoadMore
    case showMore
    case showLess
    case showMoreHint
    case showLessHint
    case nowPlaying
    case lessonsInSeries
    case playlistDownload
    case playlistSave
    case playlistNotes
    case relatedLessons
    case originalSound

    // MARK: - Radio
    case radioTitle
    case radioSubtitle
    case radioLive
    case radioOffline
    case radioOfflineMessage
    case radioTimedOut
    case radioStreamFailed
    case downloadRecitersAction
    case radioSectionLive
    case radioSectionStations
    case radioSectionDownloaded
    case radioNeedsConnection

    // MARK: - Recitations
    case recitationsSubtitle
    case featuredReciters
    case recitersLoadError
    case currentVerse

    // MARK: - Search
    case searchQuran

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
    case ayahPrefix
    case versesCount
    case noBookmarksYet
    case juz1, juz2, juz3, juz4, juz5
    case juz6, juz7, juz8, juz9, juz10
    case juz11, juz12, juz13, juz14, juz15
    case juz16, juz17, juz18, juz19, juz20
    case juz21, juz22, juz23, juz24, juz25
    case juz26, juz27, juz28, juz29, juz30

    // MARK: - Home Hero
    case homeHeroTitle
    case homeSearchAction
    case homeLocation
    case homeLocationAccessibility
    case locationLabelFormat
    case homeHeroDhikr

    // MARK: - Home Next Prayer
    case nextPrayerLabel
    case leftUntilPrayer
    case hourUnitShort
    case minuteUnitShort
    case prayerTimesUnavailable
    case tryAgainAction

    // MARK: - Home Reading Card
    case readingStartTitle
    case readingStartSubtitle
    case readingStartAction
    case readingContinueAction
    case readingStoppedAt
    case readingQuranPercent

    // MARK: - Home Date
    case homeGregorianFormat
    case homeHijriFormat
    case hijriEraSuffix

    // MARK: - Home Today
    case homeTodayTitle
    case homeTodayPrayersLabel
    case homeTodayQuranLabel
    case prayersCompletedFormat
    case markPrayedAccessibility
    case markNotPrayedAccessibility

    // MARK: - Home Athkar Now
    case homeNowBadge
    case homeAthkarNowSubtitle
    case athkarMorningTitle
    case athkarEveningTitle
    case athkarAfterIshaTitle
    case athkarLastThirdTitle

    // MARK: - Worship Tracker
    case worshipTracker
    case worshipHomeTile
    case worshipYesterday
    case worshipCurrentStreak
    case worshipBestStreak
    case worshipStreaksByCategory
    case worshipLastSevenDays
    case worshipYearOverview
    case worshipTapHint
    case worshipNotOpenYet
    case worshipDisclaimerTitle
    case worshipDisclaimerBody
    case worshipUpdateYesterday
    case worshipBackToToday
    case worshipDaysUnit
    case worshipPrayers
    case worshipAthkar
    case worshipQuran
    case worshipTasbih
    case worshipQuranReading

    // MARK: - Settings
    case settingsSectionQuran
    case settingsSectionWorship
    case settingsSectionGeneral
    case settingsSectionMore
    case settingsQuranPageSubtitle
    case settingsWorshipSubtitle
    case settingsDownloadsEmpty
    case settingsDownloadsUsedFormat
    case settingsLanguageTitle
    case settingsLanguageArabic
    case settingsLanguageEnglish
    case settingsAboutTitle
    case settingsAboutVersionFormat
    case settingsAppTagline
    case settingsAboutBody

    // MARK: - Prayer Times
    case prayerTimesTitle
    case prayerTimesSubtitle
    case prayerTimesScheduleTitle

    // MARK: - Location Picker
    case locationPickerTitle
    case locationCurrentSection
    case locationResultsSection
    case locationUseDevice
    case locationSearchPlaceholder
    case locationNoResults
    case locationPermissionDenied
    case locationOpenSettings
    case locationChangeAction
    case locationAutomaticBadge

    // MARK: - Qibla
    case qiblaTitle
    case qiblaDegreesFormat
    case qiblaAlignHint
    case qiblaAligned
    case qiblaUnavailable
    case qiblaCardinals

    // MARK: - Qibla Guidance
    case qiblaDistanceFormat
    case qiblaElevationFormat
    case qiblaTurnRight
    case qiblaTurnLeft

    // MARK: - Prayer Times Extra Anchors
    case prayerTimesGregorianFormat
    case prayerTimesOtherTimes
    case duha
    case islamicMidnight
    case lastThirdOfNight

    // MARK: - Clock Suffixes
    case clockMorningSuffix
    case clockEveningSuffix

    // MARK: - Prayer Calculation Methods
    case prayerMethodShiaIthnaAshari
    case prayerMethodKarachi
    case prayerMethodNorthAmerica
    case prayerMethodMuslimWorldLeague
    case prayerMethodUmmAlQura
    case prayerMethodEgypt
    case prayerMethodTehran
    case prayerMethodGulfRegion
    case prayerMethodKuwait
    case prayerMethodQatar
    case prayerMethodSingapore
    case prayerMethodFrance
    case prayerMethodTurkey
    case prayerMethodRussia
    case prayerMethodMoonsightingCommittee
    case prayerMethodDubai
    case prayerMethodMalaysia
    case prayerMethodTunisia
    case prayerMethodAlgeria
    case prayerMethodIndonesia
    case prayerMethodMorocco
    case prayerMethodLisbon
    case prayerMethodJordan
    case prayerMethodCustom

    // MARK: - Live Stream

    case liveStreamTitle

    // MARK: - Storage

    case storageCategoryRecitations
    case storageCategoryHadith
    case storageCategoryAthkar
    case storageCategoryTafsir
    case storageFilterAll
    case storageTotalUsed
    case storageScanning
    case storageEmptyTitle
    case storageEmptyMessage
    case storageShowMore
    case storageShowLess
    case storageDeleteAll
    case storageDeleteTitle
    case storageDeleteMessageFormat
    case storageDeleteAllTitle
    case storageDeleteAllMessageFormat

    static func prayerCalculationMethodKey(forMethodId methodId: Int) -> AppLocalizedKeys? {
        let keysByMethodId: [Int: AppLocalizedKeys] = [
            0: .prayerMethodShiaIthnaAshari, 1: .prayerMethodKarachi, 2: .prayerMethodNorthAmerica, 3: .prayerMethodMuslimWorldLeague,
            4: .prayerMethodUmmAlQura, 5: .prayerMethodEgypt, 7: .prayerMethodTehran, 8: .prayerMethodGulfRegion,
            9: .prayerMethodKuwait, 10: .prayerMethodQatar, 11: .prayerMethodSingapore, 12: .prayerMethodFrance,
            13: .prayerMethodTurkey, 14: .prayerMethodRussia, 15: .prayerMethodMoonsightingCommittee, 16: .prayerMethodDubai,
            17: .prayerMethodMalaysia, 18: .prayerMethodTunisia, 19: .prayerMethodAlgeria, 20: .prayerMethodIndonesia,
            21: .prayerMethodMorocco, 22: .prayerMethodLisbon, 23: .prayerMethodJordan, 99: .prayerMethodCustom
        ]
        return keysByMethodId[methodId]
    }

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
