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

    public var canDownload: Bool { source.canDownload }

    public static func == (lhs: TafsirBook, rhs: TafsirBook) -> Bool { lhs.id == rhs.id }

    public init(id: String, nameArabic: String, author: String, language: TafsirLanguage, length: TafsirLength?, source: TafsirSource) {
        self.id = id
        self.nameArabic = nameArabic
        self.author = author
        self.language = language
        self.length = length
        self.source = source
    }

    public enum TafsirLanguage {
        case arabic, english, french, german, urdu, turkish, indonesian, spanish

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
            }
        }

        public var isRTL: Bool { self == .arabic || self == .urdu }
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

    // MARK: Arabic tafsirs (brief → detailed, then classical depth)
    static let arabicTafsirs: [TafsirBook] = [
        TafsirBook(id: "ar-mokhtasar",  nameArabic: "المختصر",        author: "دار المختصر",               language: .arabic, length: .brief,    source: .quranEnc(slug: "arabic_mokhtasar")),
        TafsirBook(id: "ar-muyassar",   nameArabic: "التفسير الميسر", author: "مجمع الملك فهد",             language: .arabic, length: .brief,    source: .quranCom(id: 16)),
        TafsirBook(id: "ar-saadi",      nameArabic: "تفسير السعدي",   author: "ابن سعدي (1376هـ)",          language: .arabic, length: .detailed, source: .quranCom(id: 91)),
        TafsirBook(id: "ar-ibn-kathir", nameArabic: "تفسير ابن كثير", author: "ابن كثير الدمشقي (774هـ)",   language: .arabic, length: .detailed, source: .quranCom(id: 14)),
        TafsirBook(id: "ar-baghawi",    nameArabic: "معالم التنزيل",  author: "البغوي (516هـ)",             language: .arabic, length: .detailed, source: .quranCom(id: 94)),
        TafsirBook(id: "ar-qurtubi",    nameArabic: "تفسير القرطبي",  author: "القرطبي (671هـ)",            language: .arabic, length: .detailed, source: .quranCom(id: 90)),
        TafsirBook(id: "ar-tabari",     nameArabic: "جامع البيان",    author: "الطبري (310هـ)",             language: .arabic, length: .detailed, source: .quranCom(id: 15)),
    ]

    // MARK: Translations — per-verse API only (no bulk download)
    static let translations: [TafsirBook] = [
        TafsirBook(id: "en-saheeh",      nameArabic: "Saheeh International",           author: "",                     language: .english,    length: nil, source: .translation(id: 20)),
        TafsirBook(id: "en-hilali-khan", nameArabic: "Hilali & Khan",                  author: "Taqiuddin Al-Hilali",  language: .english,    length: nil, source: .translation(id: 203)),
        TafsirBook(id: "ur-maududi",     nameArabic: "تفہیم القرآن",                  author: "ابوالاعلیٰ مودودی",   language: .urdu,       length: nil, source: .translation(id: 97)),
        TafsirBook(id: "fr-hamidullah",  nameArabic: "Muhammad Hamidullah",            author: "",                     language: .french,     length: nil, source: .translation(id: 31)),
        TafsirBook(id: "de-bubenheim",   nameArabic: "Frank Bubenheim & Nadeem Elyas", author: "",                     language: .german,     length: nil, source: .translation(id: 27)),
        TafsirBook(id: "tr-diyanet",     nameArabic: "Diyanet İşleri",                author: "",                     language: .turkish,    length: nil, source: .translation(id: 77)),
        TafsirBook(id: "id-indonesian",  nameArabic: "Indonesian",                    author: "Kementerian Agama RI", language: .indonesian, length: nil, source: .translation(id: 33)),
    ]

    static var all: [TafsirBook] { arabicTafsirs + translations }

    static var `default`: TafsirBook { arabicTafsirs[0] }

    static func find(id: String) -> TafsirBook? {
        all.first { $0.id == id }
    }
}
