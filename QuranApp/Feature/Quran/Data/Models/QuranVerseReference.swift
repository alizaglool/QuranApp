//
//  QuranVerseReference.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct QuranVerseReference: Hashable {

    let surahNumber: Int
    let verseNumber: Int

    init(surahNumber: Int, verseNumber: Int) {
        self.surahNumber = surahNumber
        self.verseNumber = verseNumber
    }
}
