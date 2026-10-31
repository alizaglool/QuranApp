//
//  AthkarReaderTestDoubles.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import Foundation
import Combine
@testable import QuranApp

// MARK: - Fixtures

enum AthkarReaderFixture {

    static func item(id: Int, count: Int = 1, audio: String = "") -> AthkarItem {
        let payload: [String: Any] = [
            "id": id,
            "count": count,
            "title": "ذكر \(id)",
            "titleEn": "Dhikr \(id)",
            "audio": audio,
            "segments": [["kind": "text", "text": "نص الذكر \(id)"]]
        ]

        let data = try! JSONSerialization.data(withJSONObject: payload)
        return try! JSONDecoder().decode(AthkarItem.self, from: data)
    }

    static func items(ids: [Int], count: Int = 1) -> [AthkarItem] {
        ids.map { item(id: $0, count: count, audio: "\($0).m4a") }
    }

    static func pack(key: String = "reader_tests", itemCount: Int = 4) -> AthkarPack {
        let payload: [String: Any] = [
            "key": key,
            "group": "daily",
            "kind": "reader",
            "mood": "morning",
            "nameAr": "أذكار الاختبار",
            "nameEn": "Test Athkar",
            "itemCount": itemCount,
            "hasAudio": true
        ]

        let data = try! JSONSerialization.data(withJSONObject: payload)
        return try! JSONDecoder().decode(AthkarPack.self, from: data)
    }

    static func defaults(_ name: String = UUID().uuidString) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}

// MARK: - Audio player double

@MainActor
final class AthkarAudioPlayerDouble: AthkarAudioPlaying {

    var playingItemID: Int?
    var isPaused: Bool = false
    var currentRepetition: Int = 0
    var totalRepetitions: Int = 0
    var onFinished: (@MainActor (Int) -> Void)?

    var playableItemIDs: Set<Int>

    private(set) var playedItemIDs: [Int] = []
    private(set) var stopCount: Int = 0
    private var targetPlays: Int = 1

    private let stateSubject = PassthroughSubject<Void, Never>()
    private let failureSubject = PassthroughSubject<Void, Never>()

    init(playableItemIDs: Set<Int>) {
        self.playableItemIDs = playableItemIDs
    }

    var stateChanges: AnyPublisher<Void, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var failures: AnyPublisher<Void, Never> {
        failureSubject.eraseToAnyPublisher()
    }

    var hasCompletionHandler: Bool { onFinished != nil }

    func isPlaying(itemID: Int) -> Bool {
        playingItemID == itemID && !isPaused
    }

    func isActive(itemID: Int) -> Bool {
        playingItemID == itemID
    }

    func canPlay(item: AthkarItem, inPack packKey: String) -> Bool {
        playableItemIDs.contains(item.id)
    }

    func toggle(item: AthkarItem, inPack packKey: String) {
        guard playingItemID == item.id else {
            play(item: item, inPack: packKey)
            return
        }

        isPaused.toggle()
        stateSubject.send()
    }

    func play(item: AthkarItem, inPack packKey: String) {
        guard playableItemIDs.contains(item.id) else {
            playingItemID = nil
            isPaused = false
            resetRepetition()
            failureSubject.send()
            return
        }

        playedItemIDs.append(item.id)
        playingItemID = item.id
        isPaused = false
        targetPlays = AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: item.count)
        totalRepetitions = AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: item.count)
        currentRepetition = 1
        stateSubject.send()
    }

    func stop() {
        stopCount += 1
        playingItemID = nil
        isPaused = false
        resetRepetition()
        stateSubject.send()
    }

    func clearFailure() {}

    // MARK: - Simulation

    func finishCurrentItem() {
        guard let finished = playingItemID else { return }
        playingItemID = nil
        isPaused = false
        resetRepetition()
        stateSubject.send()
        onFinished?(finished)
    }

    func finishCurrentRepetition() {
        guard playingItemID != nil else { return }

        guard currentRepetition < targetPlays else {
            finishCurrentItem()
            return
        }

        currentRepetition += 1
        stateSubject.send()
    }

    func emitCompletion(forItemID itemID: Int) {
        onFinished?(itemID)
    }

    func reportFailure() {
        playingItemID = nil
        isPaused = false
        resetRepetition()
        stateSubject.send()
        failureSubject.send()
    }

    func interrupt() {
        guard playingItemID != nil else { return }
        isPaused = true
        stateSubject.send()
    }

    private func resetRepetition() {
        currentRepetition = 0
        totalRepetitions = 0
        targetPlays = 1
    }
}

// MARK: - Coordinator double

final class AdhkarCoordinatorDouble: AdhkarCoordinating {

    private(set) var didCoordinateBack: Bool = false

    func coordinateToAdhkarReading(category: DhikrCategory) {}
    func coordinateToAthkarReader(pack: AthkarPack, items: [AthkarItem]) {}
    func coordinateToAllahNames(names: [AllahName]) {}
    func coordinateToAllahNameDetail(names: [AllahName], startIndex: Int) {}
    func coordinateToMyAdhkar() {}
    func coordinateToProhibitedTimes() {}

    func coordinateBack() {
        didCoordinateBack = true
    }
}
