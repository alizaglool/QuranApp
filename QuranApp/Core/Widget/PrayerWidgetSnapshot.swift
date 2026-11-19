//
//  PrayerWidgetSnapshot.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct PrayerWidgetSlot: Codable, Equatable, Identifiable {

    let id: String
    let title: String
    let iconName: String
    let timeText: String
    let date: Date
    let isObligatory: Bool
}

struct PrayerWidgetDay: Codable, Equatable, Identifiable {

    let dayKey: String
    let dayOffset: Int
    let startDate: Date
    let hijriDateText: String
    let gregorianDateText: String
    let slots: [PrayerWidgetSlot]

    var id: String { dayKey }
}

struct PrayerWidgetLabels: Codable, Equatable {

    let nextPrayerTitle: String
    let remainingTitle: String
    let scheduleTitle: String
    let unavailableMessage: String
    let nowTitle: String
    let hourMinuteRemainingFormat: String
    let minuteRemainingFormat: String
    let nextPrayerGalleryTitle: String
    let nextPrayerGalleryDescription: String
    let scheduleGalleryTitle: String
    let scheduleGalleryDescription: String
    let dateGalleryTitle: String
    let dateGalleryDescription: String

    static let placeholder = PrayerWidgetLabels(nextPrayerTitle: "",
                                                remainingTitle: "",
                                                scheduleTitle: "",
                                                unavailableMessage: "",
                                                nowTitle: "",
                                                hourMinuteRemainingFormat: "%@:%@",
                                                minuteRemainingFormat: "%@",
                                                nextPrayerGalleryTitle: "",
                                                nextPrayerGalleryDescription: "",
                                                scheduleGalleryTitle: "",
                                                scheduleGalleryDescription: "",
                                                dateGalleryTitle: "",
                                                dateGalleryDescription: "")
}

struct PrayerWidgetSnapshot: Codable, Equatable {

    let languageCode: String
    let isRightToLeft: Bool
    let locationTitle: String
    let days: [PrayerWidgetDay]
    let labels: PrayerWidgetLabels

    static let placeholder = PrayerWidgetSnapshot(languageCode: "en",
                                                  isRightToLeft: false,
                                                  locationTitle: "",
                                                  days: [],
                                                  labels: .placeholder)
}

// MARK: - Queries

extension PrayerWidgetSnapshot {

    var slots: [PrayerWidgetSlot] { days.flatMap { $0.slots } }

    var isEmpty: Bool { slots.isEmpty }

    func day(at date: Date) -> PrayerWidgetDay? {
        days.last { $0.startDate <= date } ?? days.first
    }

    func nextSlot(at date: Date) -> PrayerWidgetSlot? {
        slots.first { $0.date > date }
    }

    func currentSlot(at date: Date) -> PrayerWidgetSlot? {
        slots.last { $0.date <= date }
    }

    func scheduleSlots(at date: Date) -> [PrayerWidgetSlot] {
        day(at: date)?.slots ?? []
    }

    func remainingText(at date: Date) -> String {
        guard let next = nextSlot(at: date) else { return "" }
        let totalMinutes = Int(next.date.timeIntervalSince(date) / 60)
        guard totalMinutes > 0 else { return labels.nowTitle }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        guard hours > 0 else {
            return String(format: labels.minuteRemainingFormat, String(minutes))
        }
        return String(format: labels.hourMinuteRemainingFormat, String(hours), String(minutes))
    }
}

// MARK: - Timeline

extension PrayerWidgetSnapshot {

    static let fineGrainedWindow: TimeInterval = 2 * 60 * 60
    static let coarseWindow: TimeInterval = 14 * 60 * 60
    static let coarseStep: TimeInterval = 10 * 60

    func timelineDates(from date: Date) -> [Date] {
        var dates: [Date] = [date]
        var offset: TimeInterval = 60

        while offset <= PrayerWidgetSnapshot.fineGrainedWindow {
            dates.append(date.addingTimeInterval(offset))
            offset += 60
        }
        offset = PrayerWidgetSnapshot.fineGrainedWindow + PrayerWidgetSnapshot.coarseStep
        while offset <= PrayerWidgetSnapshot.coarseWindow {
            dates.append(date.addingTimeInterval(offset))
            offset += PrayerWidgetSnapshot.coarseStep
        }

        let horizon = date.addingTimeInterval(PrayerWidgetSnapshot.coarseWindow)
        let boundaries = slots.map { $0.date }.filter { $0 > date && $0 <= horizon }
        return (dates + boundaries).sorted().reduce(into: [Date]()) { result, candidate in
            guard let last = result.last else {
                result.append(candidate)
                return
            }
            guard candidate.timeIntervalSince(last) >= 1 else { return }
            result.append(candidate)
        }
    }
}
