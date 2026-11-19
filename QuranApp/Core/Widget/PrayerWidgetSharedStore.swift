//
//  PrayerWidgetSharedStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

enum PrayerWidgetSharedStore {

    static let appGroupIdentifier = "group.com.Quran.wirdd"
    static let snapshotKey = "prayer_widget_snapshot_v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static func loadSnapshot(from defaults: UserDefaults = PrayerWidgetSharedStore.defaults) -> PrayerWidgetSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey),
              let decoded = try? JSONDecoder().decode(PrayerWidgetSnapshot.self, from: data)
        else { return nil }
        return decoded
    }

    static func save(_ snapshot: PrayerWidgetSnapshot,
                     to defaults: UserDefaults = PrayerWidgetSharedStore.defaults) {
        guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(encoded, forKey: snapshotKey)
    }

    static func clear(in defaults: UserDefaults = PrayerWidgetSharedStore.defaults) {
        defaults.removeObject(forKey: snapshotKey)
    }
}
