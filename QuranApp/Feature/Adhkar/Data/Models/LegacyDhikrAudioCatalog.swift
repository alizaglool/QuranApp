//
//  LegacyDhikrAudioCatalog.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

// MARK: - Source

struct LegacyDhikrAudioSource: Hashable {

    let packKey: String
    let fileName: String
}

// MARK: - Catalog

enum LegacyDhikrAudioCatalog {

    static func source(forDhikrIdentifier identifier: String) -> LegacyDhikrAudioSource? {
        sources[identifier]
    }

    static let sources: [String: LegacyDhikrAudioSource] = [
        // MARK: evening
        "evening_23":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_001.m4a"),
        "ruqya_quran_10":   LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_002.m4a"),
        "ruqya_quran_9":    LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_003.m4a"),
        "ruqya_quran_8":    LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_004.m4a"),
        "evening_19":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_005.m4a"),
        "evening_18":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_006.m4a"),
        "evening_17":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_007.m4a"),
        "evening_16":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_008.m4a"),
        "evening_15":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_009.m4a"),
        "evening_14":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_010.m4a"),
        "evening_13":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_011.m4a"),
        "evening_12":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_012.m4a"),
        "evening_11":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_013.m4a"),
        "evening_10":       LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_014.m4a"),
        "evening_9":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_015.m4a"),
        "evening_8":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_016.m4a"),
        "evening_7":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_017.m4a"),
        "evening_6":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_018.m4a"),
        "evening_5":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_019.m4a"),
        "evening_4":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_020.m4a"),
        "evening_3":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_021.m4a"),
        "evening_2":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_022.m4a"),
        "evening_1":        LegacyDhikrAudioSource(packKey: "evening", fileName: "evening_023.m4a"),

        // MARK: everyday_duaa
        "prophets_duas_89": LegacyDhikrAudioSource(packKey: "everyday_duaa", fileName: "everyday_duaa_002.m4a"),

        // MARK: last_two_verses
        "last_baqarah_1":   LegacyDhikrAudioSource(packKey: "last_two_verses", fileName: "last_two_verses_001.m4a"),

        // MARK: morning
        "morning_25":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_001.m4a"),
        "morning_21":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_005.m4a"),
        "morning_20":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_006.m4a"),
        "morning_19":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_007.m4a"),
        "morning_18":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_008.m4a"),
        "morning_17":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_009.m4a"),
        "morning_16":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_010.m4a"),
        "morning_15":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_011.m4a"),
        "morning_14":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_012.m4a"),
        "morning_13":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_013.m4a"),
        "morning_12":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_014.m4a"),
        "morning_11":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_015.m4a"),
        "morning_10":       LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_016.m4a"),
        "morning_9":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_017.m4a"),
        "morning_8":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_018.m4a"),
        "morning_7":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_019.m4a"),
        "morning_6":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_020.m4a"),
        "morning_5":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_021.m4a"),
        "morning_4":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_022.m4a"),
        "morning_3":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_023.m4a"),
        "morning_2":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_024.m4a"),
        "morning_1":        LegacyDhikrAudioSource(packKey: "morning", fileName: "morning_025.m4a"),

        // MARK: ruqyah_quran
        "ruqya_quran_18":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_001.m4a"),
        "ruqya_quran_17":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_002.m4a"),
        "ruqya_quran_16":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_003.m4a"),
        "ruqya_quran_15":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_004.m4a"),
        "ruqya_quran_14":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_005.m4a"),
        "ruqya_quran_13":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_006.m4a"),
        "ruqya_quran_12":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_007.m4a"),
        "ruqya_quran_11":   LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_008.m4a"),
        "evening_22":       LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_009.m4a"),
        "morning_24":       LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_009.m4a"),
        "evening_21":       LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_010.m4a"),
        "morning_23":       LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_010.m4a"),
        "evening_20":       LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_011.m4a"),
        "morning_22":       LegacyDhikrAudioSource(packKey: "ruqyah_quran", fileName: "ruqyah_quran_011.m4a"),

        // MARK: ruqyah_sunnah
        "ruqya_sunnah_12":  LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_001.m4a"),
        "ruqya_sunnah_11":  LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_002.m4a"),
        "ruqya_sunnah_10":  LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_003.m4a"),
        "ruqya_sunnah_9":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_004.m4a"),
        "ruqya_sunnah_8":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_005.m4a"),
        "ruqya_sunnah_7":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_006.m4a"),
        "ruqya_sunnah_6":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_007.m4a"),
        "ruqya_sunnah_5":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_008.m4a"),
        "ruqya_sunnah_4":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_009.m4a"),
        "ruqya_sunnah_3":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_010.m4a"),
        "ruqya_sunnah_2":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_011.m4a"),
        "ruqya_sunnah_1":   LegacyDhikrAudioSource(packKey: "ruqyah_sunnah", fileName: "ruqyah_sunnah_012.m4a"),

        // MARK: sleep
        "sleep_19":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_001.m4a"),
        "sleep_18":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_002.m4a"),
        "sleep_17":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_003.m4a"),
        "sleep_16":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_004.m4a"),
        "sleep_15":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_005.m4a"),
        "sleep_14":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_006.m4a"),
        "sleep_13":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_007.m4a"),
        "sleep_12":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_008.m4a"),
        "sleep_11":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_009.m4a"),
        "sleep_10":         LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_010.m4a"),
        "sleep_9":          LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_011.m4a"),
        "sleep_8":          LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_012.m4a"),
        "sleep_7":          LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_013.m4a"),
        "sleep_6":          LegacyDhikrAudioSource(packKey: "sleep", fileName: "sleep_014.m4a"),

        // MARK: wake_up
        "night_quran_4":    LegacyDhikrAudioSource(packKey: "wake_up", fileName: "wake_up_001.m4a"),
        "night_quran_3":    LegacyDhikrAudioSource(packKey: "wake_up", fileName: "wake_up_002.m4a"),
        "night_quran_2":    LegacyDhikrAudioSource(packKey: "wake_up", fileName: "wake_up_003.m4a"),
        "night_quran_1":    LegacyDhikrAudioSource(packKey: "wake_up", fileName: "wake_up_004.m4a")
    ]
}
