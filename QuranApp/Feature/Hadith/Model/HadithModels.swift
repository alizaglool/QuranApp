//
//  HadithModels.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation

struct HadithCollection: Codable, Identifiable, Hashable {
    let id: String
    let nameAr: String
    let nameEn: String
    let author: String
    let icon: String
    let hadiths: [Hadith]

    var count: Int { hadiths.count }
}

struct Hadith: Codable, Identifiable, Hashable {
    let id: String
    let number: Int
    let textAr: String
    let translation: String
    let narrator: String
    let reference: String
}
