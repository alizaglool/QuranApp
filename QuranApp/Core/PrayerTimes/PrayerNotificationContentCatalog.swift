//
//  PrayerNotificationContentCatalog.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import Foundation

enum PrayerNotificationContentCatalog {

    static let items: [PrayerNotificationContent] = hadiths + supplications + remembrances + verses + reminders

    static func content(dayKey: String,
                        slot: PrayerSlot,
                        kind: PrayerNotificationKind) -> PrayerNotificationContent? {
        PrayerNotificationContentSelector.shared.content(dayKey: dayKey, slot: slot, kind: kind)
    }

    static func body(for content: PrayerNotificationContent) -> String {
        content.notificationBody
    }
}

// MARK: - Hadith

extension PrayerNotificationContentCatalog {

    static let hadiths: [PrayerNotificationContent] = [
        PrayerNotificationContent(id: "hadith_two_cool_prayers",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "صلاة البردين",
                                  englishTitle: "The Two Cool Prayers",
                                  arabicText: "مَنْ صَلَّى الْبَرْدَيْنِ دَخَلَ الْجَنَّةَ",
                                  arabicSource: "رواه البخاري (٥٧٤)",
                                  reference: "Sahih al-Bukhari 574",
                                  tags: [.prayerVirtue],
                                  prayerSlots: [.fajr, .asr],
                                  suitableKinds: [.adhan, .iqamah, .reminder]),

        PrayerNotificationContent(id: "hadith_angels_gather",
                                  type: .hadith,
                                  authenticity: .agreedUpon,
                                  arabicTitle: "تجتمع الملائكة",
                                  englishTitle: "When the Angels Gather",
                                  arabicText: "يَتَعَاقَبُ فِيكُمْ مَلَائِكَةٌ بِاللَّيْلِ وَمَلَائِكَةٌ بِالنَّهَارِ، وَيَجْتَمِعُونَ فِي صَلَاةِ الْفَجْرِ وَصَلَاةِ الْعَصْرِ",
                                  arabicSource: "متفق عليه",
                                  reference: "Agreed upon — al-Bukhari & Muslim",
                                  tags: [.prayerVirtue],
                                  prayerSlots: [.fajr, .asr],
                                  suitableKinds: [.adhan]),

        PrayerNotificationContent(id: "hadith_isha_fajr_congregation",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "كأنما قام الليل",
                                  englishTitle: "As If He Prayed All Night",
                                  arabicText: "مَنْ صَلَّى الْعِشَاءَ فِي جَمَاعَةٍ فَكَأَنَّمَا قَامَ نِصْفَ اللَّيْلِ، وَمَنْ صَلَّى الصُّبْحَ فِي جَمَاعَةٍ فَكَأَنَّمَا صَلَّى اللَّيْلَ كُلَّهُ",
                                  arabicSource: "رواه مسلم (٦٥٦)",
                                  reference: "Sahih Muslim 656",
                                  tags: [.congregation, .prayerVirtue],
                                  prayerSlots: [.fajr, .isha],
                                  suitableKinds: [.adhan, .iqamah]),

        PrayerNotificationContent(id: "hadith_fajr_sunnah_rakahs",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "ركعتا الفجر",
                                  englishTitle: "The Two Rak'ahs of Fajr",
                                  arabicText: "رَكْعَتَا الْفَجْرِ خَيْرٌ مِنَ الدُّنْيَا وَمَا فِيهَا",
                                  arabicSource: "رواه مسلم (٧٢٥)",
                                  reference: "Sahih Muslim 725",
                                  tags: [.voluntaryPrayer, .preparation],
                                  prayerSlots: [.fajr],
                                  suitableKinds: [.reminder]),

        PrayerNotificationContent(id: "hadith_two_rakahs_before_maghrib",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "ركعتان قبل المغرب",
                                  englishTitle: "Two Rak'ahs Before Maghrib",
                                  arabicText: "صَلُّوا قَبْلَ الْمَغْرِبِ رَكْعَتَيْنِ",
                                  arabicSource: "رواه البخاري (١١٨٣)",
                                  reference: "Sahih al-Bukhari 1183",
                                  tags: [.voluntaryPrayer, .preparation],
                                  prayerSlots: [.maghrib],
                                  suitableKinds: [.reminder]),

        PrayerNotificationContent(id: "hadith_five_prayers_expiation",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "كفارة لما بينهن",
                                  englishTitle: "An Expiation for What Lies Between",
                                  arabicText: "الصَّلَوَاتُ الْخَمْسُ، وَالْجُمُعَةُ إِلَى الْجُمُعَةِ، كَفَّارَةٌ لِمَا بَيْنَهُنَّ",
                                  arabicSource: "رواه مسلم (٢٣٣)",
                                  reference: "Sahih Muslim 233",
                                  tags: [.prayerVirtue, .forgiveness],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "hadith_nearest_in_prostration",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "أقرب ما تكون",
                                  englishTitle: "Nearest to Your Lord",
                                  arabicText: "أَقْرَبُ مَا يَكُونُ الْعَبْدُ مِنْ رَبِّهِ وَهُوَ سَاجِدٌ، فَأَكْثِرُوا الدُّعَاءَ",
                                  arabicSource: "رواه مسلم (٤٨٢)",
                                  reference: "Sahih Muslim 482",
                                  tags: [.khushu],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .iqamah]),

