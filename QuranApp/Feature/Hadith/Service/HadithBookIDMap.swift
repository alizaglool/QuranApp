//
//  HadithBookIDMap.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import Foundation

// MARK: - Book id map

/// Translates the book ids the app shipped with into the ids the Nine Books
/// corpus uses.
///
/// The two numberings overlap — old 7 and new 7 are both valid ids for
/// different books — so nothing may be left half-translated.
enum HadithBookIDMap {

    /// Old id on the left, corpus id on the right.
    static let oldToNew: [Int: Int] = [
         1: 7,    // صحيح البخاري
         2: 5,    // صحيح مسلم
         3: 1,    // سنن النسائي
         4: 6,    // سنن أبي داود
         5: 4,    // سنن الترمذي
         6: 2,    // سنن ابن ماجه
         7: 9,    // موطأ مالك
         8: 11,   // مسند أحمد
         9: 8,    // سنن الدارمي
        10: 103,  // الأربعون النووية
        11: 104,  // الأربعون القدسية
        12: 105,  // أربعون شاه ولي الله الدهلوي
        13: 101,  // رياض الصالحين
        14: 106,  // مشكاة المصابيح
        15: 107,  // الأدب المفرد
        16: 108,  // الشمائل المحمدية
        17: 102   // بلوغ المرام
    ]

    /// Every id the old numbering used, which is also every database file the
    /// old build could have left behind.
    static let oldIDs: [Int] = Array(oldToNew.keys).sorted()

    static func newID(forOld oldID: Int) -> Int? { oldToNew[oldID] }
}

// MARK: - One-time migration

/// Moves a device off the old Hadith corpus and onto the new one, once.
///
/// There is no in-place upgrade available: the new databases carry a different
/// schema under ids that collide with the old ones, so an old `book_7.db` left
/// on disk would read as صحيح البخاري and fail every query against it. The
/// only safe move is to delete what the old build downloaded and keep the one
/// thing worth keeping — where the reader had got to.
enum HadithCorpusMigration {

    private static let marker = "hadith_corpus_migrated_to_nine_books"

    /// Runs the migration if it has not run on this device yet.
    ///
    /// Safe to call from anywhere and as often as the app likes: the marker is
    /// written whether or not there was anything to move.
    static func runIfNeeded(defaults: UserDefaults = .standard,
                            fileManager: FileManager = .default,
                            booksDirectory: URL) {
        guard !defaults.bool(forKey: marker) else { return }
        defaults.set(true, forKey: marker)

        removeOldDatabases(in: booksDirectory, fileManager: fileManager)
        migrateLastRead(defaults: defaults)
    }

    /// Forgets that the migration ran. Tests only.
    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: marker)
    }

    // MARK: Private

    /// Deletes every database the old numbering could have written.
    ///
    /// Only files named for an old id are touched, so a part-finished download
    /// or anything else in the directory is left where it is.
    private static func removeOldDatabases(in directory: URL, fileManager: FileManager) {
        for oldID in HadithBookIDMap.oldIDs {
            let url = directory.appendingPathComponent("hadith_book_\(oldID).db")
            guard fileManager.fileExists(atPath: url.path) else { continue }
            try? fileManager.removeItem(at: url)
        }
    }

    /// Carries the reading position over to the new book id.
    ///
    /// The chapter is dropped rather than translated. Old chapter ids came
    /// from a table the new corpus does not have, and a wrong chapter sends
    /// the reader to the wrong page; the hadith number survives, and the
    /// library resolves the chapter from it.
    private static func migrateLastRead(defaults: UserDefaults) {
        guard let data = defaults.data(forKey: HadithLastReadManager.storageKey),
              let position = try? JSONDecoder().decode(LastReadPosition.self, from: data) else { return }

        guard let newBookId = HadithBookIDMap.newID(forOld: position.bookId) else {
            // Already a corpus id, or an id from no numbering we know. Either
            // way, translating it again would be the thing that breaks it.
            return
        }

        let moved = LastReadPosition(
            bookId: newBookId,
            bookTitleEn: position.bookTitleEn,
            bookTitleAr: position.bookTitleAr,
            bookColorHex: position.bookColorHex,
            chapterId: 0,
            chapterTitleEn: "",
            chapterTitleAr: "",
            hadithIndex: position.hadithIndex,
            hadithNumber: position.hadithNumber,
            bookHadithCount: position.bookHadithCount,
            chapterHadithCount: position.chapterHadithCount
        )
        guard let encoded = try? JSONEncoder().encode(moved) else { return }
        defaults.set(encoded, forKey: HadithLastReadManager.storageKey)
    }
}
