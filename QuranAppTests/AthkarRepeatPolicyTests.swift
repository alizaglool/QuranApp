//
//  AthkarRepeatPolicyTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class AthkarRepeatPolicyTests: XCTestCase {

    private static let hundredCountAudioIdentifiers = ["morning_2", "morning_5", "morning_6", "evening_3", "evening_4"]

    private var root: URL!
    private var viewModel: AdhkarReadingViewModel!
    private var allAdhkar: [Dhikr] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("athkar-repeat-policy-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let url = try XCTUnwrap(Bundle.main.url(forResource: "adhkar", withExtension: "json"))
        let decoded = try JSONDecoder().decode([DhikrCategory].self, from: try Data(contentsOf: url))
        allAdhkar = decoded.flatMap(\.adhkar)
        XCTAssertFalse(allAdhkar.isEmpty)

        let downloads = AthkarAudioDownloadManager(rootDirectory: root,
                                                   expectedAudioFileNames: { _ in [] },
                                                   publishedArchiveChecksum: { _ in nil })
        viewModel = AdhkarReadingViewModel(coordinator: AdhkarCoordinatorDouble(),
                                           category: DhikrCategory(id: "repeat_policy_fixture",
                                                                   titleAr: "فئة",
                                                                   titleEn: "Category",
                                                                   icon: "star",
                                                                   adhkar: allAdhkar,
                                                                   condition: nil,
                                                                   section: "more"),
                                           downloads: downloads)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        allAdhkar = []
        if let root, FileManager.default.fileExists(atPath: root.path) {
            try FileManager.default.removeItem(at: root)
        }
        root = nil
        try super.tearDownWithError()
    }

    private func dhikr(id: String) throws -> Dhikr {
        try XCTUnwrap(allAdhkar.first { $0.id == id }, "missing legacy dhikr \(id)")
    }
}

// MARK: - Affected Items

extension AthkarRepeatPolicyTests {

    func testHundredCountAudioItemsStillCarryTheirOriginalCount() throws {
        for id in Self.hundredCountAudioIdentifiers {
            let item = try dhikr(id: id)
            XCTAssertEqual(item.count, 100, "\(id) no longer carries its original repetition count")
            XCTAssertNotNil(item.audio, "\(id) no longer declares audio")
        }
    }

    func testHundredCountAudioItemsPlayOnce() throws {
        for id in Self.hundredCountAudioIdentifiers {
            XCTAssertEqual(viewModel.audioRepeats(for: try dhikr(id: id)), 1,
                           "\(id) would loop its audio beyond the auto-repeat limit")
        }
    }

    func testHundredCountAudioItemsHoldTheFullManualCounter() throws {
        for id in Self.hundredCountAudioIdentifiers {
            let item = try dhikr(id: id)
            XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: item.count), 100,
                           "\(id) lost its manual counting target")
        }
    }

    func testTheOnlyLegacyAudioItemsAboveTheLimitAreTheKnownFive() {
        let above = allAdhkar
            .filter { $0.audio != nil && $0.count > AthkarItemAudioPlayer.autoRepeatCountLimit }
            .map(\.id)
            .sorted()

        XCTAssertEqual(above, Self.hundredCountAudioIdentifiers.sorted())
    }
}

// MARK: - Catalogue Sweep

extension AthkarRepeatPolicyTests {

    func testEveryLegacyAudioItemFollowsThePolicy() {
        let limit = AthkarItemAudioPlayer.autoRepeatCountLimit

        for item in allAdhkar where item.audio != nil {
            let repeats = viewModel.audioRepeats(for: item)

            if item.count > limit {
                XCTAssertEqual(repeats, 1, "\(item.id) repeats audio above the limit")
            } else {
                XCTAssertEqual(repeats, max(1, item.count), "\(item.id) does not repeat its configured count")
            }
        }
    }

    func testNoLegacyAudioItemEverRepeatsAboveTheLimit() {
        for item in allAdhkar where item.audio != nil {
            XCTAssertLessThanOrEqual(viewModel.audioRepeats(for: item),
                                     AthkarItemAudioPlayer.autoRepeatCountLimit,
                                     "\(item.id) exceeds the auto-repeat limit")
        }
    }

    func testEveryLegacyItemRepeatsAtLeastOnce() {
        for item in allAdhkar {
            XCTAssertGreaterThanOrEqual(viewModel.audioRepeats(for: item), 1, "\(item.id) would never play")
        }
    }
}

// MARK: - Policy Function

extension AthkarRepeatPolicyTests {

    func testAudioPlayCountBoundaries() {
        XCTAssertEqual(AthkarItemAudioPlayer.autoRepeatCountLimit, 10)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 0), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 1), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 3), 3)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 7), 7)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 10), 10)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 11), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 33), 1)
        XCTAssertEqual(AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: 100), 1)
    }

    func testHeldRepetitionCountNeverShrinksTheConfiguredCount() {
        for count in [0, 1, 3, 7, 10, 33, 100] {
            XCTAssertEqual(AthkarItemAudioPlayer.heldRepetitionCount(forRepeatCount: count), max(1, count))
        }
    }

    func testBothPlaybackPathsAgreeOnEveryCount() {
        for count in 0...200 {
            let item = Dhikr(id: "sweep_\(count)",
                             textAr: "نص",
                             description: nil,
                             title: nil,
                             count: count,
                             audio: "clip.m4a",
                             segments: nil,
                             repeatLabel: nil)

            XCTAssertEqual(viewModel.audioRepeats(for: item),
                           AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: count),
                           "the legacy reader and the pack player disagree at count \(count)")
        }
    }
}
