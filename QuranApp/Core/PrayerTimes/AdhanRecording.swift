//
//  AdhanRecording.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 02/11/2026.
//

import Foundation

struct AdhanRecording: Identifiable, Equatable {

    let id: String
    let arabicTitle: String
    let englishTitle: String
    let arabicOrigin: String?
    let englishOrigin: String?
    let notificationToneDuration: TimeInterval
    let fullAdhanDuration: TimeInterval

    var notificationToneResource: String { "adhan_tone_\(id)" }

    var fullAdhanResource: String { "adhan_full_\(id)" }
}

// MARK: - Bundled Catalog

extension AdhanRecording {

    static let defaultIdentifier = "mecca_ali_mulla"

    static let bundled: [AdhanRecording] = [
        AdhanRecording(id: "mecca_ali_mulla",
                       arabicTitle: "علي ملا",
                       englishTitle: "Ali Mulla",
                       arabicOrigin: "الحرم المكي",
                       englishOrigin: "Al-Haram, Makkah",
                       notificationToneDuration: 29,
                       fullAdhanDuration: 202),
        AdhanRecording(id: "almadena_almonawra",
                       arabicTitle: "أذان المدينة المنورة",
                       englishTitle: "Adhan of Madinah",
                       arabicOrigin: nil,
                       englishOrigin: nil,
                       notificationToneDuration: 29,
                       fullAdhanDuration: 188),
        AdhanRecording(id: "azan_alquds",
                       arabicTitle: "أذان القدس",
                       englishTitle: "Adhan of Al-Quds",
                       arabicOrigin: nil,
                       englishOrigin: nil,
                       notificationToneDuration: 29,
                       fullAdhanDuration: 182),
        AdhanRecording(id: "muhammed_altablawy",
                       arabicTitle: "محمد محمود الطبلاوي",
                       englishTitle: "Muhammad Al-Tablawy",
                       arabicOrigin: nil,
                       englishOrigin: nil,
                       notificationToneDuration: 29,
                       fullAdhanDuration: 189),
        AdhanRecording(id: "yasser_aldosary",
                       arabicTitle: "ياسر الدوسري",
                       englishTitle: "Yasser Al-Dosari",
                       arabicOrigin: nil,
                       englishOrigin: nil,
                       notificationToneDuration: 29,
                       fullAdhanDuration: 177),
        AdhanRecording(id: "edres_abkar",
                       arabicTitle: "إدريس أبكر",
                       englishTitle: "Idris Abkar",
                       arabicOrigin: nil,
                       englishOrigin: nil,
                       notificationToneDuration: 29,
                       fullAdhanDuration: 126),
        AdhanRecording(id: "saad_alghamdy",
                       arabicTitle: "سعد الغامدي",
                       englishTitle: "Saad Al-Ghamdi",
                       arabicOrigin: nil,
                       englishOrigin: nil,
                       notificationToneDuration: 29,
                       fullAdhanDuration: 116),
        AdhanRecording(id: "islam_sobhey",
                       arabicTitle: "إسلام صبحي",
                       englishTitle: "Islam Sobhi",
                       arabicOrigin: nil,
                       englishOrigin: nil,
                       notificationToneDuration: 29,
                       fullAdhanDuration: 173)
    ]

    static func recording(forIdentifier identifier: String) -> AdhanRecording? {
        AdhanRecording.bundled.first { $0.id == identifier }
    }
}
