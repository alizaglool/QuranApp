//
//  TafsirBook.swift
//  Core
//

import Foundation

// MARK: - TafsirSource

public enum TafsirSource: Equatable {
    case quranEnc(slug: String)  // quranenc.com — plain text, bulk download via /translation/sura/{slug}/{chapter}
    case quranCom(id: Int)       // api.quran.com/api/v4/tafsirs/{id} — HTML, bulk download via /by_chapter
    case translation(id: Int)    // api.quran.com/api/v4/translations/{id} — HTML, per-verse only

    public var canDownload: Bool {
        if case .translation = self { return false }
        return true
    }
}

// MARK: - TafsirBook

public struct TafsirBook: Identifiable, Equatable {
    public let id: String          // local key — UserDefaults key, downloaded filename
    public let nameArabic: String
    public let author: String
    public let language: TafsirLanguage
    public let length: TafsirLength?
    public let source: TafsirSource
    /// True = JSON is bundled inside the app (no download needed). Currently only ar-mokhtasar.
    public let isBundle: Bool
    /// GitHub raw URL for single-file download. Empty for translations and bundled books.
    public let downloadURL: String

    /// Can the user trigger a download? Only books with a non-empty downloadURL that aren't bundled.
    public var canDownload: Bool { !isBundle && !downloadURL.isEmpty }

    public static func == (lhs: TafsirBook, rhs: TafsirBook) -> Bool { lhs.id == rhs.id }

    public init(
        id: String,
        nameArabic: String,
        author: String,
        language: TafsirLanguage,
        length: TafsirLength?,
        source: TafsirSource,
        isBundle: Bool = false,
        downloadURL: String = ""
    ) {
        self.id = id
        self.nameArabic = nameArabic
        self.author = author
        self.language = language
        self.length = length
        self.source = source
        self.isBundle = isBundle
        self.downloadURL = downloadURL
    }

    public enum TafsirLanguage {
        case arabic, english, french, german, urdu, turkish, indonesian, spanish
        case bengali, russian, persian, malay, chinese, italian, somali, swahili

        public var displayName: String {
            switch self {
            case .arabic:     return "العربية"
            case .english:    return "English"
            case .french:     return "Français"
            case .german:     return "Deutsch"
            case .urdu:       return "اردو"
            case .turkish:    return "Türkçe"
            case .indonesian: return "Indonesia"
            case .spanish:    return "Español"
            case .bengali:    return "বাংলা"
            case .russian:    return "Русский"
            case .persian:    return "فارسی"
            case .malay:      return "Melayu"
            case .chinese:    return "中文"
            case .italian:    return "Italiano"
            case .somali:     return "Soomaali"
            case .swahili:    return "Kiswahili"
            }
        }

        public var isRTL: Bool { self == .arabic || self == .urdu || self == .persian }
    }

    public enum TafsirLength {
        case brief, detailed

        public var label: String {
            switch self {
            case .brief:    return "مختصر"
            case .detailed: return "موسع"
            }
        }
    }
}

// MARK: - Book Catalogue

public extension TafsirBook {

    private static let githubBase = "https://raw.githubusercontent.com/alizaglool/tafsir-books/main"

