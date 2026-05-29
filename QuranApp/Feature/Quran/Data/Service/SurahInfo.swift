//
//  SurahInfo.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-26.
//


import Foundation
import SQLite3

// MARK: - Data Models

struct SurahInfo: Identifiable {
    let id: Int
    let identifier: Int
    let arabicTitle: String
    let englishTitle: String
    let isMeccan: Bool
    let titleCodePoint: String
    let versesCount: Int
    let startPage: Int
    let endPage: Int
}

struct VersePosition {
    let verseID: Int
    let humanReadableID: String
    let number: Int
    let chapterNumber: Int
    let page1441: Int
    let markerLine: Int
    let markerCenterX: Float
    let markerCenterY: Float
    let numberCodePoint: String
}

struct VerseHighlightRect {
    let verseID: Int
    let line: Int
    let leftVal: Float
    let rightVal: Float
}

struct ChapterHeaderPosition {
    let chapterNumber: Int
    let pageNumber: Int
    let line: Int
    let centerX: Float
    let centerY: Float
}

struct PageVerse {
    let pageIdentifier: Int
    let verseID: Int
}

// MARK: - QuranDatabase

final class QuranDatabase {
    
    static let shared = QuranDatabase()
    
    private var db: OpaquePointer?
    
    private init() {
        openDatabase()
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
    
    private func openDatabase() {
        guard let dbPath = Bundle.main.path(forResource: "quran_positioning", ofType: "db") else {
            print("❌ quran_positioning.db not found in bundle")
            return
        }
        
        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            print("❌ Failed to open database")
            db = nil
        } else {
            print("✅ quran_positioning.db opened")
        }
    }
    
    // MARK: - All Surahs
    
