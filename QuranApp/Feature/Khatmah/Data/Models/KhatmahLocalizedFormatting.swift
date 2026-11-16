//
//  KhatmahLocalizedFormatting.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - KhatmahLocalizedFormatting

enum KhatmahLocalizedFormatting {

    static var isArabic: Bool {
        LocalizationManager.shared.currentLanguage == .Arabic
    }

    static var locale: Locale {
        Locale(identifier: isArabic ? "ar@numbers=arab" : "en")
    }

    static func number(_ value: Int) -> String {
        isArabic ? value.arabicNumerals : "\(value)"
    }

    static func percent(_ fraction: Double) -> String {
        let percent = Int((fraction * 100).rounded())
        return isArabic ? "\(percent.arabicNumerals)٪" : "\(percent)%"
    }

    static func dayCount(_ count: Int) -> String {
        countLabel(count,
                   one: .khatmahDaysCountOneFormat,
                   two: .khatmahDaysCountTwoFormat,
                   few: .khatmahDaysCountFewFormat,
                   many: .khatmahDaysCountManyFormat)
    }

    static func pageCount(_ count: Int) -> String {
        countLabel(count,
                   one: .khatmahPagesCountOneFormat,
                   two: .khatmahPagesCountTwoFormat,
                   few: .khatmahPagesCountFewFormat,
                   many: .khatmahPagesCountManyFormat)
    }

    static func khatmahCount(_ count: Int) -> String {
        countLabel(count,
                   one: .khatmahCountOneFormat,
                   two: .khatmahCountTwoFormat,
                   few: .khatmahCountFewFormat,
                   many: .khatmahCountManyFormat)
    }

    private static func countLabel(_ count: Int,
                                   one: AppLocalizedKeys,
                                   two: AppLocalizedKeys,
                                   few: AppLocalizedKeys,
                                   many: AppLocalizedKeys) -> String {
        let key: AppLocalizedKeys
        switch count {
        case 1: key = one
        case 2: key = two
        case 3...10: key = few
        default: key = many
        }
        return String(format: key.value, number(count))
    }
}
