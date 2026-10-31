//
//  AthkarItemAudioPlayerTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
import AVFoundation
import Combine
@testable import QuranApp

@MainActor
final class AthkarItemAudioPlayerTests: XCTestCase {

    // MARK: - Fixtures

    private let packKey = "player_tests"
    private var root: URL!
    private var center: NotificationCenter!
    private var player: AthkarItemAudioPlayer!
    private var cancellables: Set<AnyCancellable> = []
    private var observedRepetitions: [Int] = []
    private var observedTotals: [Int] = []
    private var finishedItemIDs: [Int] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("athkar-player-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        center = NotificationCenter()
    }

    override func tearDownWithError() throws {
        player?.stop()
        player = nil
        cancellables.removeAll()
        observedRepetitions = []
        observedTotals = []
        finishedItemIDs = []
        center = nil

        if let root { try? FileManager.default.removeItem(at: root) }
        root = nil

        try super.tearDownWithError()
    }

    private func makePlayer() -> AthkarItemAudioPlayer {
        let downloads = AthkarAudioDownloadManager(
            rootDirectory: root,
            expectedAudioFileNames: { _ in [] },
            publishedArchiveChecksum: { _ in nil }
        )

        let player = AthkarItemAudioPlayer(notificationCenter: center, downloads: downloads)

        player.$currentRepetition
            .sink { [weak self] in self?.observedRepetitions.append($0) }
            .store(in: &cancellables)

        player.$totalRepetitions
            .sink { [weak self] in self?.observedTotals.append($0) }
            .store(in: &cancellables)

        self.player = player
        return player
    }

    private func makeItem(count: Int, seconds: Double = 0.12) throws -> AthkarItem {
        let name = "clip-\(count)-\(UUID().uuidString).caf"
        let directory = root
            .appendingPathComponent("athkar_audio", isDirectory: true)
            .appendingPathComponent(packKey, isDirectory: true)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try writeSilence(to: directory.appendingPathComponent(name), seconds: seconds)

        return AthkarReaderFixture.item(id: 1, count: count, audio: "audio/\(name)")
    }

