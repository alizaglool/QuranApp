//
//  TafsirDatabase.swift
//  QuranApp
//

import Foundation
import SQLite3

// Expected bundle file: tafsir_mukhtasar.db
// Schema:
//   CREATE TABLE mukhtasar (
//       id            INTEGER PRIMARY KEY,
//       surah_number  INTEGER NOT NULL,
//       verse_number  INTEGER NOT NULL,
//       text          TEXT    NOT NULL
//   );

final class TafsirDatabase {

    static let shared = TafsirDatabase()

    private var db: OpaquePointer?

    private init() { openDatabase() }

    deinit {
        if let db { sqlite3_close(db) }
    }

    private func openDatabase() {
        guard let path = Bundle.main.path(forResource: "tafsir_mukhtasar", ofType: "db") else {
            print("⚠️ tafsir_mukhtasar.db not found in bundle — add it to Resources to enable tafsir")
            return
        }
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            print("❌ Failed to open tafsir_mukhtasar.db")
            db = nil
        } else {
            print("✅ tafsir_mukhtasar.db opened")
        }
    }

    // MARK: - Public API

    func getTafsir(surahNumber: Int, verseNumber: Int) -> String? {
        guard let db else { return nil }
        let query = "SELECT text FROM mukhtasar WHERE surah_number = ? AND verse_number = ? LIMIT 1"
        var stmt: OpaquePointer?
        var result: String?
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(surahNumber))
            sqlite3_bind_int(stmt, 2, Int32(verseNumber))
            if sqlite3_step(stmt) == SQLITE_ROW, let ptr = sqlite3_column_text(stmt, 0) {
                result = String(cString: ptr)
            }
        }
        sqlite3_finalize(stmt)
        return result
    }

    var isAvailable: Bool { db != nil }
}
