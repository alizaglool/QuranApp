//
//  DailyHadithService.swift
//  QuranApp
//

import Foundation
import Core

struct DailyHadith {
    let arabicText: String
    let translation: String
    let reference: String  // e.g. "SAHIH AL-BUKHARI 1"
}

// Deterministic hadith-of-the-day: same hadith all day, changes daily.
// Uses downloaded books when available; falls back to a static list otherwise.

enum DailyHadithService {

    static func hadithForToday() -> DailyHadith {
        let seed = dailySeed()

        let downloadedIds = HadithDownloadManager.shared.downloadedBookIds
        if !downloadedIds.isEmpty {
            let manifest = HadithDatabaseService.shared.loadManifest()
            let books = manifest.filter { downloadedIds.contains($0.id) }

            if !books.isEmpty {
                let bookIndex = Int(seed % UInt64(books.count))
                let book = books[bookIndex]
                let hadithNumber = Int(mix(seed, 1) % UInt64(max(1, book.hadithCount))) + 1

                if let entry = HadithDatabaseService.shared.fetchHadith(bookId: book.id, number: hadithNumber),
                   !entry.arabicText.isEmpty {
                    let isArabic = LocalizationManager.shared.currentLanguage == .Arabic
                    let bookName = isArabic ? book.titleAr : book.titleEn
                    return DailyHadith(
                        arabicText: entry.arabicText,
                        translation: entry.translation.isEmpty ? entry.arabicText : entry.translation,
                        reference: "\(bookName.uppercased()) \(entry.number)"
                    )
                }
            }
        }

        let index = Int(seed % UInt64(staticHadiths.count))
        return staticHadiths[index]
    }

    // MARK: - Seed helpers (same algorithm as DailyVerseService)

    private static func dailySeed() -> UInt64 {
        let hijri = Calendar(identifier: .islamicUmmAlQura)
        let comps = hijri.dateComponents([.year, .month, .day], from: Date())
        let year  = comps.year  ?? 1446
        let month = comps.month ?? 1
        let day   = comps.day   ?? 1

        var s = UInt64(year) &* 10000 &+ UInt64(month) &* 100 &+ UInt64(day)
        s ^= s >> 17; s &*= 0xbf58476d1ce4e5b9
        s ^= s >> 31; s &*= 0x94d049bb133111eb
        s ^= s >> 32
        return s
    }

    private static func mix(_ seed: UInt64, _ salt: UInt64) -> UInt64 {
        var s = seed &+ salt &* 0x9e3779b97f4a7c15
        s ^= s >> 17; s &*= 0xbf58476d1ce4e5b9
        s ^= s >> 31; s &*= 0x94d049bb133111eb
        s ^= s >> 32
        return s
    }

    // MARK: - Static fallback (used when no hadith book is downloaded)