        PrayerNotificationContent(id: "hadith_congregation_degrees",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "سبع وعشرون درجة",
                                  englishTitle: "Twenty-Seven Degrees",
                                  arabicText: "صَلَاةُ الْجَمَاعَةِ أَفْضَلُ مِنْ صَلَاةِ الْفَذِّ بِسَبْعٍ وَعِشْرِينَ دَرَجَةً",
                                  arabicSource: "رواه مسلم (٦٥٠)",
                                  reference: "Sahih Muslim 650",
                                  tags: [.congregation, .preparation],
                                  prayerSlots: [],
                                  suitableKinds: [.reminder, .iqamah]),

        PrayerNotificationContent(id: "hadith_walk_calmly",
                                  type: .hadith,
                                  authenticity: .agreedUpon,
                                  arabicTitle: "وعليكم السكينة",
                                  englishTitle: "Come With Tranquillity",
                                  arabicText: "إِذَا أُقِيمَتِ الصَّلَاةُ فَلَا تَأْتُوهَا تَسْعَوْنَ، وَأْتُوهَا تَمْشُونَ وَعَلَيْكُمُ السَّكِينَةُ",
                                  arabicSource: "متفق عليه",
                                  reference: "Agreed upon — al-Bukhari & Muslim",
                                  tags: [.khushu, .congregation],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .iqamah]),

        PrayerNotificationContent(id: "hadith_best_day_friday",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "خير يوم",
                                  englishTitle: "The Best of Days",
                                  arabicText: "خَيْرُ يَوْمٍ طَلَعَتْ عَلَيْهِ الشَّمْسُ يَوْمُ الْجُمُعَةِ",
                                  arabicSource: "رواه مسلم (٨٥٤)",
                                  reference: "Sahih Muslim 854",
                                  tags: [.fridayVirtue],
                                  prayerSlots: [.jumuah],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "hadith_ten_verses_al_kahf",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "عشر آيات من الكهف",
                                  englishTitle: "Ten Verses of Al-Kahf",
                                  arabicText: "مَنْ حَفِظَ عَشْرَ آيَاتٍ مِنْ أَوَّلِ سُورَةِ الْكَهْفِ عُصِمَ مِنَ الدَّجَّالِ",
                                  arabicSource: "رواه مسلم (٨٠٩)",
                                  reference: "Sahih Muslim 809",
                                  tags: [.quranRecitation, .fridayVirtue],
                                  prayerSlots: [.surahAlKahf],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "hadith_descent_last_third",
                                  type: .hadith,
                                  authenticity: .agreedUpon,
                                  arabicTitle: "من يدعوني",
                                  englishTitle: "Who Will Call Upon Me",
                                  arabicText: "يَنْزِلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا حِينَ يَبْقَى ثُلُثُ اللَّيْلِ الْآخِرُ، فَيَقُولُ: مَنْ يَدْعُونِي فَأَسْتَجِيبَ لَهُ، مَنْ يَسْأَلُنِي فَأُعْطِيَهُ، مَنْ يَسْتَغْفِرُنِي فَأَغْفِرَ لَهُ",
                                  arabicSource: "متفق عليه",
                                  reference: "Agreed upon — al-Bukhari & Muslim",
                                  tags: [.nightPrayer, .forgiveness],
                                  prayerSlots: [.lastThirdOfNight],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "hadith_duha_rakahs",
                                  type: .hadith,
                                  authenticity: .sahih,
                                  arabicTitle: "ركعتا الضحى",
                                  englishTitle: "The Two Rak'ahs of Duha",
                                  arabicText: "أَوْصَانِي خَلِيلِي بِثَلَاثٍ: صَوْمِ ثَلَاثَةِ أَيَّامٍ مِنْ كُلِّ شَهْرٍ، وَرَكْعَتَيِ الضُّحَى، وَأَنْ أُوتِرَ قَبْلَ أَنْ أَرْقُدَ",
                                  arabicSource: "رواه البخاري (١١٧٨)",
                                  reference: "Sahih al-Bukhari 1178",
                                  tags: [.voluntaryPrayer, .morningRemembrance],
                                  prayerSlots: [.duha, .sunrise],
                                  suitableKinds: [.adhan, .reminder])
    ]
}

