//
//  QuranTextService.swift
//  QuranApp
//

import Foundation

// MARK: - QuranTextService

/// Reads quran_text.json (format: {"surah_verse": "arabic text", ...}) once and
/// exposes fast O(1) lookups. Also owns the verse-end glyph factory so the
/// rendering logic lives in one place.
final class QuranTextService {

    static let shared = QuranTextService()

    private let verses: [String: String]

    private init() {
        guard
            let url  = Bundle.main.url(forResource: "quran_text", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else {
            verses = [:]
            return
        }
        // Strip leading BOM that exists on verse 1:1 in this JSON edition.
        verses = dict.mapValues {
            $0.hasPrefix("\u{FEFF}") ? String($0.dropFirst()) : $0
        }
    }

    // MARK: - Verse Text

    /// Arabic text for a given surah + verse, or nil if not in the bundle.
    func text(surah: Int, verse: Int) -> String? {
        verses["\(surah)_\(verse)"]
    }

    // MARK: - Verse-End Glyph

    /// Returns the ornamental verse-end marker character from the KFGQPCHafsSmart
    /// font's private-use block (U+E95A … U+EA58, one per verse number 1-286).
    /// Render this character in the same Hafs font as the verse text.
    static func verseEndGlyph(for verseNumber: Int) -> String? {
        guard (1...286).contains(verseNumber),
              let scalar = Unicode.Scalar(0xE95A + verseNumber - 1)
        else { return nil }
        return String(scalar)
    }
}