    func getAllSurahs() -> [SurahInfo] {
        guard let db = db else { return [] }
        
        let query = """
            SELECT c.identifier, c.number, c.arabicTitle, c.englishTitle,
                   c.isMeccan, c.titleCodePoint,
                   COUNT(v.verseID) as verseCount,
                   MIN(v.page1441) as startPage,
                   MAX(v.page1441) as endPage
            FROM chapter c
            JOIN verse v ON v.chapterNumber = c.number
            GROUP BY c.number
            ORDER BY c.number
        """
        
        var stmt: OpaquePointer?
        var surahs: [SurahInfo] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                surahs.append(SurahInfo(
                    id: Int(sqlite3_column_int(stmt, 1)),
                    identifier: Int(sqlite3_column_int(stmt, 0)),
                    arabicTitle: String(cString: sqlite3_column_text(stmt, 2)),
                    englishTitle: String(cString: sqlite3_column_text(stmt, 3)),
                    isMeccan: sqlite3_column_int(stmt, 4) == 1,
                    titleCodePoint: String(cString: sqlite3_column_text(stmt, 5)),
                    versesCount: Int(sqlite3_column_int(stmt, 6)),
                    startPage: Int(sqlite3_column_int(stmt, 7)),
                    endPage: Int(sqlite3_column_int(stmt, 8))
                ))
            }
        }
        sqlite3_finalize(stmt)
        return surahs
    }
    
    // MARK: - Surah for Page
    
    func getSurahsForPage(_ pageNumber: Int) -> [SurahInfo] {
        guard let db = db else { return [] }
        
        let query = """
            SELECT DISTINCT c.identifier, c.number, c.arabicTitle, c.englishTitle,
                   c.isMeccan, c.titleCodePoint
            FROM chapter c
            JOIN verse v ON v.chapterNumber = c.number
            JOIN page_verse pv ON pv.verseID = v.verseID
            WHERE pv.pageIdentifier = ? AND pv.edition = '1441'
            ORDER BY c.number
        """
        
        var stmt: OpaquePointer?
        var surahs: [SurahInfo] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(pageNumber - 1))
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                surahs.append(SurahInfo(
                    id: Int(sqlite3_column_int(stmt, 1)),
                    identifier: Int(sqlite3_column_int(stmt, 0)),
                    arabicTitle: String(cString: sqlite3_column_text(stmt, 2)),
                    englishTitle: String(cString: sqlite3_column_text(stmt, 3)),
                    isMeccan: sqlite3_column_int(stmt, 4) == 1,
                    titleCodePoint: String(cString: sqlite3_column_text(stmt, 5)),
                    versesCount: 0,
                    startPage: 0,
                    endPage: 0
                ))
            }
        }
        sqlite3_finalize(stmt)
        return surahs
    }
    
    // MARK: - Verses on a Page
    
    func getVersesForPage(_ pageNumber: Int) -> [VersePosition] {
        guard let db = db else { return [] }
        
        let query = """
            SELECT v.verseID, v.humanReadableID, v.number, v.chapterNumber,
                   v.page1441, v.marker1441_line, v.marker1441_centerX,
                   v.marker1441_centerY, v.marker1441_numberCodePoint
            FROM verse v
            JOIN page_verse pv ON pv.verseID = v.verseID
            WHERE pv.pageIdentifier = ? AND pv.edition = '1441'
            ORDER BY v.verseID
        """
        
        var stmt: OpaquePointer?
        var verses: [VersePosition] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(pageNumber - 1))
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                // Read the codepoint as raw bytes
                var codePointStr = ""
                if let textPtr = sqlite3_column_text(stmt, 8) {
                    let rawString = String(cString: textPtr)
                    // The db stores actual unicode chars, read them directly
                    codePointStr = rawString
                }
                
                verses.append(VersePosition(
                    verseID: Int(sqlite3_column_int(stmt, 0)),
                    humanReadableID: String(cString: sqlite3_column_text(stmt, 1)),
                    number: Int(sqlite3_column_int(stmt, 2)),
                    chapterNumber: Int(sqlite3_column_int(stmt, 3)),
                    page1441: Int(sqlite3_column_int(stmt, 4)),
                    markerLine: Int(sqlite3_column_int(stmt, 5)),
                    markerCenterX: Float(sqlite3_column_double(stmt, 6)),
                    markerCenterY: Float(sqlite3_column_double(stmt, 7)),
                    numberCodePoint: codePointStr
                ))
            }
        }
        sqlite3_finalize(stmt)
        
        // Debug first verse
        if let first = verses.first {
            let scalars = first.numberCodePoint.unicodeScalars.map { String(format: "U+%04X", $0.value) }
        }
        
        return verses
    }
    
    // MARK: - Verse Highlights
    
    func getHighlights(forVerse verseID: Int) -> [VerseHighlightRect] {
        guard let db = db else { return [] }
        
        let query = "SELECT verseID, line, leftVal, rightVal FROM verse_highlight WHERE verseID = ? AND edition = '1441'"
        
        var stmt: OpaquePointer?
        var rects: [VerseHighlightRect] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(verseID))
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                rects.append(VerseHighlightRect(
                    verseID: Int(sqlite3_column_int(stmt, 0)),
                    line: Int(sqlite3_column_int(stmt, 1)),
                    leftVal: Float(sqlite3_column_double(stmt, 2)),
                    rightVal: Float(sqlite3_column_double(stmt, 3))
                ))
            }
        }
        sqlite3_finalize(stmt)
        return rects
    }
    
    // MARK: - Chapter Headers on Page
    
    func getChapterHeaders(forPage pageNumber: Int) -> [ChapterHeaderPosition] {
        guard let db = db else { return [] }
        
        let query = "SELECT chapterNumber, pageNumber, line, centerX, centerY FROM chapter_header WHERE pageNumber = ? AND edition = '1441'"
        
        var stmt: OpaquePointer?
        var headers: [ChapterHeaderPosition] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(pageNumber))
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                headers.append(ChapterHeaderPosition(
                    chapterNumber: Int(sqlite3_column_int(stmt, 0)),
                    pageNumber: Int(sqlite3_column_int(stmt, 1)),
                    line: Int(sqlite3_column_int(stmt, 2)),
                    centerX: Float(sqlite3_column_double(stmt, 3)),
                    centerY: Float(sqlite3_column_double(stmt, 4))
                ))
            }
        }
        sqlite3_finalize(stmt)
        return headers
    }
    
    // MARK: - Juz Number
    
    func getJuz(forPage page: Int) -> Int {
        let juzPages = [1,22,42,62,82,102,121,142,162,182,
                        201,222,242,262,282,302,322,342,362,382,
                        402,422,442,462,482,502,522,542,562,582]
        for (index, startPage) in juzPages.enumerated().reversed() {
            if page >= startPage { return index + 1 }
        }
        return 1
    }
    
    // MARK: - Page for Surah / Verse

    func getPage(forSurah surahNumber: Int, verse: Int) -> Int {
        guard let db = db else { return 1 }
        let query = "SELECT page1441 FROM verse WHERE chapterNumber = ? AND number = ? LIMIT 1"
        var stmt: OpaquePointer?
        var page = getStartPage(forSurah: surahNumber)
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(surahNumber))
            sqlite3_bind_int(stmt, 2, Int32(verse))
            if sqlite3_step(stmt) == SQLITE_ROW {
                page = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return page
    }

    func getStartPage(forSurah surahNumber: Int) -> Int {
        guard let db = db else { return 1 }
        
        let query = "SELECT MIN(page1441) FROM verse WHERE chapterNumber = ?"
        var stmt: OpaquePointer?
        var page = 1
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(surahNumber))
            if sqlite3_step(stmt) == SQLITE_ROW {
                page = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return page
    }
    
    func getAllHighlightsForPage(_ pageNumber: Int) -> [VerseHighlightRect] {
        guard let db = db else { return [] }
        
        let query = """
            SELECT vh.verseID, vh.line, vh.leftVal, vh.rightVal
            FROM verse_highlight vh
            JOIN verse v ON v.verseID = vh.verseID
            JOIN page_verse pv ON pv.verseID = v.verseID
            WHERE pv.pageIdentifier = ? AND pv.edition = '1441' AND vh.edition = '1441'
            ORDER BY vh.verseID, vh.line
        """
        
        var stmt: OpaquePointer?
        var rects: [VerseHighlightRect] = []
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(pageNumber - 1))
            
            while sqlite3_step(stmt) == SQLITE_ROW {
                rects.append(VerseHighlightRect(
                    verseID: Int(sqlite3_column_int(stmt, 0)),
                    line: Int(sqlite3_column_int(stmt, 1)),
                    leftVal: Float(sqlite3_column_double(stmt, 2)),
                    rightVal: Float(sqlite3_column_double(stmt, 3))
                ))
            }
        }
        sqlite3_finalize(stmt)
        return rects
    }
    
    // MARK: - Verse Number

    func getVerseNumber(forVerseID verseID: Int) -> Int {
        guard let db = db else { return 0 }
        
        let query = "SELECT number FROM verse WHERE verseID = ?"
        var stmt: OpaquePointer?
        var number = 0
        
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(verseID))
            if sqlite3_step(stmt) == SQLITE_ROW {
                number = Int(sqlite3_column_int(stmt, 0))
            }
        }
        sqlite3_finalize(stmt)
        return number
    }
    
    // MARK: - Verse Info (by surah + verse number)

    func getVerseInfo(surahNumber: Int, verseNumber: Int) -> (verseID: Int, page: Int)? {
        guard let db = db else { return nil }
        let query = "SELECT verseID, page1441 FROM verse WHERE chapterNumber = ? AND number = ? LIMIT 1"
        var stmt: OpaquePointer?
        var result: (verseID: Int, page: Int)? = nil
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(surahNumber))
            sqlite3_bind_int(stmt, 2, Int32(verseNumber))
            if sqlite3_step(stmt) == SQLITE_ROW {
                result = (Int(sqlite3_column_int(stmt, 0)), Int(sqlite3_column_int(stmt, 1)))
            }
        }
        sqlite3_finalize(stmt)
        return result
    }

    // MARK: - Total Pages

    var totalPages: Int { 604 }
}
