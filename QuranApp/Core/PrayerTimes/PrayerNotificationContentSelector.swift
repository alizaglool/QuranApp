//
//  PrayerNotificationContentSelector.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation

struct PrayerNotificationContentRequest: Hashable {

    let slot: PrayerSlot
    let kind: PrayerNotificationKind
}

struct PrayerNotificationContentSelector {

    static let shared = PrayerNotificationContentSelector(seed: PrayerNotificationContentSeedStore().resolvedSeed())
    static let rotationCycleInDays = 90

    private let rotationCycle: [[PrayerNotificationContentRequest: PrayerNotificationContent]]

    init(seed: UInt64) {
        rotationCycle = PrayerNotificationContentSelector.rotationCycle(seed: seed)
    }

    func content(dayKey: String,
                 slot: PrayerSlot,
                 kind: PrayerNotificationKind) -> PrayerNotificationContent? {
        dailyAssignment(dayKey: dayKey)[PrayerNotificationContentRequest(slot: slot, kind: kind)]
    }

    func dailyAssignment(dayKey: String) -> [PrayerNotificationContentRequest: PrayerNotificationContent] {
        rotationCycle[PrayerNotificationContentSelector.dayInCycle(forDayKey: dayKey)]
    }

    static func pool(slot: PrayerSlot, kind: PrayerNotificationKind) -> [PrayerNotificationContent] {
        let kindMatched = PrayerNotificationContentCatalog.items.filter { $0.suits(kind: kind) }
        let slotMatched = kindMatched.filter { $0.suits(slot: slot) }

        guard !PrayerNotificationContentSelector.requiresSlotSpecificContent(slot: slot, kind: kind) else {
            return slotMatched
        }

        return slotMatched + kindMatched.filter { $0.isGeneral }
    }

    static func requiresSlotSpecificContent(slot: PrayerSlot, kind: PrayerNotificationKind) -> Bool {
        guard kind != .iqamah else { return false }

        return slot.requiresDedicatedContent
    }
}

// MARK: - Rotation Cycle

private extension PrayerNotificationContentSelector {

    static let orderedRequests: [PrayerNotificationContentRequest] = PrayerSlot.allCases.flatMap { slot in
        slot.scheduledKinds.map { PrayerNotificationContentRequest(slot: slot, kind: $0) }
    }

    static func rotationCycle(seed: UInt64) -> [[PrayerNotificationContentRequest: PrayerNotificationContent]] {
        var generator = PrayerNotificationContentRandomGenerator(seed: seed)
        var cycle: [[PrayerNotificationContentRequest: PrayerNotificationContent]] = []

        for day in 0 ..< PrayerNotificationContentSelector.rotationCycleInDays {
            let isClosingDay = day == PrayerNotificationContentSelector.rotationCycleInDays - 1
            let assignment = PrayerNotificationContentSelector.assignment(precedingDay: cycle.last ?? [:],
                                                                          followingDay: isClosingDay ? cycle.first ?? [:] : [:],
                                                                          generator: &generator)

            cycle.append(assignment)
        }

        return cycle
    }

    static func assignment(precedingDay: [PrayerNotificationContentRequest: PrayerNotificationContent],
                           followingDay: [PrayerNotificationContentRequest: PrayerNotificationContent],
                           generator: inout PrayerNotificationContentRandomGenerator)
    -> [PrayerNotificationContentRequest: PrayerNotificationContent] {
        var restedCandidates: [PrayerNotificationContentRequest: [PrayerNotificationContent]] = [:]
        var completeCandidates: [PrayerNotificationContentRequest: [PrayerNotificationContent]] = [:]

        for request in PrayerNotificationContentSelector.orderedRequests {
            let pool = PrayerNotificationContentSelector.pool(slot: request.slot, kind: request.kind)
                .shuffled(using: &generator)
            let neighbouringIdentifiers = Set([precedingDay[request]?.id, followingDay[request]?.id].compactMap { $0 })

            completeCandidates[request] = pool
            restedCandidates[request] = pool.filter { !neighbouringIdentifiers.contains($0.id) }
        }

        var matcher = PrayerNotificationDailyContentMatcher(restedCandidates: restedCandidates,
                                                            completeCandidates: completeCandidates)

        return matcher.matchedContent(for: PrayerNotificationContentSelector.orderedRequests)
    }

