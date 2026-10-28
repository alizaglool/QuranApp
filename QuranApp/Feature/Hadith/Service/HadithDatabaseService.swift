//
//  HadithDatabaseService.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Service

/// Reads the downloaded book databases.
///
/// Each book is one SQLite file holding the same tables: `Hadeths` as a tree,
/// plus the scholarly apparatus — `Ahkam`, `Takhrig`, `Rwah`, `ghareeb_words`.
/// Handles stay open for as long as the book is installed, because opening a
/// four-hundred-megabyte file on every page turn is not free.
final class HadithDatabaseService {

    static let shared = HadithDatabaseService()

    /// The id given to the single chapter invented for a book with no index.
    /// Real chapters are keyed by `Hadeths.HadethID`, which starts at 1 in
    /// every shipped book, so zero cannot collide with one.
    static let flatChapterID = 0

    /// Rows that are hadiths. Everything else in `Hadeths` is an index node.
    private static let hadithType = 2

    private var dbs: [Int: OpaquePointer] = [:]
    private var capabilities: [Int: BookCapabilities] = [:]
    private let lock = NSLock()
    private let manifestService: HadithManifestService
    private let metaService = HadithMetaService.shared

    init(manifestService: HadithManifestService = .shared) {
        self.manifestService = manifestService
    }

    /// What a particular book's file actually contains.
    ///
    /// The nine core books are Arabic only; the later collections add an
    /// English `Translation` and a ready-made `TakhrijText`. Asking the file
    /// once beats hard-coding a list of book ids that would drift.
    private struct BookCapabilities {
        let hasTranslation: Bool

        /// The hadith column list, padded so the column indices never move.
        var hadithColumns: String {
            let tail = hasTranslation ? "Translation, TakhrijText" : "'' , ''"
            return """
                AutoID, BookID, ParentID, Text, HadethNumbers, SharhText,
                FolderNum, PageNum, HadethType, BriefText, TabweebPath, RawyAlaa,
                \(tail), HadethID
                """
        }
    }

    // MARK: - Manifest

    func loadManifest() -> [HadithBook] {
        manifestService.load().books
    }

    // MARK: - Per-book DB access

    func openDB(for bookId: Int) -> OpaquePointer? {
        lock.lock(); defer { lock.unlock() }
        if let existing = dbs[bookId] { return existing }

        let url = HadithDownloadManager.shared.dbURL(for: bookId)
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK, let db else {
            // Deliberately not cached: a book being downloaded right now will
            // fail to open and must be retried once it lands, not remembered
            // as broken for the rest of the launch.
            if let db { sqlite3_close(db) }
            return nil
        }
        dbs[bookId] = db
        return db
    }

    func closeDB(for bookId: Int) {
        lock.lock(); defer { lock.unlock() }
        if let db = dbs[bookId] { sqlite3_close(db) }
        dbs[bookId] = nil
        capabilities[bookId] = nil
    }

    private func bookCapabilities(for bookId: Int) -> BookCapabilities {
        lock.lock()
        if let known = capabilities[bookId] {
            lock.unlock()
            return known
        }
        lock.unlock()

        let columns = rows(db: openDB(for: bookId),
                            "SELECT name FROM pragma_table_info('Hadeths')") { col($0, 0) }
        let found = BookCapabilities(hasTranslation: columns.contains("Translation"))

        lock.lock()
        capabilities[bookId] = found
        lock.unlock()
        return found
    }

    // MARK: - Chapters

