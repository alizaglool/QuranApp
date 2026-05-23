//
//  QuranTextResponse.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation

// MARK: - Quran Text Response
// https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranuthman.json

struct QuranTextResponse: Codable {
    let quran: [QuranVerse]
}

struct QuranVerse: Codable {
    let chapter: Int
    let verse: Int
    let text: String
}

// MARK: - Quran Info Response
// https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/info.json

struct QuranInfoResponse: Codable {
    let chapters: [String: ChapterInfo]
}

struct ChapterInfo: Codable {
    let arabicname: String
    let name: String
    let englishname: String
    let apiname: String?
    let verses: Int
    let startpage: Int?
    let endpage: Int?
    let revelation: String? // "Meccan" or "Medinan"
}

// MARK: - MP3Quran Reciters Response
// https://mp3quran.net/api/v3/reciters?language=ar

struct RecitersResponse: Codable {
    let reciters: [ReciterDTO]
}

struct ReciterDTO: Codable {
    let id: Int
    let name: String
    let letter: String?
    let moshaf: [MoshafDTO]
}

struct MoshafDTO: Codable {
    let id: Int
    let name: String
    let server: String
    let surahTotal: Int
    let surahList: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, server
        case surahTotal = "surah_total"
        case surahList = "surah_list"
    }
}
