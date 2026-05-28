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

    private var dbs: [Int: OpaquePointer] = [:]
    private let lock = NSLock()
    private var cachedManifest: [HadithBook]?

    private init() {}

    // MARK: - Manifest

    func loadManifest() -> [HadithBook] {
        if let cached = cachedManifest { return cached }
        guard let url  = Bundle.main.url(forResource: "books_manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        struct Wrapper: Codable { let books: [HadithBook] }
        let books = (try? JSONDecoder().decode(Wrapper.self, from: data))?.books ?? []
        cachedManifest = books
        return books
    }

    // MARK: - Per-book DB access

    func openDB(for bookId: Int) -> OpaquePointer? {
        lock.lock(); defer { lock.unlock() }
        if let existing = dbs[bookId] { return existing }
        let url = HadithDownloadManager.shared.dbURL(for: bookId)
        var db: OpaquePointer?
        sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil)
        dbs[bookId] = db
        return db
    }

    func closeDB(for bookId: Int) {
        lock.lock(); defer { lock.unlock() }
        if let db = dbs[bookId] { sqlite3_close(db) }
        dbs[bookId] = nil
    }

    // MARK: - Chapters

    func fetchChapters(bookId: Int) -> [HadithChapter] {
        let sql = "SELECT id, book_id, number, title_ar, title_en FROM chapters WHERE book_id = ? ORDER BY number"
        return query(db: openDB(for: bookId), sql, bind: { sqlite3_bind_int($0, 1, Int32(bookId)) }) { stmt in
            HadithChapter(
                id:      Int(sqlite3_column_int(stmt, 0)),
                bookId:  Int(sqlite3_column_int(stmt, 1)),
                number:  Int(sqlite3_column_int(stmt, 2)),
                titleAr: col(stmt, 3),
                titleEn: col(stmt, 4)
            )
        }
    }

    // MARK: - Hadiths

    func fetchHadiths(bookId: Int, chapterId: Int) -> [HadithEntry] {
        let sql = """
            SELECT id, book_id, chapter_id, number, arabic_text, translation,
                   narrator, grade, grade_en, is_marfu, narrator_chain, takhrij,
                   commentary, volume, page_no
            FROM hadiths WHERE chapter_id = ? ORDER BY number
            """
        return query(db: openDB(for: bookId), sql, bind: { sqlite3_bind_int($0, 1, Int32(chapterId)) }) { stmt in
            hadithEntry(from: stmt)
        }
    }

    func fetchHadith(bookId: Int, number: Int) -> HadithEntry? {
        let sql = """
            SELECT id, book_id, chapter_id, number, arabic_text, translation,
                   narrator, grade, grade_en, is_marfu, narrator_chain, takhrij,
                   commentary, volume, page_no
            FROM hadiths WHERE number = ? LIMIT 1
            """
        return query(db: openDB(for: bookId), sql, bind: { sqlite3_bind_int($0, 1, Int32(number)) }) { stmt in
            hadithEntry(from: stmt)
        }.first
    }

    // MARK: - Search (across all downloaded books)

    func search(query queryText: String, limit: Int = 50) -> [HadithSearchResult] {
        let trimmed = queryText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        let escaped = trimmed.replacingOccurrences(of: "\"", with: "\"\"")
        let pattern = "\"\(escaped)\""

        let bookIds  = HadithDownloadManager.shared.downloadedBookIds
        let manifest = loadManifest()
        var results: [HadithSearchResult] = []

        let sql = """
            SELECT h.id, h.book_id, h.chapter_id, h.number,
                   h.arabic_text, h.translation, h.narrator, h.grade,
                   h.grade_en, h.is_marfu, h.narrator_chain, h.takhrij,
                   h.commentary, h.volume, h.page_no
            FROM hadiths_fts f
            JOIN hadiths h ON h.id = f.rowid
            WHERE hadiths_fts MATCH ?
            ORDER BY rank
            LIMIT ?
            """

        for bookId in bookIds {
            guard results.count < limit,
                  let db   = openDB(for: bookId),
                  let book = manifest.first(where: { $0.id == bookId }) else { continue }

            let remaining = limit - results.count
            let bookResults = query(db: db, sql, bind: { stmt in
                sqlite3_bind_text(stmt, 1, pattern, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(stmt, 2, Int32(remaining))
            }) { stmt in
                HadithSearchResult(id: Int(sqlite3_column_int(stmt, 0)),
                                   hadith: hadithEntry(from: stmt),
                                   book: book)
            }
            results.append(contentsOf: bookResults)
        }
        return results
    }

    // MARK: - Private helpers

    private func query<T>(db: OpaquePointer?,
                          _ sql: String,
                          bind: ((OpaquePointer) -> Void)? = nil,
                          map: (OpaquePointer) -> T) -> [T] {
        guard let db else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        bind?(stmt)
        var results: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW { results.append(map(stmt)) }
        sqlite3_finalize(stmt)
        return results
    }

    private func hadithEntry(from stmt: OpaquePointer) -> HadithEntry {
        HadithEntry(
            id:            Int(sqlite3_column_int(stmt, 0)),
            bookId:        Int(sqlite3_column_int(stmt, 1)),
            chapterId:     Int(sqlite3_column_int(stmt, 2)),
            number:        Int(sqlite3_column_int(stmt, 3)),
            arabicText:    col(stmt, 4),
            translation:   col(stmt, 5),
            narrator:      col(stmt, 6),
            grade:         col(stmt, 7),
            gradeEn:       col(stmt, 8),
            isMarfu:       sqlite3_column_int(stmt, 9) != 0,
            narratorChain: col(stmt, 10),
            takhrij:       col(stmt, 11),
            commentary:    col(stmt, 12),
            volume:        Int(sqlite3_column_int(stmt, 13)),
            pageNo:        Int(sqlite3_column_int(stmt, 14))
        )
    }
}

private func col(_ stmt: OpaquePointer, _ index: Int32) -> String {
    guard let cStr = sqlite3_column_text(stmt, index) else { return "" }
    return String(cString: cStr)
}

// MARK: - Last Read Manager

final class HadithLastReadManager {

    static let shared = HadithLastReadManager()
    private let key = "hadith_last_read_position"
    private init() {}

    func save(_ position: LastReadPosition) {
        guard let data = try? JSONEncoder().encode(position) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    func load() -> LastReadPosition? {
        guard let data     = UserDefaults.standard.data(forKey: key),
              let position = try? JSONDecoder().decode(LastReadPosition.self, from: data) else { return nil }
        return position
    }
}