    static func dayInCycle(forDayKey dayKey: String) -> Int {
        let dayIndex = PrayerNotificationContentSelector.dayIndex(forDayKey: dayKey)
        let cycleLength = PrayerNotificationContentSelector.rotationCycleInDays
        let remainder = dayIndex % cycleLength

        return remainder < 0 ? remainder + cycleLength : remainder
    }

    static func dayIndex(forDayKey dayKey: String) -> Int {
        let components = dayKey.split(separator: "-").compactMap { Int($0) }

        guard components.count == 3 else { return 0 }

        let year = components[0]
        let month = components[1]
        let day = components[2]
        let monthShift = (14 - month) / 12
        let shiftedYear = year + 4800 - monthShift
        let shiftedMonth = month + 12 * monthShift - 3

        return day + (153 * shiftedMonth + 2) / 5 + 365 * shiftedYear
            + shiftedYear / 4 - shiftedYear / 100 + shiftedYear / 400 - 32045
    }
}

// MARK: - Seed

struct PrayerNotificationDailyContentMatcher {

    private var candidates: [PrayerNotificationContentRequest: [PrayerNotificationContent]]
    private let completeCandidates: [PrayerNotificationContentRequest: [PrayerNotificationContent]]
    private var requestsByContentIdentifier: [String: PrayerNotificationContentRequest] = [:]
    private var selections: [PrayerNotificationContentRequest: PrayerNotificationContent] = [:]

    init(restedCandidates: [PrayerNotificationContentRequest: [PrayerNotificationContent]],
         completeCandidates: [PrayerNotificationContentRequest: [PrayerNotificationContent]]) {

        candidates = restedCandidates
        self.completeCandidates = completeCandidates
    }

    mutating func matchedContent(for requests: [PrayerNotificationContentRequest])
    -> [PrayerNotificationContentRequest: PrayerNotificationContent] {

        for request in requests {
            var visitedIdentifiers: Set<String> = []
            _ = assignContent(to: request, visitedIdentifiers: &visitedIdentifiers)
        }

        for request in requests where selections[request] == nil {
            var visitedIdentifiers: Set<String> = []

            candidates[request] = completeCandidates[request]
            _ = assignContent(to: request, visitedIdentifiers: &visitedIdentifiers)
        }

        return selections
    }

    private mutating func assignContent(to request: PrayerNotificationContentRequest,
                                        visitedIdentifiers: inout Set<String>) -> Bool {

        for content in candidates[request] ?? [] {
            guard !visitedIdentifiers.contains(content.id) else { continue }

            visitedIdentifiers.insert(content.id)

            if let holder = requestsByContentIdentifier[content.id],
               !assignContent(to: holder, visitedIdentifiers: &visitedIdentifiers) {
                continue
            }

            requestsByContentIdentifier[content.id] = request
            selections[request] = content

            return true
        }

        return false
    }
}

struct PrayerNotificationContentSeedStore {

    private static let storageKey = "prayer_notification_content_seed_v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func resolvedSeed() -> UInt64 {
        if let stored = defaults.object(forKey: PrayerNotificationContentSeedStore.storageKey) as? Int {
            return UInt64(bitPattern: Int64(stored))
        }

        let generated = Int.random(in: 1 ... Int.max)
        defaults.set(generated, forKey: PrayerNotificationContentSeedStore.storageKey)

        return UInt64(bitPattern: Int64(generated))
    }
}

struct PrayerNotificationContentRandomGenerator: RandomNumberGenerator {

    private static let fallbackSeed: UInt64 = 0x2545F4914F6CDD1D
    private static let goldenGap: UInt64 = 0x9E3779B97F4A7C15

    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? PrayerNotificationContentRandomGenerator.fallbackSeed : seed
    }

    mutating func next() -> UInt64 {
        state = state &+ PrayerNotificationContentRandomGenerator.goldenGap
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58476D1CE4E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D049BB133111EB

        return mixed ^ (mixed >> 31)
    }
}