    /// The book's index, flattened to the one level that holds hadiths.
    ///
    /// `Hadeths` is a tree of varying depth and only some of its nodes are
    /// chapters: a chapter is any index node with hadiths hanging directly off
    /// it. The level above it, where there is one, becomes the section title,
    /// because a bare `باب الإيمان` reads the same in three different books.
    func fetchChapters(bookId: Int) -> [HadithChapter] {
        let sql = """
            SELECT p.HadethID,
                   COALESCE(NULLIF(p.BriefText, ''), p.Text) AS title,
                   COALESCE(g.BriefText, '') AS section,
                   COUNT(c.AutoID) AS total
            FROM Hadeths p
            JOIN Hadeths c ON c.ParentID = p.HadethID AND c.Type = \(Self.hadithType)
            LEFT JOIN Hadeths g ON g.HadethID = p.ParentID AND g.Type <> \(Self.hadithType)
            WHERE p.Type <> \(Self.hadithType)
            GROUP BY p.HadethID
            ORDER BY p.AutoID
            """
        let rows = rows(db: openDB(for: bookId), sql) { stmt in
            (id: Int(sqlite3_column_int(stmt, 0)),
             title: col(stmt, 1),
             section: col(stmt, 2),
             total: Int(sqlite3_column_int(stmt, 3)))
        }

        guard !rows.isEmpty else { return [flatChapter(bookId: bookId)].compactMap { $0 } }

        return rows.enumerated().map { index, row in
            HadithChapter(id: row.id,
                          bookId: bookId,
                          number: index + 1,
                          titleAr: row.title,
                          titleEn: "",
                          sectionTitleAr: row.section,
                          sectionTitleEn: "",
                          hadithCount: row.total)
        }
    }

    /// The stand-in chapter for the short collections, which are a flat list
    /// of forty-odd hadiths with no index at all. Without it those books would
    /// open on an empty table of contents.
    private func flatChapter(bookId: Int) -> HadithChapter? {
        let total = rows(db: openDB(for: bookId),
                          "SELECT COUNT(*) FROM Hadeths WHERE Type = \(Self.hadithType)") {
            Int(sqlite3_column_int($0, 0))
        }.first ?? 0
        guard total > 0 else { return nil }

        let name = rows(db: openDB(for: bookId),
                         "SELECT BookName FROM Books WHERE BookID = ? LIMIT 1",
                         bind: { sqlite3_bind_int($0, 1, Int32(bookId)) }) { col($0, 0) }.first ?? ""

        return HadithChapter(id: Self.flatChapterID,
                             bookId: bookId,
                             number: 1,
                             titleAr: name,
                             titleEn: "",
                             hadithCount: total)
    }

    // MARK: - Hadiths

    func fetchHadiths(bookId: Int, chapterId: Int) -> [HadithEntry] {
        let capability = bookCapabilities(for: bookId)
        // The invented chapter stands for the whole book, so it has no parent
        // to filter on.
        let filter = chapterId == Self.flatChapterID ? "" : "AND ParentID = ?"
        let sql = """
            SELECT \(capability.hadithColumns)
            FROM Hadeths
            WHERE Type = \(Self.hadithType) \(filter)
            ORDER BY AutoID
            """
        return rows(db: openDB(for: bookId), sql, bind: { stmt in
            if chapterId != Self.flatChapterID { _ = sqlite3_bind_int(stmt, 1, Int32(chapterId)) }
        }) { hadithEntry(from: $0) }
    }

