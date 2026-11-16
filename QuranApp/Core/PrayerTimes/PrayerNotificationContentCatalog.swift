//
//  PrayerNotificationContentCatalog.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import Foundation

struct PrayerNotificationContent: Equatable {

    let surah: Int
    let ayah: Int
    let arabicText: String
    let englishText: String
    let arabicSurahName: String
    let englishSurahName: String

    var id: String { "\(surah)_\(ayah)" }

    var arabicReference: String { "\(arabicSurahName): \(ayah.arabicNumerals)" }

    var englishReference: String { "\(englishSurahName) \(surah):\(ayah)" }
}

// MARK: - Catalog

enum PrayerNotificationContentCatalog {

    static let verses: [PrayerNotificationContent] = [
        PrayerNotificationContent(surah: 2,
                                  ayah: 238,
                                  arabicText: "حَٰفِظُوا۟ عَلَى ٱلصَّلَوَٰتِ وَٱلصَّلَوٰةِ ٱلْوُسْطَىٰ وَقُومُوا۟ لِلَّهِ قَٰنِتِينَ",
                                  englishText: "Guard the prayers, and the middle prayer, and stand before Allah devoutly obedient.",
                                  arabicSurahName: "البقرة",
                                  englishSurahName: "Al-Baqarah"),
        PrayerNotificationContent(surah: 20,
                                  ayah: 14,
                                  arabicText: "إِنَّنِىٓ أَنَا ٱللَّهُ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعْبُدْنِى وَأَقِمِ ٱلصَّلَوٰةَ لِذِكْرِىٓ",
                                  englishText: "Indeed, I am Allah. There is no god but Me, so worship Me and establish the prayer for My remembrance.",
                                  arabicSurahName: "طه",
                                  englishSurahName: "Taha"),
        PrayerNotificationContent(surah: 70,
                                  ayah: 23,
                                  arabicText: "ٱلَّذِينَ هُمْ عَلَىٰ صَلَاتِهِمْ دَآئِمُونَ",
                                  englishText: "Those who are constant in their prayer.",
                                  arabicSurahName: "المعارج",
                                  englishSurahName: "Al-Ma'arij"),
        PrayerNotificationContent(surah: 70,
                                  ayah: 34,
                                  arabicText: "وَٱلَّذِينَ هُمْ عَلَىٰ صَلَاتِهِمْ يُحَافِظُونَ",
                                  englishText: "And those who carefully guard their prayer.",
                                  arabicSurahName: "المعارج",
                                  englishSurahName: "Al-Ma'arij"),
        PrayerNotificationContent(surah: 23,
                                  ayah: 2,
                                  arabicText: "ٱلَّذِينَ هُمْ فِى صَلَاتِهِمْ خَٰشِعُونَ",
                                  englishText: "Those who are humbly attentive in their prayer.",
                                  arabicSurahName: "المؤمنون",
                                  englishSurahName: "Al-Mu'minun"),
        PrayerNotificationContent(surah: 87,
                                  ayah: 15,
                                  arabicText: "وَذَكَرَ ٱسْمَ رَبِّهِۦ فَصَلَّىٰ",
                                  englishText: "And remembers the name of his Lord, and prays.",
                                  arabicSurahName: "الأعلى",
                                  englishSurahName: "Al-A'la"),
        PrayerNotificationContent(surah: 24,
                                  ayah: 56,
                                  arabicText: "وَأَقِيمُوا۟ ٱلصَّلَوٰةَ وَءَاتُوا۟ ٱلزَّكَوٰةَ وَأَطِيعُوا۟ ٱلرَّسُولَ لَعَلَّكُمْ تُرْحَمُونَ",
                                  englishText: "And establish the prayer, and give the zakah, and obey the Messenger, that you may be shown mercy.",
                                  arabicSurahName: "النور",
                                  englishSurahName: "An-Nur"),
        PrayerNotificationContent(surah: 2,
                                  ayah: 153,
                                  arabicText: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ ٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ ۚ إِنَّ ٱللَّهَ مَعَ ٱلصَّٰبِرِينَ",
                                  englishText: "O you who believe, seek help through patience and prayer. Indeed, Allah is with the patient.",
                                  arabicSurahName: "البقرة",
                                  englishSurahName: "Al-Baqarah"),
        PrayerNotificationContent(surah: 2,
                                  ayah: 45,
                                  arabicText: "وَٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ ۚ وَإِنَّهَا لَكَبِيرَةٌ إِلَّا عَلَى ٱلْخَٰشِعِينَ",
                                  englishText: "And seek help through patience and prayer. It is indeed hard, except for the humble.",
                                  arabicSurahName: "البقرة",
                                  englishSurahName: "Al-Baqarah"),
        PrayerNotificationContent(surah: 17,
                                  ayah: 78,
                                  arabicText: "أَقِمِ ٱلصَّلَوٰةَ لِدُلُوكِ ٱلشَّمْسِ إِلَىٰ غَسَقِ ٱلَّيْلِ وَقُرْءَانَ ٱلْفَجْرِ ۖ إِنَّ قُرْءَانَ ٱلْفَجْرِ كَانَ مَشْهُودًۭا",
                                  englishText: "Establish the prayer from the decline of the sun until the darkness of the night, and the recitation at dawn. Indeed, the recitation at dawn is ever witnessed.",
                                  arabicSurahName: "الإسراء",
                                  englishSurahName: "Al-Isra"),
        PrayerNotificationContent(surah: 17,
                                  ayah: 79,
                                  arabicText: "وَمِنَ ٱلَّيْلِ فَتَهَجَّدْ بِهِۦ نَافِلَةًۭ لَّكَ عَسَىٰٓ أَن يَبْعَثَكَ رَبُّكَ مَقَامًۭا مَّحْمُودًۭا",
                                  englishText: "And rise at night for prayer, as something additional for you; perhaps your Lord will raise you to a praiseworthy station.",
                                  arabicSurahName: "الإسراء",
                                  englishSurahName: "Al-Isra"),
        PrayerNotificationContent(surah: 62,
                                  ayah: 9,
                                  arabicText: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا نُودِىَ لِلصَّلَوٰةِ مِن يَوْمِ ٱلْجُمُعَةِ فَٱسْعَوْا۟ إِلَىٰ ذِكْرِ ٱللَّهِ وَذَرُوا۟ ٱلْبَيْعَ ۚ ذَٰلِكُمْ خَيْرٌۭ لَّكُمْ إِن كُنتُمْ تَعْلَمُونَ",
                                  englishText: "O you who believe, when the call to prayer is made on the day of Jumu'ah, hasten to the remembrance of Allah and leave off trade. That is better for you, if you only knew.",
                                  arabicSurahName: "الجمعة",
                                  englishSurahName: "Al-Jumu'ah"),
        PrayerNotificationContent(surah: 108,
                                  ayah: 2,
                                  arabicText: "فَصَلِّ لِرَبِّكَ وَٱنْحَرْ",
                                  englishText: "So pray to your Lord, and sacrifice.",
                                  arabicSurahName: "الكوثر",
                                  englishSurahName: "Al-Kawthar"),
        PrayerNotificationContent(surah: 14,
                                  ayah: 40,
                                  arabicText: "رَبِّ ٱجْعَلْنِى مُقِيمَ ٱلصَّلَوٰةِ وَمِن ذُرِّيَّتِى ۚ رَبَّنَا وَتَقَبَّلْ دُعَآءِ",
                                  englishText: "My Lord, make me one who keeps up the prayer, and my descendants as well. Our Lord, and accept my supplication.",
                                  arabicSurahName: "إبراهيم",
                                  englishSurahName: "Ibrahim"),
        PrayerNotificationContent(surah: 6,
                                  ayah: 162,
                                  arabicText: "قُلْ إِنَّ صَلَاتِى وَنُسُكِى وَمَحْيَاىَ وَمَمَاتِى لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
                                  englishText: "Say: Indeed, my prayer, my rites, my living and my dying are for Allah, Lord of all the worlds.",
                                  arabicSurahName: "الأنعام",
                                  englishSurahName: "Al-An'am"),
        PrayerNotificationContent(surah: 13,
                                  ayah: 28,
                                  arabicText: "ٱلَّذِينَ ءَامَنُوا۟ وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ ٱللَّهِ ۗ أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
                                  englishText: "Those who believe, and whose hearts find rest in the remembrance of Allah. Surely in the remembrance of Allah do hearts find rest.",
                                  arabicSurahName: "الرعد",
                                  englishSurahName: "Ar-Ra'd")
    ]