// MARK: - Dua

extension PrayerNotificationContentCatalog {

    static let supplications: [PrayerNotificationContent] = [
        PrayerNotificationContent(id: "dua_after_adhan",
                                  type: .dua,
                                  authenticity: .sahih,
                                  arabicTitle: "دعاء بعد الأذان",
                                  englishTitle: "Supplication After the Adhan",
                                  arabicText: "اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ",
                                  arabicSource: "رواه البخاري (٦١٤)",
                                  reference: "Sahih al-Bukhari 614",
                                  tags: [.adhanResponse],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan]),

        PrayerNotificationContent(id: "dua_entering_mosque",
                                  type: .dua,
                                  authenticity: .sahih,
                                  arabicTitle: "دعاء دخول المسجد",
                                  englishTitle: "On Entering the Mosque",
                                  arabicText: "اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ",
                                  arabicSource: "رواه مسلم (٧١٣)",
                                  reference: "Sahih Muslim 713",
                                  tags: [.congregation, .preparation],
                                  prayerSlots: [],
                                  suitableKinds: [.reminder, .iqamah]),

        PrayerNotificationContent(id: "dua_ibrahim_upholding_prayer",
                                  type: .dua,
                                  authenticity: .quranicText,
                                  arabicTitle: "دعاء إبراهيم",
                                  englishTitle: "The Supplication of Ibrahim",
                                  arabicText: "رَبِّ ٱجْعَلْنِى مُقِيمَ ٱلصَّلَوٰةِ وَمِن ذُرِّيَّتِى ۚ رَبَّنَا وَتَقَبَّلْ دُعَآءِ",
                                  arabicSource: "إبراهيم: ٤٠",
                                  reference: "Ibrahim 14:40",
                                  tags: [.prayerVirtue],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .reminder])
    ]
}

// MARK: - Dhikr

extension PrayerNotificationContentCatalog {

    static let remembrances: [PrayerNotificationContent] = [
        PrayerNotificationContent(id: "dhikr_after_prayer_tasbih",
                                  type: .dhikr,
                                  authenticity: .sahih,
                                  arabicTitle: "تسبيح بعد الصلاة",
                                  englishTitle: "Remembrance After the Prayer",
                                  arabicText: "مَنْ سَبَّحَ اللَّهَ فِي دُبُرِ كُلِّ صَلَاةٍ ثَلَاثًا وَثَلَاثِينَ، وَحَمِدَ اللَّهَ ثَلَاثًا وَثَلَاثِينَ، وَكَبَّرَ اللَّهَ ثَلَاثًا وَثَلَاثِينَ، وَقَالَ: لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ، غُفِرَتْ خَطَايَاهُ",
                                  arabicSource: "رواه مسلم (٥٩٧)",
                                  reference: "Sahih Muslim 597",
                                  tags: [.forgiveness],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan]),

        PrayerNotificationContent(id: "dhikr_tahlil_hundred",
                                  type: .dhikr,
                                  authenticity: .agreedUpon,
                                  arabicTitle: "لا إله إلا الله",
                                  englishTitle: "There Is No God but Allah",
                                  arabicText: "لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ",
                                  arabicSource: "متفق عليه",
                                  reference: "Agreed upon — al-Bukhari & Muslim",
                                  tags: [.morningRemembrance],
                                  prayerSlots: [],
                                  suitableKinds: [.reminder]),

        PrayerNotificationContent(id: "dhikr_two_light_words",
                                  type: .dhikr,
                                  authenticity: .agreedUpon,
                                  arabicTitle: "كلمتان خفيفتان",
                                  englishTitle: "Two Light Words",
                                  arabicText: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
                                  arabicSource: "متفق عليه",
                                  reference: "Agreed upon — al-Bukhari & Muslim",
                                  tags: [.morningRemembrance, .eveningRemembrance],
                                  prayerSlots: [],
                                  suitableKinds: [.reminder]),

