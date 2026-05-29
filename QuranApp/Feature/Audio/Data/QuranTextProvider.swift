//
//  QuranTextProvider.swift
//  QuranApp
//
//  Loads quran_text.json from the app bundle once at first access.
//  Returns nil gracefully when the file is absent or a verse key is missing.
//  Add the full quran_text.json to /QuranApp/Resources/ to enable verse text.
//  Run Scripts/generate_quran_text.py to generate the complete file.
//

import Foundation

final class QuranTextProvider {

    static let shared = QuranTextProvider()

    private let texts: [String: String]

    private init() {
        guard
            let url  = Bundle.main.url(forResource: "quran_text", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        else {
            texts = [:]
            return
        }
        texts = dict
    }

    func text(surah: Int, verse: Int) -> String? {
        texts["\(surah)_\(verse)"]
    }
}
