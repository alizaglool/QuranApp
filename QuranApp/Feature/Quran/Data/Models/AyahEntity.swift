//
//  AyahEntity.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation
import SwiftData

@Model
final class AyahEntity {
    @Attribute(.unique) var id: String // "surahId-verseNumber" e.g. "2-142"
    var surahId: Int
    var verseNumber: Int
    var text: String
    
    init(surahId: Int, verseNumber: Int, text: String) {
        self.id = "\(surahId)-\(verseNumber)"
        self.surahId = surahId
        self.verseNumber = verseNumber
        self.text = text
    }
}