        PrayerNotificationContent(id: "dhikr_morning_remembrance",
                                  type: .dhikr,
                                  authenticity: .sahih,
                                  arabicTitle: "أذكار الصباح",
                                  englishTitle: "Morning Remembrance",
                                  arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
                                  arabicSource: "رواه مسلم (٢٧٢٣)",
                                  reference: "Sahih Muslim 2723",
                                  tags: [.morningRemembrance],
                                  prayerSlots: [.sunrise],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "dhikr_evening_remembrance",
                                  type: .dhikr,
                                  authenticity: .sahih,
                                  arabicTitle: "أذكار المساء",
                                  englishTitle: "Evening Remembrance",
                                  arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ",
                                  arabicSource: "رواه مسلم (٢٧٢٣)",
                                  reference: "Sahih Muslim 2723",
                                  tags: [.eveningRemembrance],
                                  prayerSlots: [.maghrib],
                                  suitableKinds: [.adhan, .reminder])
    ]
}

// MARK: - Quran

extension PrayerNotificationContentCatalog {

    static let verses: [PrayerNotificationContent] = [
        PrayerNotificationContent(id: "quran_taha_14",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "وأقم الصلاة لذكري",
                                  englishTitle: "Establish Prayer in My Remembrance",
                                  arabicText: "إِنَّنِىٓ أَنَا ٱللَّهُ لَآ إِلَٰهَ إِلَّآ أَنَا۠ فَٱعْبُدْنِى وَأَقِمِ ٱلصَّلَوٰةَ لِذِكْرِىٓ",
                                  arabicSource: "طه: ١٤",
                                  reference: "Taha 20:14",
                                  tags: [.prayerVirtue, .khushu],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .iqamah, .reminder]),

        PrayerNotificationContent(id: "quran_al_baqarah_153",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "استعينوا بالصبر والصلاة",
                                  englishTitle: "Seek Help Through Patience and Prayer",
                                  arabicText: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوا۟ ٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ ۚ إِنَّ ٱللَّهَ مَعَ ٱلصَّٰبِرِينَ",
                                  arabicSource: "البقرة: ١٥٣",
                                  reference: "Al-Baqarah 2:153",
                                  tags: [.prayerVirtue],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .iqamah, .reminder]),

        PrayerNotificationContent(id: "quran_ar_rad_28",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "تطمئن القلوب",
                                  englishTitle: "Hearts Find Rest",
                                  arabicText: "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ",
                                  arabicSource: "الرعد: ٢٨",
                                  reference: "Ar-Ra'd 13:28",
                                  tags: [.khushu],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .iqamah, .reminder]),

        PrayerNotificationContent(id: "quran_al_isra_78",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "قرآن الفجر",
                                  englishTitle: "The Recitation at Dawn",
                                  arabicText: "أَقِمِ ٱلصَّلَوٰةَ لِدُلُوكِ ٱلشَّمْسِ إِلَىٰ غَسَقِ ٱلَّيْلِ وَقُرْءَانَ ٱلْفَجْرِ ۖ إِنَّ قُرْءَانَ ٱلْفَجْرِ كَانَ مَشْهُودًۭا",
                                  arabicSource: "الإسراء: ٧٨",
                                  reference: "Al-Isra 17:78",
                                  tags: [.quranRecitation],
                                  prayerSlots: [.fajr],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "quran_al_isra_79",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "ومن الليل فتهجد",
                                  englishTitle: "Rise for Prayer in the Night",
                                  arabicText: "وَمِنَ ٱلَّيْلِ فَتَهَجَّدْ بِهِۦ نَافِلَةًۭ لَّكَ عَسَىٰٓ أَن يَبْعَثَكَ رَبُّكَ مَقَامًۭا مَّحْمُودًۭا",
                                  arabicSource: "الإسراء: ٧٩",
                                  reference: "Al-Isra 17:79",
                                  tags: [.nightPrayer],
                                  prayerSlots: [.lastThirdOfNight],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "quran_al_muminun_2",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "في صلاتهم خاشعون",
                                  englishTitle: "Humble in Their Prayer",
                                  arabicText: "ٱلَّذِينَ هُمْ فِى صَلَاتِهِمْ خَٰشِعُونَ",
                                  arabicSource: "المؤمنون: ٢",
                                  reference: "Al-Mu'minun 23:2",
                                  tags: [.khushu],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .iqamah]),

        PrayerNotificationContent(id: "quran_adh_dhariyat_18",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "وبالأسحار",
                                  englishTitle: "In the Hours Before Dawn",
                                  arabicText: "وَبِٱلْأَسْحَارِ هُمْ يَسْتَغْفِرُونَ",
                                  arabicSource: "الذاريات: ١٨",
                                  reference: "Adh-Dhariyat 51:18",
                                  tags: [.nightPrayer, .forgiveness],
                                  prayerSlots: [.lastThirdOfNight],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "quran_al_jumuah_9",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "فاسعوا إلى ذكر الله",
                                  englishTitle: "Hasten to the Remembrance of Allah",
                                  arabicText: "يَٰٓأَيُّهَا ٱلَّذِينَ ءَامَنُوٓا۟ إِذَا نُودِىَ لِلصَّلَوٰةِ مِن يَوْمِ ٱلْجُمُعَةِ فَٱسْعَوْا۟ إِلَىٰ ذِكْرِ ٱللَّهِ وَذَرُوا۟ ٱلْبَيْعَ ۚ ذَٰلِكُمْ خَيْرٌۭ لَّكُمْ إِن كُنتُمْ تَعْلَمُونَ",
                                  arabicSource: "الجمعة: ٩",
                                  reference: "Al-Jumu'ah 62:9",
                                  tags: [.fridayVirtue, .congregation],
                                  prayerSlots: [.jumuah],
                                  suitableKinds: [.adhan, .iqamah, .reminder]),

        PrayerNotificationContent(id: "quran_al_kahf_1",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "فاتحة سورة الكهف",
                                  englishTitle: "The Opening of Al-Kahf",
                                  arabicText: "ٱلْحَمْدُ لِلَّهِ ٱلَّذِىٓ أَنزَلَ عَلَىٰ عَبْدِهِ ٱلْكِتَٰبَ وَلَمْ يَجْعَل لَّهُۥ عِوَجَا",
                                  arabicSource: "الكهف: ١",
                                  reference: "Al-Kahf 18:1",
                                  tags: [.quranRecitation, .fridayVirtue],
                                  prayerSlots: [.surahAlKahf],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "quran_taha_130",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "قبل طلوع الشمس",
                                  englishTitle: "Before the Rising of the Sun",
                                  arabicText: "وَسَبِّحْ بِحَمْدِ رَبِّكَ قَبْلَ طُلُوعِ ٱلشَّمْسِ وَقَبْلَ غُرُوبِهَا",
                                  arabicSource: "طه: ١٣٠",
                                  reference: "Taha 20:130",
                                  tags: [.morningRemembrance],
                                  prayerSlots: [.sunrise],
                                  suitableKinds: [.adhan, .reminder]),

        PrayerNotificationContent(id: "quran_al_anam_162",
                                  type: .quran,
                                  authenticity: .quranicText,
                                  arabicTitle: "إن صلاتي لله",
                                  englishTitle: "My Prayer Is for Allah",
                                  arabicText: "قُلْ إِنَّ صَلَاتِى وَنُسُكِى وَمَحْيَاىَ وَمَمَاتِى لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ",
                                  arabicSource: "الأنعام: ١٦٢",
                                  reference: "Al-An'am 6:162",
                                  tags: [.khushu, .prayerVirtue],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .iqamah, .reminder])
    ]
}

