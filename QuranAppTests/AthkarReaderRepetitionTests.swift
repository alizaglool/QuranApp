//
//  AthkarReaderRepetitionTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class AthkarReaderRepetitionTests: XCTestCase {

    // MARK: - Builders

    private func makeViewModel(
        ids: [Int] = [1, 2, 3],
        count: Int = 3
    ) -> (AthkarReaderViewModel, AthkarAudioPlayerDouble) {
        let items = AthkarReaderFixture.items(ids: ids, count: count)
        let audio = AthkarAudioPlayerDouble(playableItemIDs: Set(ids))

        let viewModel = AthkarReaderViewModel(
            coordinator: AdhkarCoordinatorDouble(),
            pack: AthkarReaderFixture.pack(itemCount: items.count),
            items: items,
            settings: AthkarReaderSettings(defaults: AthkarReaderFixture.defaults()),
            completion: AthkarCompletionStore(defaults: AthkarReaderFixture.defaults()),
            audio: audio
        )

        viewModel.onAppear()
        return (viewModel, audio)
    }

    private func settle() async {
        try? await Task.sleep(nanoseconds: 120_000_000)
    }

    // MARK: - Advance timing

    func testReaderAdvancesOnlyAfterTheFinalRepetition() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        await settle()

        XCTAssertEqual(viewModel.playbackRepetition, 1)
        XCTAssertEqual(viewModel.playbackRepetitionTotal, 3)

        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertEqual(viewModel.playbackRepetition, 2)

        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertEqual(viewModel.playbackRepetition, 3)

        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1, 2])
        XCTAssertEqual(viewModel.index, 1)
        XCTAssertEqual(viewModel.playbackRepetition, 1)
    }

    func testSevenTimesAthkarNeedsSevenRepetitionsBeforeAdvancing() async {
        let (viewModel, audio) = makeViewModel(count: 7)

        viewModel.toggleAudio()

        for _ in 1...6 {
            audio.finishCurrentRepetition()
        }
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.playbackRepetition, 7)
        XCTAssertEqual(viewModel.playbackRepetitionTotal, 7)

        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1, 2])
    }

    func testSingleCountAthkarAdvancesOnTheFirstCompletion() async {
        let (viewModel, audio) = makeViewModel(count: 1)

        viewModel.toggleAudio()
        await settle()

        XCTAssertEqual(viewModel.playbackRepetitionTotal, 1)

        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1, 2])
        XCTAssertEqual(viewModel.index, 1)
    }

    func testHighCountAthkarAdvancesAfterASinglePlay() async {
        let (viewModel, audio) = makeViewModel(count: 100)

        viewModel.toggleAudio()
        await settle()

        XCTAssertEqual(viewModel.playbackRepetition, 1)
        XCTAssertEqual(viewModel.playbackRepetitionTotal, 100)

        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1, 2])
    }

    // MARK: - Layout

    func testSwitchingLayoutMidPlaybackKeepsTheRepetitionState() async {
        let (viewModel, audio) = makeViewModel(count: 7)

        viewModel.toggleAudio()
        audio.finishCurrentRepetition()
        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(viewModel.layout, .horizontal)
        XCTAssertEqual(viewModel.playbackRepetition, 3)

        viewModel.setLayout(.vertical)
        await settle()

        XCTAssertEqual(viewModel.layout, .vertical)
        XCTAssertEqual(audio.playingItemID, 1)
        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.playbackRepetition, 3)
        XCTAssertEqual(viewModel.playbackRepetitionTotal, 7)
    }

    // MARK: - Pause

    func testPausingMidRepetitionKeepsTheSameRepetition() async {
        let (viewModel, audio) = makeViewModel(count: 4)

        viewModel.toggleAudio()
        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(viewModel.playbackRepetition, 2)

        viewModel.toggleAudio()
        await settle()

        XCTAssertTrue(audio.isPaused)
        XCTAssertEqual(viewModel.playbackRepetition, 2)

        viewModel.toggleAudio()
        await settle()

        XCTAssertFalse(audio.isPaused)
        XCTAssertEqual(viewModel.playbackRepetition, 2)
        XCTAssertEqual(audio.playedItemIDs, [1])
    }

    // MARK: - Progress label

    func testRepetitionLabelDescribesOnlyThePlayingAthkar() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        await settle()

        XCTAssertEqual(viewModel.repetitionLabel(forItemID: 1), "1 / 3")
        XCTAssertEqual(viewModel.repetitionLabel(forItemID: 2), "")
        XCTAssertFalse(viewModel.repetitionAccessibilityLabel(forItemID: 1).isEmpty)

        audio.finishCurrentRepetition()
        await settle()

        XCTAssertEqual(viewModel.repetitionLabel(forItemID: 1), "2 / 3")
    }

    func testRepetitionLabelIsHiddenForSingleCountAthkar() async {
        let (viewModel, _) = makeViewModel(count: 1)

        viewModel.toggleAudio()
        await settle()

        XCTAssertEqual(viewModel.repetitionLabel(forItemID: 1), "")
        XCTAssertEqual(viewModel.repetitionAccessibilityLabel(forItemID: 1), "")
    }

    func testRepetitionLabelClearsWhenPlaybackStops() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        await settle()
        audio.stop()
        await settle()

        XCTAssertEqual(viewModel.playbackRepetition, 0)
        XCTAssertEqual(viewModel.playbackRepetitionTotal, 0)
        XCTAssertEqual(viewModel.repetitionLabel(forItemID: 1), "")
    }
}
