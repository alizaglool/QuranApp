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
}

struct PrayerTimings: Codable {
    let Fajr: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String
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