// MARK: - Reminder

extension PrayerNotificationContentCatalog {

    static let reminders: [PrayerNotificationContent] = [
        PrayerNotificationContent(id: "reminder_prepare_wudu",
                                  type: .reminder,
                                  authenticity: .appReminder,
                                  arabicTitle: "استعد للصلاة",
                                  englishTitle: "Get Ready to Pray",
                                  arabicText: "جدد وضوءك واستقبل الصلاة بقلب حاضر.",
                                  arabicSource: "",
                                  reference: "",
                                  tags: [.preparation],
                                  prayerSlots: [],
                                  suitableKinds: [.reminder]),

        PrayerNotificationContent(id: "reminder_set_aside_distractions",
                                  type: .reminder,
                                  authenticity: .appReminder,
                                  arabicTitle: "اترك ما يشغلك",
                                  englishTitle: "Set Distractions Aside",
                                  arabicText: "اترك هاتفك وما يشغلك، ثم أقبل على صلاتك.",
                                  arabicSource: "",
                                  reference: "",
                                  tags: [.khushu, .preparation],
                                  prayerSlots: [],
                                  suitableKinds: [.reminder, .iqamah]),

        PrayerNotificationContent(id: "reminder_remind_your_family",
                                  type: .reminder,
                                  authenticity: .appReminder,
                                  arabicTitle: "ذكّر من حولك",
                                  englishTitle: "Remind Those Around You",
                                  arabicText: "ذكّر أهلك بالصلاة، فالدال على الخير كفاعله.",
                                  arabicSource: "",
                                  reference: "",
                                  tags: [.preparation, .congregation],
                                  prayerSlots: [],
                                  suitableKinds: [.adhan, .reminder])
    ]
}
