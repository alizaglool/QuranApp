//
//  HijriCalendarDateTextFormatter.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct HijriCalendarDateTextFormatter {

    static func text(for date: Date,
                     identifier: Calendar.Identifier,
                     languageCode: String,
                     format: String) -> String {
        let locale = Locale(identifier: languageCode)
        var calendar = Calendar(identifier: identifier)
        calendar.locale = locale

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