    private static let staticHadiths: [DailyHadith] = [
        DailyHadith(
            arabicText: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى",
            translation: "\"Actions are only by intentions, and every person will have only what they intended.\"",
            reference: "SAHIH AL-BUKHARI 1"
        ),
        DailyHadith(
            arabicText: "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ",
            translation: "\"Whoever takes a path in search of knowledge, Allah will make easy for him a path to Paradise.\"",
            reference: "SAHIH MUSLIM 2699"
        ),
        DailyHadith(
            arabicText: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ",
            translation: "\"The best among you are those who learn the Quran and teach it.\"",
            reference: "SAHIH AL-BUKHARI 5027"
        ),
        DailyHadith(
            arabicText: "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
            translation: "\"None of you truly believes until he loves for his brother what he loves for himself.\"",
            reference: "SAHIH MUSLIM 45"
        ),
        DailyHadith(
            arabicText: "الدِّينُ النَّصِيحَةُ",
            translation: "\"The religion is sincere advice.\"",
            reference: "SAHIH MUSLIM 55"
        ),
        DailyHadith(
            arabicText: "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ",
            translation: "\"Your smile in your brother's face is an act of charity.\"",
            reference: "JAMI AT-TIRMIDHI 1956"
        ),
        DailyHadith(
            arabicText: "يَسِّرُوا وَلَا تُعَسِّرُوا وَبَشِّرُوا وَلَا تُنَفِّرُوا",
            translation: "\"Make things easy and do not make them difficult; give glad tidings and do not drive people away.\"",
            reference: "SAHIH AL-BUKHARI 69"
        ),
        DailyHadith(
            arabicText: "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ",
            translation: "\"Whoever believes in Allah and the Last Day, let him speak good or remain silent.\"",
            reference: "SAHIH AL-BUKHARI 6018"
        ),
        DailyHadith(
            arabicText: "إِنَّ اللَّهَ جَمِيلٌ يُحِبُّ الْجَمَالَ",
            translation: "\"Indeed Allah is beautiful and He loves beauty.\"",
            reference: "SAHIH MUSLIM 91"
        ),
        DailyHadith(
            arabicText: "مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ",
            translation: "\"Whoever fasts Ramadan out of faith and seeking reward, his previous sins are forgiven.\"",
            reference: "SAHIH AL-BUKHARI 38"
        ),
        DailyHadith(
            arabicText: "أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ",
            translation: "\"The most beloved deeds to Allah are those done consistently, even if they are few.\"",
            reference: "SAHIH AL-BUKHARI 6464"
        ),
        DailyHadith(
            arabicText: "الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ",
            translation: "\"A Muslim is the one from whose tongue and hands the Muslims are safe.\"",
            reference: "SAHIH AL-BUKHARI 10"
        ),
        DailyHadith(
            arabicText: "اتَّقِ اللَّهِ حَيْثُمَا كُنْتَ وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا",
            translation: "\"Fear Allah wherever you are, and follow a bad deed with a good one to erase it.\"",
            reference: "JAMI AT-TIRMIDHI 1987"
        ),
        DailyHadith(
            arabicText: "إِنَّ مِنْ أَكْمَلِ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا",
            translation: "\"The most complete of believers in faith are those with the best character.\"",
            reference: "JAMI AT-TIRMIDHI 1162"
        ),
        DailyHadith(
            arabicText: "الطُّهُورُ شَطْرُ الإِيمَانِ",
            translation: "\"Purity is half of faith.\"",
            reference: "SAHIH MUSLIM 223"
        ),
        DailyHadith(
            arabicText: "مَنْ لَا يَرْحَمُ النَّاسَ لَا يَرْحَمُهُ اللَّهُ",
            translation: "\"Whoever does not show mercy to people, Allah will not show mercy to him.\"",
            reference: "SAHIH AL-BUKHARI 7376"
        ),
        DailyHadith(
            arabicText: "أَفْضَلُ الصِّيَامِ بَعْدَ رَمَضَانَ شَهْرُ اللَّهِ الْمُحَرَّمُ",
            translation: "\"The best fasting after Ramadan is the month of Allah, Muharram.\"",
            reference: "SAHIH MUSLIM 1163"
        ),
        DailyHadith(
            arabicText: "مَنْ أَحَبَّ لِقَاءَ اللَّهِ أَحَبَّ اللَّهُ لِقَاءَهُ",
            translation: "\"Whoever loves to meet Allah, Allah loves to meet him.\"",
            reference: "SAHIH AL-BUKHARI 6507"
        ),
        DailyHadith(
            arabicText: "بُنِيَ الإِسْلاَمُ عَلَى خَمْسٍ شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ",
            translation: "\"Islam is built on five: the testimony that there is no god but Allah and Muhammad is His messenger, prayer, zakat, Hajj, and fasting Ramadan.\"",
            reference: "SAHIH AL-BUKHARI 8"
        ),
        DailyHadith(
            arabicText: "كُلُّ أُمَّتِي يَدْخُلُونَ الْجَنَّةَ إِلاَّ مَنْ أَبَى",
            translation: "\"All of my nation will enter Paradise except those who refuse.\" They asked: Who refuses? He said: \"Whoever obeys me enters Paradise, and whoever disobeys me has refused.\"",
            reference: "SAHIH AL-BUKHARI 7280"
        ),
        DailyHadith(
            arabicText: "حُفَّتِ الْجَنَّةُ بِالْمَكَارِهِ وَحُفَّتِ النَّارُ بِالشَّهَوَاتِ",
            translation: "\"Paradise is surrounded by hardships and Hell is surrounded by desires.\"",
            reference: "SAHIH MUSLIM 2822"
        ),
        DailyHadith(
            arabicText: "مَنْ أَرَادَ أَنْ يَنْظُرَ إِلَى رَجُلٍ مِنْ أَهْلِ الْجَنَّةِ فَلْيَنْظُرْ إِلَى هَذَا",
            translation: "\"Whoever wishes to look at a man from the people of Paradise, let him look at this man.\" (Said about a man who never asked people for anything.)",
            reference: "SAHIH AL-BUKHARI 1468"
        ),
        DailyHadith(
            arabicText: "إِنَّ رَبَّكُمْ حَيِيٌّ كَرِيمٌ يَسْتَحِي مِنْ عَبْدِهِ إِذَا رَفَعَ يَدَيْهِ إِلَيْهِ أَنْ يَرُدَّهُمَا صِفْرًا",
            translation: "\"Your Lord is Generous and Kind; He is too shy to turn away the hands of His servant empty when he raises them to Him.\"",
            reference: "SUNAN ABU DAWUD 1488"
        ),
        DailyHadith(
            arabicText: "سَدِّدُوا وَقَارِبُوا وَأَبْشِرُوا فَإِنَّهُ لَا يُدْخِلُ الْجَنَّةَ أَحَدًا عَمَلُهُ",
            translation: "\"Be steadfast, and draw near; give glad tidings, for no one will enter Paradise by his deeds alone.\"",
            reference: "SAHIH AL-BUKHARI 6467"
        ),
        DailyHadith(
            arabicText: "أَرْبَعٌ إِذَا كُنَّ فِيكَ فَلاَ عَلَيْكَ مَا فَاتَكَ مِنَ الدُّنْيَا",
            translation: "\"Four things: if you have them, it does not matter what you have missed of the world — guarding trusts, truthful speech, good character, and restraint in food.\"",
            reference: "MUSNAD AHMAD 6652"
        ),
        DailyHadith(
            arabicText: "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ",
            translation: "\"Charity does not decrease wealth.\"",
            reference: "SAHIH MUSLIM 2588"
        ),
        DailyHadith(
            arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى",
            translation: "\"O Allah, I ask You for guidance, piety, chastity, and self-sufficiency.\"",
            reference: "SAHIH MUSLIM 2721"
        ),
        DailyHadith(
            arabicText: "مَا مَلَأَ آدَمِيٌّ وِعَاءً شَرًّا مِنْ بَطْنٍ",
            translation: "\"No human being has filled a container worse than his stomach.\"",
            reference: "JAMI AT-TIRMIDHI 2380"
        ),
        DailyHadith(
            arabicText: "كُلُّ بَنِي آدَمَ خَطَّاءٌ وَخَيْرُ الْخَطَّائِينَ التَّوَّابُونَ",
            translation: "\"Every son of Adam makes mistakes, and the best of those who make mistakes are those who repent.\"",
            reference: "JAMI AT-TIRMIDHI 2499"
        ),
        DailyHadith(
            arabicText: "إِنَّ اللَّهَ لَا يَنْظُرُ إِلَى أَجْسَادِكُمْ وَلَا إِلَى صُوَرِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ",
            translation: "\"Indeed Allah does not look at your bodies or your forms, but He looks at your hearts.\"",
            reference: "SAHIH MUSLIM 2564"
        ),
        DailyHadith(
            arabicText: "خُذُوا الْعَطَاءَ مَا كَانَ عَطَاءً فَإِذَا كَانَ رِشْوَةً عَنْ دِينِكُمْ فَلَا",
            translation: "\"Take gifts while they are gifts; but when they become bribes for your religion, do not take them.\"",
            reference: "MUSNAD AHMAD 3718"
        )
    ]
}
