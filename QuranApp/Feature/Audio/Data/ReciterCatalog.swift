//
//  ReciterCatalog.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 11/10/2026
//

import Foundation

// MARK: - Catalog

struct ReciterCatalog: Decodable {
    let baseUrl: String?
    let featured: [FeaturedReciter]
    let reciters: [RemoteReciter]
}

// MARK: - Featured

struct FeaturedReciter: Codable {
    let everyayahSlug: String
    let mp3quranId: Int?
    let name: String
    let nameAr: String
    let url: String?
}

// MARK: - Reciter

struct RemoteReciter: Decodable {
    let name: String
    let nameAr: String
    let file: String?
    let url: String?
    let everyayahSlug: String
    let mp3quranId: Int?
    let bitrateKbps: Int
    let sizeMB: Int
    let bundledIds: [String]?
    let radioIds: [Int]?
}

// MARK: - Mapping

extension RemoteReciter {

    var reciterInfo: ReciterInfo {
        ReciterInfo(
            id: everyayahSlug,
            arabicName: nameAr,
            englishName: name,
            bitrateKbps: bitrateKbps,
            sizeMB: sizeMB,
            mp3quranId: mp3quranId,
            radioIds: radioIds ?? [],
            imageURL: url
        )
    }
}
