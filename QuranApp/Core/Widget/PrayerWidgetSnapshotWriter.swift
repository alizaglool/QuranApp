//
//  PrayerWidgetSnapshotWriter.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation
import WidgetKit
import Core

@MainActor
final class PrayerWidgetSnapshotWriter {

    static let shared = PrayerWidgetSnapshotWriter()

    private static let projectedDayCount = 2
    private static let widgetSlots: [PrayerSlot] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]

    private let locationStore: SelectedLocationStore
    private let localizationManager: LocalizationManager
    private let locationLabelFormatter = SelectedLocationLabelFormatter()
    private let defaults: UserDefaults

    init(locationStore: SelectedLocationStore? = nil,
         localizationManager: LocalizationManager? = nil,
         defaults: UserDefaults = PrayerWidgetSharedStore.defaults) {
        self.locationStore = locationStore ?? .shared
        self.localizationManager = localizationManager ?? .shared
        self.defaults = defaults
    }

    func refresh(day: DayPrayerTimes?) {
        guard let day else {
            guard PrayerWidgetSharedStore.loadSnapshot(from: defaults) != nil else { return }
            PrayerWidgetSharedStore.clear(in: defaults)
            reloadTimelines()
            return
        }
        guard let snapshot = makeSnapshot(day: day) else { return }
        guard snapshot != PrayerWidgetSharedStore.loadSnapshot(from: defaults) else { return }

        PrayerWidgetSharedStore.save(snapshot, to: defaults)
        reloadTimelines()
    }

    private func reloadTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Snapshot

private extension PrayerWidgetSnapshotWriter {

    func makeSnapshot(day: DayPrayerTimes) -> PrayerWidgetSnapshot? {
        let calendar = day.calendar
        guard let anchorDate = DayPrayerTimes.date(fromDayKey: day.dayKey, calendar: calendar) else { return nil }

        let anchorDayStart = calendar.startOfDay(for: anchorDate)
        let days = (0 ..< PrayerWidgetSnapshotWriter.projectedDayCount).compactMap {
            makeDay(dayOffset: $0, day: day, anchorDayStart: anchorDayStart, calendar: calendar)
        }
        guard !days.isEmpty else { return nil }

        return PrayerWidgetSnapshot(languageCode: languageCode,
                                    isRightToLeft: isArabic,
                                    locationTitle: locationLabelFormatter.displayLabel(for: locationStore.selectedLocation),
                                    days: days,
                                    labels: labels)
    }

    func makeDay(dayOffset: Int,
                 day: DayPrayerTimes,
                 anchorDayStart: Date,
                 calendar: Calendar) -> PrayerWidgetDay? {
        guard let dayStart = calendar.date(byAdding: .day, value: dayOffset, to: anchorDayStart) else { return nil }

        let dayKey = DayPrayerTimes.dayKey(for: dayStart, calendar: calendar)
        let slots = PrayerWidgetSnapshotWriter.widgetSlots.compactMap {
            makeSlot($0, day: day, dayStart: dayStart, dayKey: dayKey, calendar: calendar)
        }
        guard !slots.isEmpty else { return nil }

        return PrayerWidgetDay(dayKey: dayKey,
                               dayOffset: dayOffset,
                               startDate: dayStart,
                               hijriDateText: hijriText(for: dayStart),
                               gregorianDateText: gregorianText(for: dayStart),
                               slots: slots)
    }

    func makeSlot(_ slot: PrayerSlot,
                  day: DayPrayerTimes,
                  dayStart: Date,
                  dayKey: String,
                  calendar: Calendar) -> PrayerWidgetSlot? {
        let minutes = day.minutesSinceMidnight(of: slot)
        guard let date = calendar.date(byAdding: .minute, value: minutes, to: dayStart) else { return nil }

        return PrayerWidgetSlot(id: "\(dayKey)-\(slot.rawValue)",
                                title: slot.localizedName,
                                iconName: slot.iconName,
                                timeText: PrayerClockFormatter.twelveHourClock(fromMinutesSinceMidnight: minutes),
                                date: date,
                                isObligatory: PrayerSlot.obligatorySlots.contains(slot))
    }
}

// MARK: - Labels

private extension PrayerWidgetSnapshotWriter {

    var isArabic: Bool { localizationManager.currentLanguage == .Arabic }

    var languageCode: String { isArabic ? "ar" : "en" }

    var labels: PrayerWidgetLabels {
        PrayerWidgetLabels(nextPrayerTitle: AppLocalizedKeys.nextPrayerLabel.value,
                           remainingTitle: AppLocalizedKeys.remaining.value,
                           scheduleTitle: AppLocalizedKeys.prayerTimesScheduleTitle.value,
                           unavailableMessage: AppLocalizedKeys.prayerTimesUnavailable.value,
                           nowTitle: AppLocalizedKeys.widgetNowTitle.value,
                           hourMinuteRemainingFormat: AppLocalizedKeys.widgetHourMinuteRemainingFormat.value,
                           minuteRemainingFormat: AppLocalizedKeys.widgetMinuteRemainingFormat.value,
                           nextPrayerGalleryTitle: AppLocalizedKeys.widgetNextPrayerGalleryTitle.value,
                           nextPrayerGalleryDescription: AppLocalizedKeys.widgetNextPrayerGalleryDescription.value,
                           scheduleGalleryTitle: AppLocalizedKeys.widgetScheduleGalleryTitle.value,
                           scheduleGalleryDescription: AppLocalizedKeys.widgetScheduleGalleryDescription.value,
                           dateGalleryTitle: AppLocalizedKeys.widgetDateGalleryTitle.value,
                           dateGalleryDescription: AppLocalizedKeys.widgetDateGalleryDescription.value)
    }

    func hijriText(for date: Date) -> String {
        let text = HijriCalendarDateTextFormatter.text(for: date,
                                                       identifier: .islamicUmmAlQura,
                                                       languageCode: languageCode,
                                                       format: AppLocalizedKeys.homeHijriFormat.value)
        return "\(text) \(AppLocalizedKeys.hijriEraSuffix.value)"
    }

    func gregorianText(for date: Date) -> String {
        HijriCalendarDateTextFormatter.text(for: date,
                                            identifier: .gregorian,
                                            languageCode: languageCode,
                                            format: AppLocalizedKeys.prayerTimesGregorianFormat.value)
    }
}
