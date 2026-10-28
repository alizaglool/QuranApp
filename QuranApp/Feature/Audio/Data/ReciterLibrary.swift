//
//  ReciterLibrary.swift
//  QuranApp
//

import Foundation

struct ReciterInfo: Identifiable, Hashable, Codable {
    let id: String
    let arabicName: String
    let englishName: String
    let bitrateKbps: Int
    let sizeMB: Int
    let mp3quranId: Int?
    let radioIds: [Int]
    let imageURL: String?

    var estimatedSizeMB: Int { sizeMB }
}

enum ReciterLibrary {

    // MARK: - Catalog

    static var all: [ReciterInfo] {
        catalogLock.lock()
        if let resolved {
            catalogLock.unlock()
            return resolved
        }
        catalogLock.unlock()

        let loaded = ReciterCatalogService.shared.currentReciters()
        let seeded = loaded.isEmpty ? [defaultReciter] : loaded

        catalogLock.lock()
        defer { catalogLock.unlock() }
        if resolved == nil { resolved = seeded }
        return resolved ?? seeded
    }

    static var featured: [FeaturedReciter] {
        ReciterCatalogService.shared.currentFeatured()
    }

    static func reciter(for slug: String) -> ReciterInfo? {
        all.first { $0.id == slug }
    }

    @discardableResult
    static func refreshFromRemote() async -> [ReciterInfo] {
        guard
            let fresh = try? await ReciterCatalogService.shared.refresh(),
            !fresh.isEmpty
        else { return all }

        catalogLock.lock()
        resolved = fresh
        catalogLock.unlock()
        return fresh
    }

    static func warmUp() {
        DispatchQueue.global(qos: .utility).async { _ = all }
    }

    // MARK: - Storage

    private static let catalogLock = NSLock()
    private static var resolved: [ReciterInfo]?

    static let defaultReciter = ReciterInfo(
        id: "Alafasy_128kbps",
        arabicName: "مشاري العفاسي",
        englishName: "Mishary Alafasy",
        bitrateKbps: 128,
        sizeMB: 1667,
        mp3quranId: 123,
        radioIds: [79],
        imageURL: nil
    )

    static func everyAyahURL(reciter: String, surah: Int, verse: Int) -> URL {
        let s = String(format: "%03d", surah)
        let v = String(format: "%03d", verse)
        // Force-unwrap is safe: format string is controlled, always produces valid URL
        return URL(string: "https://everyayah.com/data/\(reciter)/\(s)\(v).mp3")!
    }

    static let surahArabicNames: [Int: String] = [
        1: "الفاتحة", 2: "البقرة", 3: "آل عمران", 4: "النساء", 5: "المائدة",
        6: "الأنعام", 7: "الأعراف", 8: "الأنفال", 9: "التوبة", 10: "يونس",
        11: "هود", 12: "يوسف", 13: "الرعد", 14: "إبراهيم", 15: "الحجر",
        16: "النحل", 17: "الإسراء", 18: "الكهف", 19: "مريم", 20: "طه",
        21: "الأنبياء", 22: "الحج", 23: "المؤمنون", 24: "النور", 25: "الفرقان",
        26: "الشعراء", 27: "النمل", 28: "القصص", 29: "العنكبوت", 30: "الروم",
        31: "لقمان", 32: "السجدة", 33: "الأحزاب", 34: "سبأ", 35: "فاطر",
        36: "يس", 37: "الصافات", 38: "ص", 39: "الزمر", 40: "غافر",
        41: "فصلت", 42: "الشورى", 43: "الزخرف", 44: "الدخان", 45: "الجاثية",
        46: "الأحقاف", 47: "محمد", 48: "الفتح", 49: "الحجرات", 50: "ق",
        51: "الذاريات", 52: "الطور", 53: "النجم", 54: "القمر", 55: "الرحمن",
        56: "الواقعة", 57: "الحديد", 58: "المجادلة", 59: "الحشر", 60: "الممتحنة",
        61: "الصف", 62: "الجمعة", 63: "المنافقون", 64: "التغابن", 65: "الطلاق",
        66: "التحريم", 67: "الملك", 68: "القلم", 69: "الحاقة", 70: "المعارج",
        71: "نوح", 72: "الجن", 73: "المزمل", 74: "المدثر", 75: "القيامة",
        76: "الإنسان", 77: "المرسلات", 78: "النبأ", 79: "النازعات", 80: "عبس",
        81: "التكوير", 82: "الانفطار", 83: "المطففين", 84: "الانشقاق", 85: "البروج",
        86: "الطارق", 87: "الأعلى", 88: "الغاشية", 89: "الفجر", 90: "البلد",
        91: "الشمس", 92: "الليل", 93: "الضحى", 94: "الشرح", 95: "التين",
        96: "العلق", 97: "القدر", 98: "البينة", 99: "الزلزلة", 100: "العاديات",
        101: "القارعة", 102: "التكاثر", 103: "العصر", 104: "الهمزة", 105: "الفيل",
        106: "قريش", 107: "الماعون", 108: "الكوثر", 109: "الكافرون", 110: "النصر",
        111: "المسد", 112: "الإخلاص", 113: "الفلق", 114: "الناس"
    ]

    static let verseCounts: [Int: Int] = [
        1: 7,   2: 286, 3: 200, 4: 176, 5: 120, 6: 165, 7: 206, 8: 75,  9: 129, 10: 109,
        11: 123,12: 111,13: 43, 14: 52, 15: 99, 16: 128,17: 111,18: 110,19: 98, 20: 135,
        21: 112,22: 78, 23: 118,24: 64, 25: 77, 26: 227,27: 93, 28: 88, 29: 69, 30: 60,
        31: 34, 32: 30, 33: 73, 34: 54, 35: 45, 36: 83, 37: 182,38: 88, 39: 75, 40: 85,
        41: 54, 42: 53, 43: 89, 44: 59, 45: 37, 46: 35, 47: 38, 48: 29, 49: 18, 50: 45,
        51: 60, 52: 49, 53: 62, 54: 55, 55: 78, 56: 96, 57: 29, 58: 22, 59: 24, 60: 13,
        61: 14, 62: 11, 63: 11, 64: 18, 65: 12, 66: 12, 67: 30, 68: 52, 69: 52, 70: 44,
        71: 28, 72: 28, 73: 20, 74: 56, 75: 40, 76: 31, 77: 50, 78: 40, 79: 46, 80: 42,
        81: 29, 82: 19, 83: 36, 84: 25, 85: 22, 86: 17, 87: 19, 88: 26, 89: 30, 90: 20,
        91: 15, 92: 21, 93: 11, 94: 8,  95: 8,  96: 19, 97: 5,  98: 8,  99: 8,  100: 11,
        101: 11,102: 8, 103: 3, 104: 9, 105: 5, 106: 4, 107: 7, 108: 3, 109: 6, 110: 3,
        111: 5, 112: 4, 113: 5, 114: 6
    ]
}