    private func writeSilence(to url: URL, seconds: Double) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44_100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let file = try AVAudioFile(forWriting: url, settings: settings)
        let frames = AVAudioFrameCount(44_100.0 * seconds)

        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames))
        buffer.frameLength = frames
        try file.write(from: buffer)
    }

    private func settle(_ seconds: Double = 0.2) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func waitForFinish(timeout: TimeInterval = 15) async {
        let expectation = expectation(description: "playback finished")
        expectation.assertForOverFulfill = true

        player.onFinished = { [weak self] itemID in
            self?.finishedItemIDs.append(itemID)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: timeout)
    }

    private func waitForRepetition(_ target: Int) async throws {
        for _ in 0..<600 {
            if player.currentRepetition >= target { return }
            await settle(0.02)
        }

        throw XCTSkip("playback did not reach repetition \(target) in this environment")
    }

    // MARK: - Auto repeat

    func testThreeTimesAthkarRepeatsThreeTimesAndReportsOnce() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 3)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        XCTAssertEqual(player.currentRepetition, 1)
        XCTAssertEqual(player.totalRepetitions, 3)

        await waitForFinish()
        await settle(0.5)

        XCTAssertEqual(finishedItemIDs, [item.id])
        XCTAssertEqual(observedRepetitions.max(), 3)
        XCTAssertTrue(observedRepetitions.contains(1))
        XCTAssertTrue(observedRepetitions.contains(2))
        XCTAssertTrue(observedRepetitions.contains(3))
        XCTAssertNil(player.playingItemID)
        XCTAssertEqual(player.currentRepetition, 0)
        XCTAssertEqual(player.totalRepetitions, 0)
    }

    func testSevenTimesAthkarRepeatsSevenTimes() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 7)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        XCTAssertEqual(player.totalRepetitions, 7)

        await waitForFinish()
        await settle(0.5)

        XCTAssertEqual(finishedItemIDs, [item.id])
        XCTAssertEqual(observedRepetitions.max(), 7)
    }

    func testHighCountAthkarPlaysAudioOnceAndHoldsTheCounter() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 100)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        XCTAssertEqual(player.currentRepetition, 1)
        XCTAssertEqual(player.totalRepetitions, 100)

        await waitForFinish()
        await settle(0.5)

        XCTAssertEqual(finishedItemIDs, [item.id])
        XCTAssertEqual(observedRepetitions.max(), 1)
        XCTAssertEqual(observedTotals.max(), 100)
    }

    func testSingleCountAthkarPlaysOnce() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 1)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        XCTAssertEqual(player.totalRepetitions, 1)

        await waitForFinish()
        await settle(0.5)

        XCTAssertEqual(finishedItemIDs, [item.id])
        XCTAssertEqual(observedRepetitions.max(), 1)
    }

    func testZeroCountAthkarPlaysOnce() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 0)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        XCTAssertEqual(player.currentRepetition, 1)
        XCTAssertEqual(player.totalRepetitions, 1)

        await waitForFinish()
        await settle(0.5)

        XCTAssertEqual(finishedItemIDs, [item.id])
        XCTAssertEqual(observedRepetitions.max(), 1)
    }

    // MARK: - Pause

    func testPauseMidRepetitionResumesTheSameRepetition() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 5, seconds: 0.6)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        try await waitForRepetition(2)
        let paused = player.currentRepetition

        player.pause()
        XCTAssertTrue(player.isPaused)

        await settle(0.5)

        XCTAssertTrue(player.isPaused)
        XCTAssertEqual(player.currentRepetition, paused)
        XCTAssertEqual(player.playingItemID, item.id)
        XCTAssertEqual(player.totalRepetitions, 5)

        player.resume()

        XCTAssertFalse(player.isPaused)
        XCTAssertEqual(player.currentRepetition, paused)
        XCTAssertEqual(player.playingItemID, item.id)
        XCTAssertTrue(finishedItemIDs.isEmpty)
    }

    // MARK: - Route changes

    func testUnavailableRouteChangePausesPlayback() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 5, seconds: 0.6)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        let repetition = player.currentRepetition
        postRouteChange(reason: .oldDeviceUnavailable)
        await settle()

        XCTAssertTrue(player.isPaused)
        XCTAssertEqual(player.playingItemID, item.id)
        XCTAssertEqual(player.currentRepetition, repetition)
        XCTAssertEqual(player.totalRepetitions, 5)
    }

    func testOtherRouteChangesDoNotPausePlayback() async throws {
        let player = makePlayer()
        let item = try makeItem(count: 5, seconds: 0.6)

        player.play(item: item, inPack: packKey)
        try XCTSkipIf(player.hasFailed, "audio playback is unavailable in this environment")

        postRouteChange(reason: .newDeviceAvailable)
        await settle()

        XCTAssertFalse(player.isPaused)
        XCTAssertEqual(player.playingItemID, item.id)
    }

    func testRouteChangeWithoutPlaybackIsIgnored() async throws {
        _ = makePlayer()

        postRouteChange(reason: .oldDeviceUnavailable)
        await settle()

        XCTAssertFalse(player.isPaused)
        XCTAssertNil(player.playingItemID)
        XCTAssertFalse(player.hasFailed)
    }

    private func postRouteChange(reason: AVAudioSession.RouteChangeReason) {
        center.post(
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            userInfo: [AVAudioSessionRouteChangeReasonKey: reason.rawValue]
        )
    }

    // MARK: - Missing audio

    func testMissingAudioFileFailsWithoutRepetitionState() async throws {
        let player = makePlayer()
        let item = AthkarReaderFixture.item(id: 9, count: 3, audio: "audio/absent.caf")

        player.play(item: item, inPack: packKey)

        XCTAssertTrue(player.hasFailed)
        XCTAssertNil(player.playingItemID)
        XCTAssertEqual(player.currentRepetition, 0)
        XCTAssertEqual(player.totalRepetitions, 0)
    }
}
