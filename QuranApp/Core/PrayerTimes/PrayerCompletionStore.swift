//
//  PrayerCompletionStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 14/10/2026.
//

import Foundation

struct PrayerCompletionRecord: Codable, Equatable {
    let dayKey: String
    var prayed: Set<Int>
}

struct PrayerCompletionHistory: Codable, Equatable {
    var days: [String: Set<Int>]
}

final class PrayerCompletionStore {

    static let shared = PrayerCompletionStore()

    private let defaultsKey = "home.prayerCompletion"
    private let historyLimit = 400
    private let defaults: UserDefaults
    private var cachedHistory: PrayerCompletionHistory?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
}

// MARK: - Reads

extension PrayerCompletionStore {

    func prayed(on dayKey: String) -> Set<Int> {
        history().days[dayKey] ?? []
    }

    func isPrayed(index: Int, on dayKey: String) -> Bool {
        prayed(on: dayKey).contains(index)
    }

    func count(on dayKey: String) -> Int {
        prayed(on: dayKey).count
    }
}

// MARK: - Writes

extension PrayerCompletionStore {

    @discardableResult
    func toggle(index: Int, on dayKey: String) -> Set<Int> {
        var record = history()
        var current = record.days[dayKey] ?? []
        if current.contains(index) {
            current.remove(index)
        } else {
            current.insert(index)
        }
        record.days[dayKey] = current
        write(record)
        return current
    }

    func clear() {
        cachedHistory = nil
        defaults.removeObject(forKey: defaultsKey)
    }
}

// MARK: - Storage

private extension PrayerCompletionStore {

    func history() -> PrayerCompletionHistory {
        if let cachedHistory { return cachedHistory }

        let decoded = decodeHistory() ?? migratedSingleDayHistory() ?? PrayerCompletionHistory(days: [:])
        cachedHistory = decoded
        return decoded
    }

    func decodeHistory() -> PrayerCompletionHistory? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(PrayerCompletionHistory.self, from: data)
    }

    func migratedSingleDayHistory() -> PrayerCompletionHistory? {
        guard let data = defaults.data(forKey: defaultsKey),
              let legacy = try? JSONDecoder().decode(PrayerCompletionRecord.self, from: data) else {
            return nil
        }
        return PrayerCompletionHistory(days: [legacy.dayKey: legacy.prayed])
    }

    func write(_ record: PrayerCompletionHistory) {
        var trimmed = record
        if trimmed.days.count > historyLimit {
            let retained = Set(trimmed.days.keys.sorted().suffix(historyLimit))
            trimmed.days = trimmed.days.filter { retained.contains($0.key) }
        }
        cachedHistory = trimmed
        guard let data = try? JSONEncoder().encode(trimmed) else { return }
        defaults.set(data, forKey: defaultsKey)
    }
}
