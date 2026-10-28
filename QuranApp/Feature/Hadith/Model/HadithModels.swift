//
//  HadithModels.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import Core

// MARK: - Book

struct HadithBook: Identifiable, Hashable {
    let id: Int
    /// Where the book sits in the library, which is the scholarly order of the
    /// nine books followed by the shorter collections — not the id order.
    var sort: Int = 0
    let titleAr: String
    let titleEn: String
    let authorAr: String
    let authorEn: String
    let hadithCount: Int
    let chapterCount: Int
    let colorHex: String
    let downloadURL: String
    /// The size of the download, which is gzipped.
    let fileSizeBytes: Int
    /// What the book takes up once installed. Five times the download for the
    /// big books, so the reader is told this number before, not after.
    var installedSizeBytes: Int = 0
    /// True only for the later collections, which ship an English column. The
    /// nine core books are Arabic only and their translation block is hidden.
    var hasTranslation: Bool = false
    /// Checked against the file that arrives, before un-gzipping it.
    var gzSha256: String = ""
    /// Checked against the un-gzipped database, before it is opened.
    var dbSha256: String = ""

    var fileSizeLabel: String { HadithByteSize.label(fileSizeBytes) }

    var installedSizeLabel: String { HadithByteSize.label(installedSizeBytes) }

    var title: String  { LocalizationManager.shared.currentLanguage == .Arabic ? titleAr  : titleEn  }
    var author: String { LocalizationManager.shared.currentLanguage == .Arabic ? authorAr : authorEn }
}

// MARK: Book · decoding

/// Decoded by hand so that a manifest written by an older or a newer build
/// still loads: every field added after the first release is optional and
/// falls back to the property's default. The synthesised `Decodable` would
/// ignore those defaults and fail the whole manifest on one missing key.
extension HadithBook: Codable {

    private enum CodingKeys: String, CodingKey {
        case id, sort, titleAr, titleEn, authorAr, authorEn
        case hadithCount, chapterCount, colorHex, downloadURL
        case fileSizeBytes, installedSizeBytes, hasTranslation
        case gzSha256, dbSha256
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id            = try container.decode(Int.self, forKey: .id)
        sort          = try container.decodeIfPresent(Int.self, forKey: .sort) ?? 0
        titleAr       = try container.decode(String.self, forKey: .titleAr)
        titleEn       = try container.decode(String.self, forKey: .titleEn)
        authorAr      = try container.decodeIfPresent(String.self, forKey: .authorAr) ?? ""
        authorEn      = try container.decodeIfPresent(String.self, forKey: .authorEn) ?? ""
        hadithCount   = try container.decodeIfPresent(Int.self, forKey: .hadithCount) ?? 0
        chapterCount  = try container.decodeIfPresent(Int.self, forKey: .chapterCount) ?? 0
        colorHex      = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? ""
        downloadURL   = try container.decodeIfPresent(String.self, forKey: .downloadURL) ?? ""
        fileSizeBytes = try container.decodeIfPresent(Int.self, forKey: .fileSizeBytes) ?? 0
        installedSizeBytes = try container.decodeIfPresent(Int.self, forKey: .installedSizeBytes) ?? 0
        hasTranslation = try container.decodeIfPresent(Bool.self, forKey: .hasTranslation) ?? false
        gzSha256      = try container.decodeIfPresent(String.self, forKey: .gzSha256) ?? ""
        dbSha256      = try container.decodeIfPresent(String.self, forKey: .dbSha256) ?? ""
    }
}

// MARK: - Last read

struct LastReadPosition: Codable {
    let bookId: Int
    let bookTitleEn: String
    let bookTitleAr: String
    let bookColorHex: String
    let chapterId: Int
    let chapterTitleEn: String
    let chapterTitleAr: String
    let hadithIndex: Int
    let hadithNumber: Int
    let bookHadithCount: Int
    let chapterHadithCount: Int