    // MARK: Arabic tafsirs (brief → detailed, then classical depth)
    static let arabicTafsirs: [TafsirBook] = [
        // Bundled in app — always available, no download needed
        TafsirBook(id: "ar-mokhtasar",  nameArabic: "المختصر",        author: "دار المختصر",             language: .arabic, length: .brief,    source: .quranEnc(slug: "arabic_mokhtasar"), isBundle: true),
        // GitHub-hosted — single-file download
        TafsirBook(id: "ar-muyassar",   nameArabic: "التفسير الميسر", author: "مجمع الملك فهد",           language: .arabic, length: .brief,    source: .quranCom(id: 16),  downloadURL: "\(githubBase)/ar-muyassar.json"),
        TafsirBook(id: "ar-saadi",      nameArabic: "تفسير السعدي",   author: "ابن سعدي (1376هـ)",        language: .arabic, length: .detailed, source: .quranCom(id: 91),  downloadURL: "\(githubBase)/ar-saadi.json"),
        TafsirBook(id: "ar-ibn-kathir", nameArabic: "تفسير ابن كثير", author: "ابن كثير الدمشقي (774هـ)", language: .arabic, length: .detailed, source: .quranCom(id: 14),  downloadURL: "\(githubBase)/ar-ibn-kathir.json"),
        TafsirBook(id: "ar-jalalyn",    nameArabic: "تفسير الجلالين",  author: "الجلالين",               language: .arabic, length: .brief,    source: .quranCom(id: 74),  downloadURL: "\(githubBase)/ar-jalalyn.json"),
        TafsirBook(id: "ar-baghawi",    nameArabic: "معالم التنزيل",  author: "البغوي (516هـ)",           language: .arabic, length: .detailed, source: .quranCom(id: 94),  downloadURL: "\(githubBase)/ar-baghawi.json"),
        TafsirBook(id: "ar-qurtubi",    nameArabic: "تفسير القرطبي",  author: "القرطبي (671هـ)",          language: .arabic, length: .detailed, source: .quranCom(id: 90),  downloadURL: "\(githubBase)/ar-qurtubi.json"),
        TafsirBook(id: "ar-tabari",     nameArabic: "جامع البيان",    author: "الطبري (310هـ)",           language: .arabic, length: .detailed, source: .quranCom(id: 15),  downloadURL: "\(githubBase)/ar-tabari.json"),
        TafsirBook(id: "ar-ibn-ashur",  nameArabic: "تفسير ابن عاشور", author: "ابن عاشور (1393هـ)",      language: .arabic, length: .detailed, source: .quranCom(id: 92),  downloadURL: "\(githubBase)/ar-ibn-ashur.json"),
    ]

