//
//  PrayerWidgetTimelineProvider.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import WidgetKit

struct PrayerWidgetTimelineProvider: TimelineProvider {

    private static let retryInterval: TimeInterval = 30 * 60

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        PrayerWidgetEntry(date: Date(), snapshot: storedSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(PrayerWidgetEntry(date: Date(), snapshot: storedSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = storedSnapshot()

        guard snapshot.nextSlot(at: now) != nil else {
            let retryDate = now.addingTimeInterval(PrayerWidgetTimelineProvider.retryInterval)
            completion(Timeline(entries: [PrayerWidgetEntry(date: now, snapshot: snapshot)],
                                policy: .after(retryDate)))
            return
        }

        let entries = snapshot.timelineDates(from: now).map {
            PrayerWidgetEntry(date: $0, snapshot: snapshot)
        }
        let reloadDate = entries.last?.date ?? now.addingTimeInterval(PrayerWidgetTimelineProvider.retryInterval)
        completion(Timeline(entries: entries, policy: .after(reloadDate)))
    }

    private func storedSnapshot() -> PrayerWidgetSnapshot {
        PrayerWidgetSharedStore.loadSnapshot() ?? .placeholder
    }
}
