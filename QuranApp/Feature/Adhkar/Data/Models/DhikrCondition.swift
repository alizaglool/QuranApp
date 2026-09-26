//
//  DhikrCondition.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import Foundation

/// A calendar- or clock-based gate deciding whether a dhikr category is offered right now.
/// Raw values are the `condition` strings used in `adhkar.json`.
enum DhikrCondition: String {

    // Hijri calendar windows — evaluated in C1.
    case dhulHijjahFirstTen = "dhul_hijjah_1_10"
    case arafah = "arafah"
    case eidAdha = "eid_adha"
    case tashreeq = "tashreeq"
    case ramadan = "ramadan"
    case eidFitr = "eid_fitr"

    // Prayer-time windows — recognised now, evaluated in C2.
    case qiyam = "qiyam"
    case lastThirdOfNight = "night_third"
    case afterIsha = "after_isha"
    case afterMaghrib = "after_maghrib"
    case morning = "morning"
    case evening = "evening"
}
