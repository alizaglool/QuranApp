//
//  StorageUsage.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation

enum StorageCategory: String, CaseIterable, Identifiable, Sendable {
    case quranPages
    case recitations
    case hadith
    case athkar
    case tafsir

    var id: String { rawValue }
}

enum StorageDeleteTarget: Hashable, Sendable {
    case reciterSurah(slug: String, surahNumber: Int)
    case reciter(slug: String)
    case hadithBook(identifier: Int)
    case athkarPack(key: String)
    case tafsirBook(identifier: String)
    case quranPack(key: String)
}

struct SurahUsage: Hashable, Sendable {
    let number: Int
    let bytes: Int64
}

struct ReciterUsage: Hashable, Sendable {
    let slug: String
    let bytes: Int64
    let surahs: [SurahUsage]
}

struct StorageItemUsage: Hashable, Sendable {
    let identifier: String
    let bytes: Int64
}

struct StorageScan: Sendable {
    let reciters: [ReciterUsage]
    let hadithBooks: [StorageItemUsage]
    let athkarPacks: [StorageItemUsage]
    let tafsirBooks: [StorageItemUsage]
    let quranPacks: [StorageItemUsage]

    static let empty = StorageScan(reciters: [],
                                   hadithBooks: [],
                                   athkarPacks: [],
                                   tafsirBooks: [],
                                   quranPacks: [])
}

// MARK: - Totals

extension StorageScan {

    var totalBytes: Int64 {
        StorageCategory.allCases.reduce(Int64(0)) { $0 + bytes(for: $1) }
    }

    var isEmpty: Bool { totalBytes == 0 }

    func bytes(for category: StorageCategory) -> Int64 {
        switch category {
        case .recitations: return reciters.reduce(Int64(0)) { $0 + $1.bytes }
        case .hadith: return hadithBooks.reduce(Int64(0)) { $0 + $1.bytes }
        case .athkar: return athkarPacks.reduce(Int64(0)) { $0 + $1.bytes }
        case .tafsir: return tafsirBooks.reduce(Int64(0)) { $0 + $1.bytes }
        case .quranPages: return quranPacks.reduce(Int64(0)) { $0 + $1.bytes }
        }
    }
}