    static func content(dayKey: String,
                        slot: PrayerSlot,
                        kind: PrayerNotificationKind) -> PrayerNotificationContent? {
        guard !verses.isEmpty else { return nil }

        let offset = dayOffset(forDayKey: dayKey) + rotationOffset(slot: slot, kind: kind)
        return verses[offset % verses.count]
    }

    static func localizedBody(for content: PrayerNotificationContent, isArabic: Bool) -> String {
        guard isArabic else { return "\u{201C}\(content.englishText)\u{201D}\n\(content.englishReference)" }

        return "\u{FD3E}\(content.arabicText)\u{FD3F}\n\(content.arabicReference)"
    }
}

// MARK: - Deterministic Rotation

private extension PrayerNotificationContentCatalog {

    static func dayOffset(forDayKey dayKey: String) -> Int {
        Int(stableHash(dayKey) % UInt64(verses.count))
    }

    static func rotationOffset(slot: PrayerSlot, kind: PrayerNotificationKind) -> Int {
        let slotIndex = PrayerSlot.allCases.firstIndex(of: slot) ?? 0
        let kindStride = kind == .adhan ? 0 : PrayerSlot.allCases.count

        return slotIndex + kindStride
    }

    static func stableHash(_ value: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325

        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }

        return hash
    }
}
