//
//  AthkarCompletionStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Combine
import Core

// MARK: - Progress

struct AthkarPackProgress: Codable, Hashable {
    var tallies: [String: Int]
    var completed: [Int]
    var finishedAt: Date?

    static let empty = AthkarPackProgress(tallies: [:], completed: [], finishedAt: nil)

    var completedCount: Int { completed.count }

    var isFinished: Bool { finishedAt != nil }
}

// MARK: - Day record

private struct AthkarDayRecord: Codable {
    var day: String
    var packs: [String: AthkarPackProgress]

    static func fresh(day: String) -> AthkarDayRecord {
        AthkarDayRecord(day: day, packs: [:])
    }
}

// MARK: - Store

final class AthkarCompletionStore: ObservableObject {

    static let shared = AthkarCompletionStore()

    private static let storageKey = "athkar_today_progress"
    private static let streakKey = "athkar_streak"

    @Published private(set) var packs: [String: AthkarPackProgress] = [:]
    @Published private(set) var streak: Int = 0

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let formatter: DateFormatter
    private var day: String = ""

    init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        self.formatter = formatter

        restore()
    }

    // MARK: - Queries

    func progress(forKey packKey: String) -> AthkarPackProgress {
        refreshDayIfNeeded()
        return packs[packKey] ?? .empty
    }

    func completedCount(forKey packKey: String) -> Int {
        progress(forKey: packKey).completedCount
    }

    func isCompleted(itemID: Int, inPack packKey: String) -> Bool {
        progress(forKey: packKey).completed.contains(itemID)
    }

    func tally(itemID: Int, inPack packKey: String) -> Int {
        progress(forKey: packKey).tallies[String(itemID)] ?? 0
    }

    func isFinished(_ pack: AthkarPack) -> Bool {
        let progress = progress(forKey: pack.key)
        guard pack.itemCount > 0 else { return progress.isFinished }
        return progress.isFinished || progress.completedCount >= pack.itemCount
    }

    func ratio(for pack: AthkarPack) -> Double {
        guard pack.itemCount > 0 else { return 0 }
        return min(1, Double(completedCount(forKey: pack.key)) / Double(pack.itemCount))
    }

    // MARK: - Mutation

    func setCompleted(_ isCompleted: Bool, itemID: Int, inPack packKey: String) {
        mutate(packKey) { progress in
            if isCompleted {
                guard !progress.completed.contains(itemID) else { return }
                progress.completed.append(itemID)
            } else {
                progress.completed.removeAll { $0 == itemID }
                progress.tallies.removeValue(forKey: String(itemID))
                progress.finishedAt = nil
            }
        }
    }

    func toggle(itemID: Int, inPack packKey: String) {
        setCompleted(!isCompleted(itemID: itemID, inPack: packKey), itemID: itemID, inPack: packKey)
    }

    @discardableResult
    func advance(item: AthkarItem, inPack packKey: String) -> Bool {
        let target = item.repeatCount
        var reachedTarget = false

        mutate(packKey) { progress in
            let identifier = String(item.id)
            let next = min(target, (progress.tallies[identifier] ?? 0) + 1)
            progress.tallies[identifier] = next

            if next >= target {
                reachedTarget = true
                if !progress.completed.contains(item.id) {
                    progress.completed.append(item.id)
                }
            }
        }

        return reachedTarget
    }

    func resetTally(itemID: Int, inPack packKey: String) {
        mutate(packKey) { progress in
            progress.tallies.removeValue(forKey: String(itemID))
            progress.completed.removeAll { $0 == itemID }
            progress.finishedAt = nil
        }
    }

    func markFinished(_ pack: AthkarPack, itemIDs: [Int]) {
        mutate(pack.key) { progress in
            progress.completed = Array(Set(progress.completed).union(itemIDs))
            progress.finishedAt = Date()
        }
        bumpStreak()
    }

    func reset(packKey: String) {
        refreshDayIfNeeded()
        guard packs.removeValue(forKey: packKey) != nil else { return }
        persist()
    }

    func resetAll() {
        refreshDayIfNeeded()
        guard !packs.isEmpty else { return }
        packs.removeAll()
        persist()
    }

    // MARK: - Streak

    private func bumpStreak() {
        let record = defaults.string(forKey: Self.streakKey) ?? ""
        let parts = record.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        let lastDay = parts.first.map(String.init) ?? ""
        let value = parts.count == 2 ? Int(parts[1]) ?? 0 : 0

        guard lastDay != day else { return }

        let yesterday = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        let next = lastDay == yesterday ? value + 1 : 1

        streak = next
        defaults.set("\(day)|\(next)", forKey: Self.streakKey)
    }

    private func restoreStreak() {
        let record = defaults.string(forKey: Self.streakKey) ?? ""
        let parts = record.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2, let value = Int(parts[1]) else {
            streak = 0
            return
        }

        let lastDay = String(parts[0])
        let yesterday = formatter.string(from: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        streak = (lastDay == day || lastDay == yesterday) ? value : 0
    }

    // MARK: - Storage

    private func mutate(_ packKey: String, _ change: (inout AthkarPackProgress) -> Void) {
        refreshDayIfNeeded()
        var progress = packs[packKey] ?? .empty
        change(&progress)
        packs[packKey] = progress
        persist()
    }

    private func refreshDayIfNeeded() {
        let today = formatter.string(from: Date())
        guard today != day else { return }
        day = today
        packs = [:]
        persist()
        restoreStreak()
    }

    private func restore() {
        day = formatter.string(from: Date())

        guard let data = defaults.data(forKey: Self.storageKey),
              let record = try? JSONDecoder().decode(AthkarDayRecord.self, from: data) else {
            packs = [:]
            restoreStreak()
            return
        }

        packs = record.day == day ? record.packs : [:]
        if record.day != day { persist() }
        restoreStreak()
    }

    private func persist() {
        let record = AthkarDayRecord(day: day, packs: packs)
        guard let data = try? JSONEncoder().encode(record) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
