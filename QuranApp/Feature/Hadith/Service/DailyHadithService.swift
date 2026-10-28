//
//  DailyHadithService.swift
//  QuranApp
//

import Foundation
import Core

struct DailyHadith {
    let arabicText: String
    let reference: String
}

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
                    return DailyHadith(
                        arabicText: entry.arabicText,
                        reference: "\(book.titleAr) \(entry.number)"
                    )
                }
            }
        }

        let index = Int(seed % UInt64(staticHadiths.count))
        return staticHadiths[index]
    }

    // MARK: - Seed Helpers

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

    // MARK: - Static Fallback

    private static let staticHadiths: [DailyHadith] = [
        DailyHadith(
            arabicText: "إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ وَإِنَّمَا لِكُلِّ امْرِئٍ مَا نَوَى",
            reference: "صحيح البخاري 1"
        ),
        DailyHadith(
            arabicText: "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ",
            reference: "صحيح مسلم 2699"
        ),
        DailyHadith(
            arabicText: "خَيْرُكُمْ مَنْ تَعَلَّمَ الْقُرْآنَ وَعَلَّمَهُ",
            reference: "صحيح البخاري 5027"
        ),
        DailyHadith(
            arabicText: "لَا يُؤْمِنُ أَحَدُكُمْ حَتَّى يُحِبَّ لِأَخِيهِ مَا يُحِبُّ لِنَفْسِهِ",
            reference: "صحيح مسلم 45"
        ),
        DailyHadith(
            arabicText: "الدِّينُ النَّصِيحَةُ",
            reference: "صحيح مسلم 55"
        ),
        DailyHadith(
            arabicText: "تَبَسُّمُكَ فِي وَجْهِ أَخِيكَ لَكَ صَدَقَةٌ",
            reference: "جامع الترمذي 1956"
        ),
        DailyHadith(
            arabicText: "يَسِّرُوا وَلَا تُعَسِّرُوا وَبَشِّرُوا وَلَا تُنَفِّرُوا",
            reference: "صحيح البخاري 69"
        ),
        DailyHadith(
            arabicText: "مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ",
            reference: "صحيح البخاري 6018"
        ),
        DailyHadith(
            arabicText: "إِنَّ اللَّهَ جَمِيلٌ يُحِبُّ الْجَمَالَ",
            reference: "صحيح مسلم 91"
        ),
        DailyHadith(
            arabicText: "مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ",
            reference: "صحيح البخاري 38"
        ),
        DailyHadith(
            arabicText: "أَحَبُّ الأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ",
            reference: "صحيح البخاري 6464"
        ),
        DailyHadith(
            arabicText: "الْمُسْلِمُ مَنْ سَلِمَ الْمُسْلِمُونَ مِنْ لِسَانِهِ وَيَدِهِ",
            reference: "صحيح البخاري 10"
        ),
        DailyHadith(
            arabicText: "اتَّقِ اللَّهِ حَيْثُمَا كُنْتَ وَأَتْبِعِ السَّيِّئَةَ الْحَسَنَةَ تَمْحُهَا",
            reference: "جامع الترمذي 1987"
        ),
        DailyHadith(
            arabicText: "إِنَّ مِنْ أَكْمَلِ الْمُؤْمِنِينَ إِيمَانًا أَحْسَنُهُمْ خُلُقًا",
            reference: "جامع الترمذي 1162"
        ),
        DailyHadith(
            arabicText: "الطُّهُورُ شَطْرُ الإِيمَانِ",
            reference: "صحيح مسلم 223"
        ),
        DailyHadith(
            arabicText: "مَنْ لَا يَرْحَمُ النَّاسَ لَا يَرْحَمُهُ اللَّهُ",
            reference: "صحيح البخاري 7376"
        ),
        DailyHadith(
            arabicText: "أَفْضَلُ الصِّيَامِ بَعْدَ رَمَضَانَ شَهْرُ اللَّهِ الْمُحَرَّمُ",
            reference: "صحيح مسلم 1163"
        ),
        DailyHadith(
            arabicText: "مَنْ أَحَبَّ لِقَاءَ اللَّهِ أَحَبَّ اللَّهُ لِقَاءَهُ",
            reference: "صحيح البخاري 6507"
        ),
        DailyHadith(
            arabicText: "بُنِيَ الإِسْلاَمُ عَلَى خَمْسٍ شَهَادَةِ أَنْ لاَ إِلَهَ إِلاَّ اللَّهُ",
            reference: "صحيح البخاري 8"
        ),
        DailyHadith(
            arabicText: "كُلُّ أُمَّتِي يَدْخُلُونَ الْجَنَّةَ إِلاَّ مَنْ أَبَى",
            reference: "صحيح البخاري 7280"
        ),
        DailyHadith(
            arabicText: "حُفَّتِ الْجَنَّةُ بِالْمَكَارِهِ وَحُفَّتِ النَّارُ بِالشَّهَوَاتِ",
            reference: "صحيح مسلم 2822"
        ),
        DailyHadith(
            arabicText: "مَنْ أَرَادَ أَنْ يَنْظُرَ إِلَى رَجُلٍ مِنْ أَهْلِ الْجَنَّةِ فَلْيَنْظُرْ إِلَى هَذَا",
            reference: "صحيح البخاري 1468"
        ),
        DailyHadith(
            arabicText: "إِنَّ رَبَّكُمْ حَيِيٌّ كَرِيمٌ يَسْتَحِي مِنْ عَبْدِهِ إِذَا رَفَعَ يَدَيْهِ إِلَيْهِ أَنْ يَرُدَّهُمَا صِفْرًا",
            reference: "سنن أبي داود 1488"
        ),
        DailyHadith(
            arabicText: "سَدِّدُوا وَقَارِبُوا وَأَبْشِرُوا فَإِنَّهُ لَا يُدْخِلُ الْجَنَّةَ أَحَدًا عَمَلُهُ",
            reference: "صحيح البخاري 6467"
        ),
        DailyHadith(
            arabicText: "أَرْبَعٌ إِذَا كُنَّ فِيكَ فَلاَ عَلَيْكَ مَا فَاتَكَ مِنَ الدُّنْيَا",
            reference: "مسند أحمد 6652"
        ),
        DailyHadith(
            arabicText: "مَا نَقَصَتْ صَدَقَةٌ مِنْ مَالٍ",
            reference: "صحيح مسلم 2588"
        ),
        DailyHadith(
            arabicText: "اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى",
            reference: "صحيح مسلم 2721"
        ),
        DailyHadith(
            arabicText: "مَا مَلَأَ آدَمِيٌّ وِعَاءً شَرًّا مِنْ بَطْنٍ",
            reference: "جامع الترمذي 2380"
        ),
        DailyHadith(
            arabicText: "كُلُّ بَنِي آدَمَ خَطَّاءٌ وَخَيْرُ الْخَطَّائِينَ التَّوَّابُونَ",
            reference: "جامع الترمذي 2499"
        ),
        DailyHadith(
            arabicText: "إِنَّ اللَّهَ لَا يَنْظُرُ إِلَى أَجْسَادِكُمْ وَلَا إِلَى صُوَرِكُمْ وَلَكِنْ يَنْظُرُ إِلَى قُلُوبِكُمْ",
            reference: "صحيح مسلم 2564"
        ),
        DailyHadith(
            arabicText: "خُذُوا الْعَطَاءَ مَا كَانَ عَطَاءً فَإِذَا كَانَ رِشْوَةً عَنْ دِينِكُمْ فَلَا",
            reference: "مسند أحمد 3718"
        )
    ]
}
