//
//  AudioModels.swift
//  QuranApp
//

import Foundation
import SwiftData

@Model
final class AudioProgress {
    var surahNumber: Int
    var verseNumber: Int
    var reciterSlug: String
    var playbackSpeed: Float
    var repeatMode: String
    var repeatRangeEnabled: Bool
    var repeatVerseEnabled: Bool
    var repeatFromSurah: Int
    var repeatFromVerse: Int
    var repeatToSurah: Int
    var repeatToVerse: Int
    var rangeRepeatCount: Int
    var verseRepeatCount: Int
    var updatedAt: Date

    init(
        surahNumber: Int = 1,
        verseNumber: Int = 1,
        reciterSlug: String = "Alafasy_128kbps",
        playbackSpeed: Float = 1.0,
        repeatMode: String = "off",
        repeatRangeEnabled: Bool = false,
        repeatVerseEnabled: Bool = false,
        repeatFromSurah: Int = 1,
        repeatFromVerse: Int = 1,
        repeatToSurah: Int = 1,
        repeatToVerse: Int = 7,
        rangeRepeatCount: Int = 0,
        verseRepeatCount: Int = 0
    ) {
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
        self.reciterSlug = reciterSlug
        self.playbackSpeed = playbackSpeed
        self.repeatMode = repeatMode
        self.repeatRangeEnabled = repeatRangeEnabled
        self.repeatVerseEnabled = repeatVerseEnabled
        self.repeatFromSurah = repeatFromSurah
        self.repeatFromVerse = repeatFromVerse
        self.repeatToSurah = repeatToSurah
        self.repeatToVerse = repeatToVerse
        self.rangeRepeatCount = rangeRepeatCount
        self.verseRepeatCount = verseRepeatCount
        self.updatedAt = Date()
    }
}

@Model
final class DownloadedReciter {
    var slug: String
    var name: String
    var arabicName: String
    var downloadedSurahNumbers: [Int]
    var totalSizeBytes: Int64
    var updatedAt: Date

    init(slug: String, name: String, arabicName: String) {
        self.slug = slug
        self.name = name
        self.arabicName = arabicName
        self.downloadedSurahNumbers = []
        self.totalSizeBytes = 0
        self.updatedAt = Date()
    }
}
