//
//  EgyptianRadioStationReference.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation

// MARK: - EgyptianRadioStationReference

enum EgyptianRadioStationReference {

    static let identifier: Int = 900_003

    static let fallback = RadioStation(
        id: identifier,
        nameAr: "إذاعة القرآن الكريم من القاهرة",
        nameEn: "Holy Quran Radio from Cairo",
        url: "https://stream.radiojar.com/8s5u5tpdtwzuv"
    )

    static func station(in stations: [RadioStation]) -> RadioStation {
        stations.first { $0.id == identifier } ?? fallback
    }
}
