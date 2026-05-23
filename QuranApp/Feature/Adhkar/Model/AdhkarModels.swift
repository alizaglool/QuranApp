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
}

struct Dhikr: Codable, Identifiable, Hashable {
    let id: String
    let textAr: String
    let title: String?
    let count: Int
    let audio: String?
}
