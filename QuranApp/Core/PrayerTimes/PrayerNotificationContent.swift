//
//  PrayerNotificationContent.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

enum PrayerNotificationContentType: String, CaseIterable {
    case hadith
    case dua
    case dhikr
    case quran
    case reminder

    var carriesNarrationSource: Bool {
        switch self {
        case .hadith, .dua, .dhikr: return true
        case .quran, .reminder: return false
        }
    }
}

enum PrayerNotificationContentAuthenticity: String, CaseIterable {
    case agreedUpon
    case sahih
    case quranicText
    case appReminder

    var isNarrationGrading: Bool {
        self == .agreedUpon || self == .sahih
    }

    var arabicLabel: String {
        switch self {
        case .agreedUpon: return "متفق عليه"
        case .sahih: return "صحيح"
        case .quranicText: return "قرآن كريم"
        case .appReminder: return "تذكير"
        }
    }

    var englishLabel: String {
        switch self {
        case .agreedUpon: return "Agreed upon"
        case .sahih: return "Authentic"
        case .quranicText: return "Qur'an"
        case .appReminder: return "Reminder"
        }
    }
}

enum PrayerNotificationContentTag: String, CaseIterable {
    case prayerVirtue
    case congregation
    case voluntaryPrayer
    case khushu
    case nightPrayer
    case morningRemembrance
    case eveningRemembrance
    case forgiveness
    case adhanResponse
    case fridayVirtue
    case quranRecitation
    case preparation
}

struct PrayerNotificationContent: Equatable {

    let id: String
    let type: PrayerNotificationContentType
    let authenticity: PrayerNotificationContentAuthenticity
    let arabicTitle: String
    let englishTitle: String
    let arabicText: String
    let arabicSource: String
    let reference: String
    let tags: Set<PrayerNotificationContentTag>
    let prayerSlots: Set<PrayerSlot>
    let suitableKinds: Set<PrayerNotificationKind>

    var isGeneral: Bool { prayerSlots.isEmpty }

    func suits(slot: PrayerSlot) -> Bool { prayerSlots.contains(slot) }

    func suits(kind: PrayerNotificationKind) -> Bool { suitableKinds.contains(kind) }

    func localizedTitle(isArabic: Bool) -> String {
        isArabic ? arabicTitle : englishTitle
    }
}

// MARK: - Presentation

extension PrayerNotificationContent {

    static let maximumTextLength = 360

    var notificationBody: String {
        guard !arabicSource.isEmpty else { return quotedArabicText }

        return "\(quotedArabicText)\n\(arabicSource)"
    }

    private var quotedArabicText: String {
        switch type {
        case .quran:
            return "\u{FD3E}\(arabicText)\u{FD3F}"
        case .hadith, .dua, .dhikr:
            return "\u{00AB}\(arabicText)\u{00BB}"
        case .reminder:
            return arabicText
        }
    }
}
