//
//  HadithMetaService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import Foundation
import SQLite3

final class HadithMetaService {
    static let shared = HadithMetaService()

    private static let resource = "hadith_meta"
    private static let fileExtension = "sqlite"
    private static let trailingSeparator = "@@"

    private var handle: OpaquePointer?
    private var didOpen = false
    private let lock = NSLock()

    private init() {}

    deinit {
        if let handle { sqlite3_close(handle) }
    }

    // MARK: - Notes

    func notes(for references: [HadithNoteRef]) -> [HadithNote] {
        guard !references.isEmpty else { return [] }

        let ids = references.map(\.noteID)
        let placeholders = Array(repeating: "?", count: ids.count).joined(separator: ", ")
        let sql = "SELECT NoteID, NoteText FROM Notes WHERE NoteID IN (\(placeholders))"

        let fetched = rows(sql, bind: { stmt in
            for (offset, id) in ids.enumerated() {
                _ = sqlite3_bind_int(stmt, Int32(offset + 1), Int32(id))
            }
        }) { stmt in
            (id: Int(sqlite3_column_int(stmt, 0)), text: Self.clean(column(stmt, 1)))
        }

        let texts = Dictionary(fetched.map { ($0.id, $0.text) }, uniquingKeysWith: { first, _ in first })

        return references.compactMap { reference in
            guard let text = texts[reference.noteID], !text.isEmpty else { return nil }
            return HadithNote(id: reference.noteID, text: text, offset: reference.offset)
        }
    }

    // MARK: - Subjects

    func subjectPaths(nodeIDs: [Int]) -> [HadithSubjectPath] {
        guard !nodeIDs.isEmpty else { return [] }

        var seen: Set<Int> = []
        var paths: [HadithSubjectPath] = []

        for nodeID in nodeIDs where seen.insert(nodeID).inserted {
            let segments = pathSegments(nodeID: nodeID)
            guard !segments.isEmpty else { continue }
            paths.append(HadithSubjectPath(id: nodeID, segments: segments))
        }
        return paths
    }

    private func pathSegments(nodeID: Int) -> [String] {
        let sql = """
            WITH RECURSIVE ancestry(NodeID, ParentID, depth) AS (
                SELECT NodeID, ParentID, 0
                FROM SubjectsTreeLinks
                WHERE NodeID = ?
                UNION ALL
                SELECT link.NodeID, link.ParentID, ancestry.depth + 1
                FROM SubjectsTreeLinks link
                JOIN ancestry ON link.NodeID = ancestry.ParentID
            )
            SELECT tree.NodeText
            FROM ancestry
            JOIN SubjectsTree tree ON tree.NodeID = ancestry.NodeID
            ORDER BY ancestry.depth DESC
            """
        return rows(sql, bind: { sqlite3_bind_int($0, 1, Int32(nodeID)) }) { stmt in
            column(stmt, 0)
        }
        .filter { !$0.isEmpty }
    }

    // MARK: - Database

    private func openDB() -> OpaquePointer? {
        lock.lock(); defer { lock.unlock() }
        if didOpen { return handle }
        didOpen = true

        guard let path = Bundle.main.path(forResource: Self.resource,
                                          ofType: Self.fileExtension) else { return nil }
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK, let db else {
            if let db { sqlite3_close(db) }
            return nil
        }
        handle = db
        return db
    }

    private func rows<T>(_ sql: String,
                         bind: ((OpaquePointer) -> Void)? = nil,
                         map: (OpaquePointer) -> T) -> [T] {
        guard let db = openDB() else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else { return [] }
        bind?(stmt)
        var results: [T] = []
        while sqlite3_step(stmt) == SQLITE_ROW { results.append(map(stmt)) }
        sqlite3_finalize(stmt)
        return results
    }

    private static func clean(_ raw: String) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix(trailingSeparator) {
            text.removeLast(trailingSeparator.count)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
}

private func column(_ stmt: OpaquePointer, _ index: Int32) -> String {
    guard let value = sqlite3_column_text(stmt, index) else { return "" }
    return String(cString: value)
}
