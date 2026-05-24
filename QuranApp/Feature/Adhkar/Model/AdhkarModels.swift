//
//  AdhkarModels.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation

struct DhikrCategory: Codable, Identifiable, Hashable {
    let id: String
    let titleAr: String
    let titleEn: String
    let icon: String
    let adhkar: [Dhikr]
    let condition: String?
    let section: String?

    init(id: String, titleAr: String, titleEn: String, icon: String,
         adhkar: [Dhikr], condition: String? = nil, section: String? = nil) {
        self.id = id
        self.titleAr = titleAr
        self.titleEn = titleEn
        self.icon = icon
        self.adhkar = adhkar
        self.condition = condition
        self.section = section
    }
}

struct Dhikr: Codable, Identifiable, Hashable {
    let id: String
    let textAr: String
    let description: String?
    let title: String?
    let count: Int
    let audio: String?
}

struct AllahName: Codable, Identifiable, Hashable {
    let id: Int
    let nameAr: String
    let transliteration: String
    let meaning: String?
    let descriptionAr: String?
}

enum DhikrSection: String {
    case daily = "daily"
    case special = "special"
    case more = "more"
}
