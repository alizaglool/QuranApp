//
//  HadithDatabaseService.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class HadithDatabaseService {

    static let shared = HadithDatabaseService()
    private var db: OpaquePointer?

    private init() {
        guard let path = Bundle.main.path(forResource: "hadith", ofType: "db") else { return }
        sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil)
    }

    // MARK: - Books

    func fetchBooks() -> [HadithBook] {
        let sql = "SELECT id, title_ar, title_en, author_ar, author_en, hadith_count, color_hex FROM books ORDER BY id"
        return query(sql) { stmt in
            HadithBook(
                id: Int(sqlite3_column_int(stmt, 0)),
                titleAr: col(stmt, 1),
                titleEn: col(stmt, 2),
                authorAr: col(stmt, 3),
                authorEn: col(stmt, 4),
                hadithCount: Int(sqlite3_column_int(stmt, 5)),
                colorHex: col(stmt, 6)
            )
        }
    }

    // MARK: - Chapters

    func fetchChapters(bookId: Int) -> [HadithChapter] {
        let sql = "SELECT id, book_id, number, title_ar, title_en FROM chapters WHERE book_id = ? ORDER BY number"
        return query(sql, bind: { sqlite3_bind_int($0, 1, Int32(bookId)) }) { stmt in
            HadithChapter(
                id: Int(sqlite3_column_int(stmt, 0)),
                bookId: Int(sqlite3_column_int(stmt, 1)),
                number: Int(sqlite3_column_int(stmt, 2)),
                titleAr: col(stmt, 3),
                titleEn: col(stmt, 4)
            )
        }
    }

    // MARK: - Hadiths

    func fetchHadiths(chapterId: Int) -> [HadithEntry] {
        let sql = "SELECT id, book_id, chapter_id, number, arabic_text, translation, narrator, grade FROM hadiths WHERE chapter_id = ? ORDER BY number"
        return query(sql, bind: { sqlite3_bind_int($0, 1, Int32(chapterId)) }) { stmt in
            hadithEntry(from: stmt)
        }
    }

    // MARK: - Search

    func search(query queryText: String, limit: Int = 50) -> [HadithSearchResult] {
        let trimmed = queryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let escaped = trimmed.replacingOccurrences(of: "\"", with: "\"\"")
        let pattern = "\"\(escaped)\""
        let sql = """
            SELECT h.id, h.book_id, h.chapter_id, h.number,
                   h.arabic_text, h.translation, h.narrator, h.grade,
                   b.title_ar, b.title_en, b.author_ar, b.author_en,
                   b.hadith_count, b.color_hex
            FROM hadiths_fts f
            JOIN hadiths h ON h.id = f.rowid
            JOIN books b ON b.id = h.book_id
            WHERE hadiths_fts MATCH ?
            ORDER BY rank
            LIMIT ?
            """
        return query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, pattern, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 2, Int32(limit))
        }) { stmt in
            let entry = hadithEntry(from: stmt)
            let book = HadithBook(
                id: entry.bookId,
                titleAr: col(stmt, 8),
                titleEn: col(stmt, 9),
                authorAr: col(stmt, 10),
                authorEn: col(stmt, 11),
                hadithCount: Int(sqlite3_column_int(stmt, 12)),
                colorHex: col(stmt, 13)
            )
            return HadithSearchResult(id: entry.id, hadith: entry, book: book)
        }
    }

    // MARK: - Private helpers

    private func query<T>(_ sql: String,
                          bind: ((OpaquePointer) -> Void)? = nil,
                          map: (OpaquePointer) -> T) -> [T] {
        var stmt: OpaquePointer?
        var results: [T] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        bind?(stmt)
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(map(stmt))
        }
        sqlite3_finalize(stmt)
        return results
    }

    private func hadithEntry(from stmt: OpaquePointer) -> HadithEntry {
        HadithEntry(
            id: Int(sqlite3_column_int(stmt, 0)),
            bookId: Int(sqlite3_column_int(stmt, 1)),
            chapterId: Int(sqlite3_column_int(stmt, 2)),
            number: Int(sqlite3_column_int(stmt, 3)),
            arabicText: col(stmt, 4),
            translation: col(stmt, 5),
            narrator: col(stmt, 6),
            grade: col(stmt, 7)
        )
    }
}

private func col(_ stmt: OpaquePointer, _ index: Int32) -> String {
    guard let cStr = sqlite3_column_text(stmt, index) else { return "" }
    return String(cString: cStr)
}