    // MARK: Translations — downloadable from GitHub; live API fallback when not downloaded
    static let translations: [TafsirBook] = [
        // English
        TafsirBook(id: "en-saheeh",      nameArabic: "Saheeh International",           author: "",                     language: .english,    length: nil, source: .translation(id: 20),  downloadURL: "\(githubBase)/en-saheeh.json"),
        TafsirBook(id: "en-hilali-khan", nameArabic: "Hilali & Khan",                  author: "Taqiuddin Al-Hilali",  language: .english,    length: nil, source: .translation(id: 203), downloadURL: "\(githubBase)/en-hilali-khan.json"),
        TafsirBook(id: "en-pickthall",   nameArabic: "Pickthall",                      author: "Mohammed Pickthall",   language: .english,    length: nil, source: .translation(id: 57),  downloadURL: "\(githubBase)/en-pickthall.json"),
        TafsirBook(id: "en-yusuf-ali",   nameArabic: "Yusuf Ali",                      author: "Abdullah Yusuf Ali",   language: .english,    length: nil, source: .translation(id: 56),  downloadURL: "\(githubBase)/en-yusuf-ali.json"),
        TafsirBook(id: "en-khattab",     nameArabic: "The Clear Quran",                author: "Dr. Mustafa Khattab",  language: .english,    length: nil, source: .translation(id: 131), downloadURL: "\(githubBase)/en-khattab.json"),
        TafsirBook(id: "en-usmani",      nameArabic: "Mufti Taqi Usmani",              author: "Mufti Taqi Usmani",    language: .english,    length: nil, source: .translation(id: 84),  downloadURL: "\(githubBase)/en-usmani.json"),
        TafsirBook(id: "en-haleem",      nameArabic: "Abdel Haleem",                   author: "M.A.S. Abdel Haleem",  language: .english,    length: nil, source: .translation(id: 85),  downloadURL: "\(githubBase)/en-haleem.json"),
        // Urdu
        TafsirBook(id: "ur-maududi",     nameArabic: "تفہیم القرآن",                  author: "ابوالاعلیٰ مودودی",   language: .urdu,       length: nil, source: .translation(id: 97),  downloadURL: "\(githubBase)/ur-maududi.json"),
        TafsirBook(id: "ur-junagarhi",   nameArabic: "جوناگڑھی",                      author: "محمد جوناگڑھی",        language: .urdu,       length: nil, source: .translation(id: 98),  downloadURL: "\(githubBase)/ur-junagarhi.json"),
        TafsirBook(id: "ur-jalandhari",  nameArabic: "جالندھری",                      author: "فتح محمد جالندھری",   language: .urdu,       length: nil, source: .translation(id: 234), downloadURL: "\(githubBase)/ur-jalandhari.json"),
        // Other languages
        TafsirBook(id: "fr-hamidullah",  nameArabic: "Muhammad Hamidullah",            author: "",                     language: .french,     length: nil, source: .translation(id: 31),  downloadURL: "\(githubBase)/fr-hamidullah.json"),
        TafsirBook(id: "de-bubenheim",   nameArabic: "Frank Bubenheim & Nadeem Elyas", author: "",                     language: .german,     length: nil, source: .translation(id: 27),  downloadURL: "\(githubBase)/de-bubenheim.json"),
        TafsirBook(id: "tr-diyanet",     nameArabic: "Diyanet İşleri",                author: "",                     language: .turkish,    length: nil, source: .translation(id: 77),  downloadURL: "\(githubBase)/tr-diyanet.json"),
        TafsirBook(id: "id-indonesian",  nameArabic: "Indonesian",                     author: "Kementerian Agama RI", language: .indonesian, length: nil, source: .translation(id: 33),  downloadURL: "\(githubBase)/id-indonesian.json"),
        TafsirBook(id: "ms-basmeih",     nameArabic: "Basmeih",                        author: "Abdullah Muhammad Basmeih", language: .malay,  length: nil, source: .translation(id: 39),  downloadURL: "\(githubBase)/ms-basmeih.json"),
        TafsirBook(id: "es-cortes",      nameArabic: "Julio Cortés",                   author: "Julio Cortés",         language: .spanish,    length: nil, source: .translation(id: 83),  downloadURL: "\(githubBase)/es-cortes.json"),
        TafsirBook(id: "ru-kuliev",      nameArabic: "Эльмир Кулиев",                  author: "Эльмир Кулиев",        language: .russian,    length: nil, source: .translation(id: 79),  downloadURL: "\(githubBase)/ru-kuliev.json"),
        TafsirBook(id: "bn-muhiuddin",   nameArabic: "মুহিউদ্দীন খান",               author: "মুহিউদ্দীন খান",      language: .bengali,    length: nil, source: .translation(id: 161), downloadURL: "\(githubBase)/bn-muhiuddin.json"),
        TafsirBook(id: "fa-islamhouse",  nameArabic: "ترجمه الهی قمشه‌ای",            author: "الهی قمشه‌ای",        language: .persian,    length: nil, source: .translation(id: 29),  downloadURL: "\(githubBase)/fa-islamhouse.json"),
        TafsirBook(id: "zh-majain",      nameArabic: "马坚",                           author: "马坚",                 language: .chinese,    length: nil, source: .translation(id: 76),  downloadURL: "\(githubBase)/zh-majain.json"),
        TafsirBook(id: "it-piccardo",    nameArabic: "Hamza Piccardo",                 author: "Hamza Piccardo",       language: .italian,    length: nil, source: .translation(id: 149), downloadURL: "\(githubBase)/it-piccardo.json"),
        TafsirBook(id: "so-barwani",     nameArabic: "Abduh Barwani (Somali)",          author: "Abduh Barwani",        language: .somali,     length: nil, source: .translation(id: 67),  downloadURL: "\(githubBase)/so-barwani.json"),
        TafsirBook(id: "sw-barwani",     nameArabic: "Abduh Barwani (Swahili)",         author: "Abduh Barwani",        language: .swahili,    length: nil, source: .translation(id: 68),  downloadURL: "\(githubBase)/sw-barwani.json"),
    ]

    static var all: [TafsirBook] { arabicTafsirs + translations }

    static var `default`: TafsirBook { arabicTafsirs[0] }

    static func find(id: String) -> TafsirBook? {
        all.first { $0.id == id }
    }
}
