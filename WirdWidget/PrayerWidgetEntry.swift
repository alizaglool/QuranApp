//
//  PrayerWidgetEntry.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import WidgetKit

struct PrayerWidgetEntry: TimelineEntry {

    let date: Date
    let snapshot: PrayerWidgetSnapshot
}

// MARK: - Derived

extension PrayerWidgetEntry {

    var nextSlot: PrayerWidgetSlot? { snapshot.nextSlot(at: date) }

    var currentSlot: PrayerWidgetSlot? { snapshot.currentSlot(at: date) }

    var scheduleSlots: [PrayerWidgetSlot] { snapshot.scheduleSlots(at: date) }

    var upcomingSlots: [PrayerWidgetSlot] { snapshot.slots.filter { $0.date > date } }

    var remainingText: String { snapshot.remainingText(at: date) }

    var hijriDateText: String { snapshot.day(at: date)?.hijriDateText ?? "" }

    var gregorianDateText: String { snapshot.day(at: date)?.gregorianDateText ?? "" }

    var hasContent: Bool { nextSlot != nil }
}
