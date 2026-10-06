//
//  PrayerTimesAPIResponse.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-25.
//

import Foundation

// https://api.aladhan.com/v1/timingsByCity?city=Riyadh&country=SA

struct PrayerTimesAPIResponse: Codable {
    let data: PrayerTimesData
}

struct PrayerTimesData: Codable {
    let timings: PrayerTimings
    let date: PrayerDate
    /// Optional so a payload without it still decodes. Its `timezone` names the
    /// clock the timings are on, which is not the device's: the city is pinned
    /// to Riyadh wherever the user happens to be.
    let meta: PrayerMeta?
}

struct PrayerMeta: Codable {
    let timezone: String
}

/// Aladhan returns plain `"HH:mm"` strings. Property names match the payload's
/// own capitalisation, including `Lastthird`.
///
/// Only the five the Home prayer card has always read are required. The anchors
/// the time-gated sections added are optional on purpose: a payload that omits
/// one must not fail the whole decode and take Home's prayer times down with it.
struct PrayerTimings: Codable {
    let Fajr: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String

    let Sunrise: String?
    let Sunset: String?
    let Midnight: String?
    let Lastthird: String?
}

struct PrayerDate: Codable {
    let hijri: HijriDate
    let gregorian: GregorianDate
}

struct HijriDate: Codable {
    let day: String
    let month: HijriMonth
    let year: String
}

struct HijriMonth: Codable {
    let en: String
    let ar: String
    let number: Int
}

struct GregorianDate: Codable {
    let day: String
    let month: GregorianMonth
    let year: String
}

struct GregorianMonth: Codable {
    let en: String
    let number: Int
}
