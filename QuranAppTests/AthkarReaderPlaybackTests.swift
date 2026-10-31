//
//  AthkarReaderPlaybackTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class AthkarReaderPlaybackTests: XCTestCase {

    // MARK: - Builders

    private func makeViewModel(
        ids: [Int] = [1, 2, 3, 4],
        playable: Set<Int>? = nil
    ) -> (AthkarReaderViewModel, AthkarAudioPlayerDouble) {
        let items = AthkarReaderFixture.items(ids: ids, count: 3)
        let audio = AthkarAudioPlayerDouble(playableItemIDs: playable ?? Set(ids))

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

    // MARK: - Sequential advance

    func testPlaybackAdvancesThroughTheCategoryInOrder() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.finishCurrentItem()
        audio.finishCurrentItem()
        audio.finishCurrentItem()

        XCTAssertEqual(audio.playedItemIDs, [1, 2, 3, 4])
    }

    func testOneCompletionAdvancesExactlyOneAthkar() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.finishCurrentItem()

        XCTAssertEqual(audio.playedItemIDs, [1, 2])
        XCTAssertEqual(viewModel.index, 1)
    }

    func testDuplicateCompletionCallbackDoesNotAdvanceTwice() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.finishCurrentItem()
        audio.emitCompletion(forItemID: 1)
        audio.emitCompletion(forItemID: 1)

        XCTAssertEqual(audio.playedItemIDs, [1, 2])
        XCTAssertEqual(viewModel.index, 1)
    }

    func testCompletionForAnAthkarThatIsNotPlayingIsIgnored() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.emitCompletion(forItemID: 3)

        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.index, 0)
    }

    func testPlaybackKeepsTheReaderPositionAndScrollTargetInSync() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.finishCurrentItem()

        XCTAssertEqual(viewModel.index, 1)
        XCTAssertEqual(viewModel.scrollTarget, 2)

        await settle()

        XCTAssertEqual(viewModel.playingIndex, 1)
        XCTAssertTrue(viewModel.isPlaying)
    }

    // MARK: - End of category

    func testPlaybackStopsCleanlyAtTheEndOfTheCategory() async {
        let (viewModel, audio) = makeViewModel(ids: [1, 2, 3])

        viewModel.toggleAudio()
        audio.finishCurrentItem()
        audio.finishCurrentItem()
        audio.finishCurrentItem()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1, 2, 3])
        XCTAssertNil(audio.playingItemID)
        XCTAssertNil(viewModel.playingItemID)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertFalse(viewModel.isFinished)
    }

    // MARK: - Missing audio

    func testPlaybackSkipsAthkarWithoutInstalledAudio() {
        let (viewModel, audio) = makeViewModel(playable: [1, 4])

        viewModel.toggleAudio()
        audio.finishCurrentItem()

        XCTAssertEqual(audio.playedItemIDs, [1, 4])
        XCTAssertEqual(viewModel.index, 3)
        XCTAssertEqual(viewModel.scrollTarget, 4)
        XCTAssertEqual(viewModel.toast, viewModel.audioSkippedMessage)
    }

    func testSkipNoticeIsShownOnlyOncePerPlaybackRun() async {
        let (viewModel, audio) = makeViewModel(ids: [1, 2, 3, 4, 5, 6], playable: [1, 3, 5])

        viewModel.toggleAudio()
        audio.finishCurrentItem()

        XCTAssertEqual(viewModel.toast, viewModel.audioSkippedMessage)

        try? await Task.sleep(nanoseconds: 1_800_000_000)
        XCTAssertEqual(viewModel.toast, "")

        audio.finishCurrentItem()

        XCTAssertEqual(audio.playedItemIDs, [1, 3, 5])
        XCTAssertEqual(viewModel.toast, "")
    }

    func testPlaybackStopsWhenNoLaterAthkarHasAudio() async {
        let (viewModel, audio) = makeViewModel(ids: [1, 2, 3], playable: [1])

        viewModel.toggleAudio()
        audio.finishCurrentItem()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.toast, "")
    }

    func testPlayingAnAthkarWithoutAudioReportsFailureAndDoesNotAdvance() async {
        let (viewModel, audio) = makeViewModel(playable: [2, 3, 4])

        viewModel.toggleAudio()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [])
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.toast, viewModel.audioFailureMessage)
    }

    func testPlaybackFailureDoesNotAdvanceToTheNextAthkar() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.reportFailure()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.toast, viewModel.audioFailureMessage)
    }

    // MARK: - Manual control

    func testManualSelectionStartsAndContinuesFromThatAthkar() {
        let (viewModel, audio) = makeViewModel()

        viewModel.navigate(to: 2)
        viewModel.toggleAudio()
        audio.finishCurrentItem()

        XCTAssertEqual(audio.playedItemIDs, [3, 4])
        XCTAssertEqual(viewModel.index, 3)
    }

    func testUserNavigationStopsPlayback() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        viewModel.navigate(to: 2)
        await settle()

        XCTAssertEqual(audio.stopCount, 1)
        XCTAssertNil(audio.playingItemID)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(audio.playedItemIDs, [1])
    }

    func testPauseDoesNotAdvancePlayback() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        viewModel.toggleAudio()
        await settle()

        XCTAssertTrue(audio.isPaused)
        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.playingItemID, 1)
    }

    func testResumeAfterPauseContinuesTheSameAthkar() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        viewModel.toggleAudio()
        viewModel.toggleAudio()
        await settle()

        XCTAssertFalse(audio.isPaused)
        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertTrue(viewModel.isPlaying)
    }

    func testInterruptionPausesWithoutAdvancing() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.interrupt()
        await settle()

        XCTAssertEqual(audio.playedItemIDs, [1])
        XCTAssertEqual(viewModel.index, 0)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertEqual(viewModel.playingItemID, 1)
    }

    func testPausedPlaybackStillAdvancesAfterTheUserResumesAndTheItemFinishes() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        viewModel.toggleAudio()
        viewModel.toggleAudio()
        audio.finishCurrentItem()

        XCTAssertEqual(audio.playedItemIDs, [1, 2])
    }

    func testRestartStopsPlaybackAndReturnsToTheFirstAthkar() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.finishCurrentItem()
        viewModel.restart()
        await settle()

        XCTAssertEqual(viewModel.index, 0)
        XCTAssertEqual(viewModel.scrollTarget, 1)
        XCTAssertEqual(viewModel.tally, 0)
        XCTAssertNil(audio.playingItemID)
        XCTAssertFalse(viewModel.isPlaying)
    }

    // MARK: - Progress isolation

    func testContinuousPlaybackDoesNotChangeCounterProgress() {
        let (viewModel, audio) = makeViewModel(ids: [1, 2, 3])

        viewModel.toggleAudio()
        audio.finishCurrentItem()
        audio.finishCurrentItem()
        audio.finishCurrentItem()

        XCTAssertEqual(viewModel.tally, 0)
        XCTAssertEqual(viewModel.completedCount, 0)
        XCTAssertFalse(viewModel.isFinished)
    }

    // MARK: - Lifecycle

    func testDismissingTheReaderStopsPlaybackAndReleasesTheCompletionHandler() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        viewModel.onDisappear()

        XCTAssertFalse(audio.hasCompletionHandler)
        XCTAssertEqual(audio.stopCount, 1)
        XCTAssertNil(audio.playingItemID)
    }

    func testCompletionAfterDismissalDoesNotStartPlayback() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        viewModel.onDisappear()
        audio.emitCompletion(forItemID: 1)

        XCTAssertEqual(audio.playedItemIDs, [1])
    }

    // MARK: - Scroll focus

    func testScrollFocusIsIgnoredWhilePlaybackIsScrollingTheListItself() {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        audio.finishCurrentItem()
        viewModel.focus(onItemID: 4)

        XCTAssertEqual(viewModel.index, 1)
    }

    func testManualScrollChangesTheFocusedAthkarWithoutStoppingPlayback() async {
        let (viewModel, audio) = makeViewModel()

        viewModel.toggleAudio()
        try? await Task.sleep(nanoseconds: 700_000_000)
        viewModel.focus(onItemID: 3)

        XCTAssertEqual(viewModel.index, 2)
        XCTAssertEqual(audio.playingItemID, 1)
        XCTAssertEqual(audio.stopCount, 0)
    }
}
