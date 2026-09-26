//
//  MyDhikr.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import Foundation

struct MyDhikr: Identifiable, Codable {
    let id: String
    let textAr: String
    let count: Int
    let createdAt: Date

    init(id: String = UUID().uuidString, textAr: String, count: Int = 33, createdAt: Date = Date()) {
        self.id = id
        self.textAr = textAr
        self.count = count
        self.createdAt = createdAt
    }
}
