//
//  RadioStation.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation

// MARK: - RadioStation

struct RadioStation: Identifiable, Hashable, Codable {

    let id: Int
    let nameAr: String
    let nameEn: String
    let url: String
    let isLive: Bool
    let thumbnail: String?

    init(id: Int, nameAr: String, nameEn: String, url: String, isLive: Bool = false, thumbnail: String? = nil) {
        self.id = id
        self.nameAr = nameAr
        self.nameEn = nameEn
        self.url = url
        self.isLive = isLive
        self.thumbnail = thumbnail
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        nameAr = try container.decode(String.self, forKey: .nameAr)
        nameEn = try container.decodeIfPresent(String.self, forKey: .nameEn) ?? nameAr
        url = try container.decode(String.self, forKey: .url)
        isLive = try container.decodeIfPresent(Bool.self, forKey: .isLive) ?? false
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
    }

    var streamURL: URL? {
        URL(string: url)
    }
}

// MARK: - OfflineRadioStation

struct OfflineRadioStation: Identifiable, Hashable {

    let reciterSlug: String
    let nameAr: String
    let nameEn: String
    let surahNumbers: [Int]

    var id: String { reciterSlug }

    var surahCount: Int { surahNumbers.count }
}
