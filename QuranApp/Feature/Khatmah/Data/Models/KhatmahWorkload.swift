//
//  KhatmahWorkload.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - KhatmahWorkload

enum KhatmahWorkload: Equatable {
    case juz(Int)
    case threeQuarterJuz
    case halfJuz
    case quarterJuz
    case pages(Int)
}

// MARK: - Derivation

extension KhatmahWorkload {

    static let quartersPerJuz = 8
    static let pagesPerQuarterJuz = Double(KhatmahPageBounds.totalPages) / 30.0 / Double(KhatmahWorkload.quartersPerJuz)

    static func forPagesPerDay(_ pagesPerDay: Int) -> KhatmahWorkload {
        guard pagesPerDay > 0 else { return .pages(0) }
        let quarters = Int((Double(pagesPerDay) / KhatmahWorkload.pagesPerQuarterJuz).rounded())
        switch quarters {
        case 2: return .quarterJuz
        case 4: return .halfJuz
        case 6: return .threeQuarterJuz
        case let value where value >= KhatmahWorkload.quartersPerJuz && value % KhatmahWorkload.quartersPerJuz == 0:
            return .juz(value / KhatmahWorkload.quartersPerJuz)
        default: return .pages(pagesPerDay)
        }
    }
}

// MARK: - Localized Label

extension KhatmahWorkload {

    var localizedLabel: String {
        switch self {
        case .quarterJuz:
            return AppLocalizedKeys.khatmahWorkloadQuarterJuz.value
        case .halfJuz:
            return AppLocalizedKeys.khatmahWorkloadHalfJuz.value
        case .threeQuarterJuz:
            return AppLocalizedKeys.khatmahWorkloadThreeQuarterJuz.value
        case .juz(let count):
            return KhatmahWorkload.juzLabel(count)
        case .pages(let count):
            return String(format: AppLocalizedKeys.khatmahPagesPerDayFormat.value, KhatmahLocalizedFormatting.pageCount(count))
        }
    }

    private static func juzLabel(_ count: Int) -> String {
        switch count {
        case 1:
            return AppLocalizedKeys.khatmahWorkloadJuzOne.value
        case 2:
            return AppLocalizedKeys.khatmahWorkloadJuzTwo.value
        case 3...10:
            return String(format: AppLocalizedKeys.khatmahWorkloadJuzFewFormat.value, KhatmahLocalizedFormatting.number(count))
        default:
            return String(format: AppLocalizedKeys.khatmahWorkloadJuzManyFormat.value, KhatmahLocalizedFormatting.number(count))
        }
    }
}