    var bookTitle: String    { LocalizationManager.shared.currentLanguage == .Arabic ? bookTitleAr    : bookTitleEn    }
    var chapterTitle: String { LocalizationManager.shared.currentLanguage == .Arabic ? chapterTitleAr : chapterTitleEn }

}

// MARK: - Chapter

struct HadithChapter: Identifiable, Hashable {
    let id: Int
    let bookId: Int
    let number: Int
    let titleAr: String
    let titleEn: String
    /// The part the chapter belongs to. The books nest their index two or three
    /// levels deep, so a chapter title alone — "باب الإيمان" — can read the
    /// same in two different parts of the book.
    var sectionTitleAr: String = ""
    var sectionTitleEn: String = ""
    /// How many hadith the chapter holds, shown next to its title.
    var hadithCount: Int = 0

    var title: String { LocalizationManager.shared.currentLanguage == .Arabic ? titleAr : titleEn }

    var sectionTitle: String {
        LocalizationManager.shared.currentLanguage == .Arabic ? sectionTitleAr : sectionTitleEn
    }

    var hasSection: Bool { !sectionTitle.isEmpty }
}

// MARK: - Entry

struct HadithEntry: Identifiable, Hashable {
    let id: Int
    let bookId: Int
    let chapterId: Int
    /// The first of `numbers`, kept as a scalar because jumping to a hadith and
    /// restoring a reading position both address a single number.
    let number: Int
    /// The body with every markup tag removed.
    let arabicText: String
    let translation: String
    /// The companion the report comes through.
    let narrator: String
    /// al-Albani's ruling, which the nine books carry inline in the body.
    let grade: String
    let gradeEn: String
    let isMarfu: Bool
    /// The chain of transmission, lifted out of the body.
    let narratorChain: String
    let takhrij: String
    let commentary: String
    let volume: Int
    let pageNo: Int
    /// Every number this report carries. A hadith repeated under several
    /// numbers is stored once and lists all of them.
    var numbers: [Int] = []
    /// مرفوع · موقوف · قدسي · أثر مقطوع. Strictly richer than `isMarfu`, which
    /// is kept only because older screens read it.
    var kind: String = ""
    /// A one-line summary of the report.
    var brief: String = ""
    /// The chapter path this hadith sits under, as the book's own index words it.
    var breadcrumb: String = ""
    /// The typed spans the parser lifted out of the body: the chain, the rare
    /// words, the Qur'an quotations and the inline numbers, each as a range
    /// over `arabicText`.
    var markup: HadithMarkup = .empty
    var hadethID: Int = 0

    var hasTranslation: Bool { !translation.isEmpty }
    var hasCommentary: Bool  { !commentary.isEmpty }
    var hasGrade: Bool       { !grade.isEmpty || !gradeEn.isEmpty }

    /// `"٣/١٢٤"`, or just the page when the book is a single volume.
    var referenceLabel: String {
        guard pageNo > 0 else { return "" }
        return volume > 0 ? "\(volume)/\(pageNo)" : "\(pageNo)"
    }

    /// Every number the report carries, for the header line.
    var numbersLabel: String {
        let all = numbers.isEmpty ? [number] : numbers
        return all.map(String.init).joined(separator: "، ")
    }
}

// MARK: - Search

struct HadithSearchResult: Identifiable {
    let id: Int
    let hadith: HadithEntry
    let book: HadithBook
}

// MARK: - Byte sizes

/// One place that turns a byte count into something a reader can judge.
///
/// The library mixes a 12 KiB collection with a 460 MiB one, so a fixed `MB`
/// formatter prints "0.0 MB" on one end and six digits on the other.
enum HadithByteSize {

    static func label(_ bytes: Int) -> String {
        guard bytes > 0 else { return "" }
        let kb = Double(bytes) / 1024
        if kb < 1000 { return String(format: "%.0f KB", kb.rounded()) }
        let mb = kb / 1024
        if mb < 1000 { return String(format: mb < 10 ? "%.1f MB" : "%.0f MB", mb) }
        return String(format: "%.2f GB", mb / 1024)
    }
}