    /// Looks a hadith up by its printed number.
    ///
    /// `HadethNumbers` holds a set — `@1@2@` — because one entry can cover
    /// several numbered reports, so this matches a member of the set rather
    /// than the whole column.
    func fetchHadith(bookId: Int, number: Int) -> HadithEntry? {
        let capability = bookCapabilities(for: bookId)
        let sql = """
            SELECT \(capability.hadithColumns)
            FROM Hadeths
            WHERE Type = \(Self.hadithType) AND HadethNumbers LIKE ?
            ORDER BY AutoID
            LIMIT 1
            """
        return rows(db: openDB(for: bookId), sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, "%@\(number)@%", -1, SQLITE_TRANSIENT)
        }) { hadithEntry(from: $0) }.first
    }

    /// Looks a hadith up by its row id, which is what a cross-reference from
    /// another table carries.
    func fetchHadith(bookId: Int, autoId: Int) -> HadithEntry? {
        let capability = bookCapabilities(for: bookId)
        let sql = """
            SELECT \(capability.hadithColumns)
            FROM Hadeths
            WHERE AutoID = ?
            LIMIT 1
            """
        return rows(db: openDB(for: bookId), sql, bind: { stmt in
            sqlite3_bind_int(stmt, 1, Int32(autoId))
        }) { hadithEntry(from: $0) }.first
    }

    // MARK: - Scholarly apparatus

    /// Everything hanging off one hadith: the rulings other scholars gave it,
    /// where else it is reported, and what its rare words mean.
    ///
    /// Read separately from the hadith itself because a reader turning pages
    /// never needs it, and three extra joins per page turn would be paid by
    /// everyone to serve the few who open the detail sheet.
    func fetchDetail(for entry: HadithEntry) -> HadithDetail {
        let nodeIDs = fetchSubjectNodeIDs(bookId: entry.bookId, hadethID: entry.hadethID)

        return HadithDetail(
            entry: entry,
            rulings: fetchRulings(bookId: entry.bookId, autoId: entry.id),
            takhrij: fetchTakhrij(bookId: entry.bookId, autoId: entry.id),
            ghareeb: fetchGhareeb(bookId: entry.bookId, references: entry.markup.ghareebWords),
            notes: metaService.notes(for: entry.markup.notes),
            subjects: metaService.subjectPaths(nodeIDs: nodeIDs)
        )
    }

    func fetchSubjectNodeIDs(bookId: Int, hadethID: Int) -> [Int] {
        guard hadethID > 0 else { return [] }

        let sql = """
            SELECT NodeID
            FROM HadethsSubjects
            WHERE HadethID = ? AND BookID = ?
            ORDER BY AutoID
            """
        return rows(db: openDB(for: bookId), sql, bind: { stmt in
            sqlite3_bind_int(stmt, 1, Int32(hadethID))
            sqlite3_bind_int(stmt, 2, Int32(bookId))
        }) { stmt in
            Int(sqlite3_column_int(stmt, 0))
        }
    }

    func fetchRulings(bookId: Int, autoId: Int) -> [HadithRuling] {
        let sql = """
            SELECT HokomId, Hokom, Scientist, Source
            FROM Ahkam
            WHERE HadethAutoId = ?
            ORDER BY HokomId
            """
        return rows(db: openDB(for: bookId), sql, bind: { sqlite3_bind_int($0, 1, Int32(autoId)) }) { stmt in
            HadithRuling(id: Int(sqlite3_column_int(stmt, 0)),
                         text: col(stmt, 1),
                         scholar: col(stmt, 2),
                         source: col(stmt, 3))
        }.filter { !$0.text.isEmpty }
    }

    /// Where else this hadith is reported, gathered one group per book.
    ///
    /// A single hadith can be cited forty times in one collection, so the flat
    /// rows are collapsed into "صحيح البخاري · ٥٢١، ٥٤١، ٥٤٤" rather than
    /// forty near-identical lines.
    func fetchTakhrij(bookId: Int, autoId: Int) -> [HadithTakhrijSection] {
        let sql = """
            SELECT TakhrigAutoID, TakhregBookID, TakhregBookName,
                   TakhregHadethNumber, TakhregType
            FROM Takhrig
            WHERE HadethAutoId = ?
            ORDER BY TakhregBookID, TakhregHadethNumber
            """
        let entries = rows(db: openDB(for: bookId), sql, bind: { sqlite3_bind_int($0, 1, Int32(autoId)) }) { stmt in
            HadithTakhrijEntry(id: Int(sqlite3_column_int(stmt, 0)),
                               bookId: Int(sqlite3_column_int(stmt, 1)),
                               bookName: col(stmt, 2),
                               hadithNumber: col(stmt, 3),
                               relation: .make(Int(sqlite3_column_int(stmt, 4))))
        }

        var order: [HadithTakhrijRelation] = []
        var sections: [HadithTakhrijRelation: [HadithTakhrijGroup]] = [:]

        for relation in entries.map(\.relation) where sections[relation] == nil {
            order.append(relation)
            sections[relation] = groups(in: entries, relation: relation, bookId: bookId)
        }

        return order
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { relation in
                guard let groups = sections[relation], !groups.isEmpty else { return nil }
                return HadithTakhrijSection(relation: relation, groups: groups)
            }
    }

    private func groups(in entries: [HadithTakhrijEntry],
                        relation: HadithTakhrijRelation,
                        bookId: Int) -> [HadithTakhrijGroup] {
        var order: [Int] = []
        var grouped: [Int: (name: String, numbers: [String])] = [:]

        for entry in entries where entry.relation == relation && !entry.hadithNumber.isEmpty {
            if grouped[entry.bookId] == nil {
                order.append(entry.bookId)
                grouped[entry.bookId] = (entry.bookName, [])
            }
            // The same number can be listed twice under one type, and the
            // reader has no use for seeing it twice.
            if grouped[entry.bookId]?.numbers.contains(entry.hadithNumber) == false {
                grouped[entry.bookId]?.numbers.append(entry.hadithNumber)
            }
        }

        return order.compactMap { id in
            guard let group = grouped[id] else { return nil }
            return HadithTakhrijGroup(bookId: id,
                                      bookName: group.name,
                                      numbers: group.numbers,
                                      isSameBook: id == bookId)
        }
    }

    /// The meanings of the rare words the parser found in this body.
    ///
    /// `ghareeb_words` stores only the meaning — the word itself is the text
    /// the tag wrapped — so the two halves are put back together here.
    func fetchGhareeb(bookId: Int, references: [HadithGhareebRef]) -> [HadithGhareebMeaning] {
        guard !references.isEmpty else { return [] }

        let ids = references.map { $0.wordID }
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = "SELECT ID, Mean FROM ghareeb_words WHERE ID IN (\(placeholders))"
        let rows = rows(db: openDB(for: bookId), sql, bind: { stmt in
            for (offset, id) in ids.enumerated() {
                _ = sqlite3_bind_int(stmt, Int32(offset + 1), Int32(id))
            }
        }) { stmt in
            (id: Int(sqlite3_column_int(stmt, 0)), meaning: col(stmt, 1))
        }

        let meanings = Dictionary(rows.map { ($0.id, $0.meaning) }, uniquingKeysWith: { first, _ in first })
        // Kept in the order the words appear in the body, so the glossary
        // reads alongside the hadith rather than against it.
        return references.compactMap { reference in
            guard let meaning = meanings[reference.wordID], !meaning.isEmpty else { return nil }
            return HadithGhareebMeaning(id: reference.wordID, word: reference.word, meaning: meaning)
        }
    }

    /// One transmitter's biography, assembled from the three tables that hold it.
    ///
    /// `Rwah` has no link back to any hadith: a narrator is only ever reached
    /// through an id the parser lifted out of the chain.
    func fetchNarrator(bookId: Int, narratorId: Int) -> HadithNarratorProfile? {
        let sql = """
            SELECT ID, Name, Konia, Nasab, Laqab, Shohra, Tabaka, Country,
                   DOB, DOD, BirthPos, DeathPos, Notes, Source, IbnHajarSay,
                   Aqwal, ShortName
            FROM Rwah
            WHERE ID = ?
            LIMIT 1
            """
        let profiles = rows(db: openDB(for: bookId), sql, bind: { sqlite3_bind_int($0, 1, Int32(narratorId)) }) { stmt in
            HadithNarratorProfile(id: Int(sqlite3_column_int(stmt, 0)),
                                  name: col(stmt, 1),
                                  shortName: col(stmt, 16),
                                  kunya: col(stmt, 2),
                                  lineage: col(stmt, 3),
                                  epithet: col(stmt, 4),
                                  knownAs: col(stmt, 5),
                                  generation: col(stmt, 6),
                                  country: col(stmt, 7),
                                  birthYear: col(stmt, 8),
                                  deathYear: col(stmt, 9),
                                  birthPlace: col(stmt, 10),
                                  deathPlace: col(stmt, 11),
                                  notes: col(stmt, 12),
                                  source: col(stmt, 13),
                                  ibnHajarVerdict: col(stmt, 14),
                                  verdictsSummary: col(stmt, 15),
                                  verdicts: [],
                                  sources: [])
        }
        guard let profile = profiles.first, !profile.isEmpty else { return nil }

        let verdicts = rows(db: openDB(for: bookId), """
            SELECT AqwalId, Name, Shohra, Say
            FROM RwahAqwal
            WHERE RawyId = ?
            ORDER BY AqwalId
            """, bind: { sqlite3_bind_int($0, 1, Int32(narratorId)) }) { stmt in
            HadithNarratorVerdict(id: Int(sqlite3_column_int(stmt, 0)),
                                  scholar: col(stmt, 1),
                                  scholarKnownAs: col(stmt, 2),
                                  verdict: col(stmt, 3))
        }.filter { !$0.verdict.isEmpty }

        let sources = rows(db: openDB(for: bookId), """
            SELECT Source
            FROM RwahSources
            WHERE RawyId = ?
            ORDER BY SourceId
            """, bind: { sqlite3_bind_int($0, 1, Int32(narratorId)) }) { col($0, 0) }
            .filter { !$0.isEmpty }

        return HadithNarratorProfile(id: profile.id,
                                     name: profile.name,
                                     shortName: profile.shortName,
                                     kunya: profile.kunya,
                                     lineage: profile.lineage,
                                     epithet: profile.epithet,
                                     knownAs: profile.knownAs,
                                     generation: profile.generation,
                                     country: profile.country,
                                     birthYear: profile.birthYear,
                                     deathYear: profile.deathYear,
                                     birthPlace: profile.birthPlace,
                                     deathPlace: profile.deathPlace,
                                     notes: profile.notes,
                                     source: profile.source,
                                     ibnHajarVerdict: profile.ibnHajarVerdict,
                                     verdictsSummary: profile.verdictsSummary,
                                     verdicts: verdicts,
                                     sources: sources)
    }

    // MARK: - Search (across all downloaded books)

    func searchAllBooks(_ searchQuery: HadithSearchQuery,
                        limit: Int = HadithSearchPlanner.resultLimit) -> HadithSearchOutcome {
        let books = loadManifest()
        let installed = Set(HadithDownloadManager.shared.downloadedBookIds)

        var scanned: [Int: [Int]] = [:]
        for book in books where installed.contains(book.id) {
            let ids = scanMatches(bookId: book.id, searchQuery: searchQuery,
                                  cap: HadithSearchPlanner.scanCap)
            guard !ids.isEmpty else { continue }
            scanned[book.id] = ids
        }

        let counts = books.compactMap { book -> HadithSearchPlanner.BookCount? in
            guard let ids = scanned[book.id] else { return nil }
            return HadithSearchPlanner.BookCount(bookId: book.id, matches: ids.count)
        }
        let quotas = HadithSearchPlanner.allocate(counts: counts, limit: limit)

        let matches = books.compactMap { book -> HadithBookMatches? in
            guard let ids = scanned[book.id], let quota = quotas[book.id], quota > 0 else { return nil }
            return bookMatches(book: book, scannedIds: ids, take: quota)
        }

        return HadithSearchOutcome(query: searchQuery,
                                   books: matches,
                                   notInstalled: books.filter { !installed.contains($0.id) })
    }

    func searchResults(in book: HadithBook,
                       searchQuery: HadithSearchQuery,
                       limit: Int = HadithSearchPlanner.expandedLimit) -> HadithBookMatches? {
        let ids = scanMatches(bookId: book.id, searchQuery: searchQuery,
                              cap: HadithSearchPlanner.scanCap)
        guard !ids.isEmpty else { return nil }
        return bookMatches(book: book, scannedIds: ids, take: min(limit, ids.count))
    }

    private func bookMatches(book: HadithBook, scannedIds: [Int], take: Int) -> HadithBookMatches? {
        let entries = hydrate(bookId: book.id, autoIds: Array(scannedIds.prefix(take)))
        guard !entries.isEmpty else { return nil }
        return HadithBookMatches(
            book: book,
            results: entries.map { HadithSearchResult(id: $0.id, hadith: $0, book: book) },
            totalMatches: scannedIds.count,
            isTotalApproximate: scannedIds.count >= HadithSearchPlanner.scanCap)
    }

    private func scanMatches(bookId: Int, searchQuery: HadithSearchQuery, cap: Int) -> [Int] {
        let capability = bookCapabilities(for: bookId)
        let predicate = SearchPredicate(searchQuery: searchQuery,
                                        matchesTranslation: capability.hasTranslation)
        let sql = """
            SELECT AutoID
            FROM Hadeths
            WHERE Type = \(Self.hadithType) AND \(predicate.whereClause)
            ORDER BY AutoID
            LIMIT \(cap)
            """
        return rows(db: openDB(for: bookId), sql, bind: predicate.bind) {
            Int(sqlite3_column_int($0, 0))
        }
    }

    private func hydrate(bookId: Int, autoIds: [Int]) -> [HadithEntry] {
        guard !autoIds.isEmpty else { return [] }
        let capability = bookCapabilities(for: bookId)
        let placeholders = Array(repeating: "?", count: autoIds.count).joined(separator: ", ")
        let sql = """
            SELECT \(capability.hadithColumns)
            FROM Hadeths
            WHERE AutoID IN (\(placeholders))
            ORDER BY AutoID
            """
        return rows(db: openDB(for: bookId), sql, bind: { stmt in
            for (offset, autoId) in autoIds.enumerated() {
                _ = sqlite3_bind_int(stmt, Int32(offset + 1), Int32(autoId))
            }
        }) { hadithEntry(from: $0) }
    }

    private struct SearchPredicate {

        let whereClause: String
        private let patterns: [String]

        init(searchQuery: HadithSearchQuery, matchesTranslation: Bool) {
            var clauses: [String] = []
            var patterns: [String] = []

            for term in searchQuery.terms {
                let arabic = patterns.count + 1
                patterns.append(HadithSearchQuery.likePattern(term.folded))

                guard matchesTranslation else {
                    clauses.append("SearchText LIKE ?\(arabic) ESCAPE '\\'")
                    continue
                }
                let latin = patterns.count + 1
                patterns.append(HadithSearchQuery.likePattern(term.latin))
                clauses.append("(SearchText LIKE ?\(arabic) ESCAPE '\\'"
                               + " OR TranslationSearch LIKE ?\(latin) ESCAPE '\\')")
            }

            self.whereClause = clauses.joined(separator: " AND ")
            self.patterns = patterns
        }

        func bind(_ stmt: OpaquePointer) {
            for (offset, pattern) in patterns.enumerated() {
                _ = sqlite3_bind_text(stmt, Int32(offset + 1), pattern, -1, SQLITE_TRANSIENT)
            }
        }
    }

    // MARK: - Private helpers

    private func rows<T>(db: OpaquePointer?,
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
        let markup = HadithMarkupParser.parse(col(stmt, 3))
        let numbers = Self.parseNumbers(col(stmt, 4))
        let kind = col(stmt, 8)
        // `FolderNum` and `PageNum` are the book's own citation; the one the
        // body carries inline is a fallback for the rows that lack them.
        let volume = Int(sqlite3_column_int(stmt, 6))
        let pageNo = Int(sqlite3_column_int(stmt, 7))

        var entry = HadithEntry(
            id:            Int(sqlite3_column_int(stmt, 0)),
            bookId:        Int(sqlite3_column_int(stmt, 1)),
            chapterId:     Int(sqlite3_column_int(stmt, 2)),
            number:        numbers.first ?? markup.numbers.first ?? 0,
            arabicText:    markup.text,
            translation:   col(stmt, 12),
            narrator:      col(stmt, 11),
            grade:         markup.ruling,
            gradeEn:       "",
            isMarfu:       kind.contains("مرفوع"),
            narratorChain: markup.isnadText,
            takhrij:       col(stmt, 13),
            commentary:    col(stmt, 5),
            volume:        volume > 0 ? volume : markup.volume,
            pageNo:        pageNo > 0 ? pageNo : markup.pageNo
        )
        entry.numbers = numbers.isEmpty ? markup.numbers : numbers
        entry.kind = kind
        entry.brief = col(stmt, 9)
        entry.breadcrumb = col(stmt, 10)
        entry.markup = markup
        entry.hadethID = Int(sqlite3_column_int(stmt, 14))
        return entry
    }

    /// Reads the `@1@2@` set the corpus stores numbers in.
    static func parseNumbers(_ raw: String) -> [Int] {
        raw.split(separator: "@").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}

private func col(_ stmt: OpaquePointer, _ index: Int32) -> String {
    guard let cStr = sqlite3_column_text(stmt, index) else { return "" }
    return String(cString: cStr)
}

// MARK: - Last Read Manager

final class HadithLastReadManager {

    static let shared = HadithLastReadManager()
    static let storageKey = "hadith_last_read_position"
    private init() {}

    func save(_ position: LastReadPosition) {
        guard let data = try? JSONEncoder().encode(position) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    func load() -> LastReadPosition? {
        guard let data     = UserDefaults.standard.data(forKey: Self.storageKey),
              let position = try? JSONDecoder().decode(LastReadPosition.self, from: data) else { return nil }
        return position
    }
}
