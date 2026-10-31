//
//  AthkarReaderLayoutTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class AthkarReaderLayoutTests: XCTestCase {

    // MARK: - Default

    func testLayoutDefaultsToHorizontalPaging() {
        let settings = AthkarReaderSettings(defaults: AthkarReaderFixture.defaults())

        XCTAssertEqual(settings.layout, .horizontal)
    }

    func testUnknownStoredLayoutFallsBackToHorizontalPaging() {
        let defaults = AthkarReaderFixture.defaults()
        defaults.set("carousel", forKey: "athkar.reader.layoutMode")

        let settings = AthkarReaderSettings(defaults: defaults)

        XCTAssertEqual(settings.layout, .horizontal)
    }

    // MARK: - Persistence

    func testSelectedLayoutSurvivesRelaunch() {
        let defaults = AthkarReaderFixture.defaults()

        let first = AthkarReaderSettings(defaults: defaults)
        first.setLayout(.vertical)

        let relaunched = AthkarReaderSettings(defaults: defaults)

        XCTAssertEqual(relaunched.layout, .vertical)
    }

    func testPersistedLayoutIsPreferredOverTheDefault() {
        let defaults = AthkarReaderFixture.defaults()
        AthkarReaderSettings(defaults: defaults).setLayout(.vertical)

        let relaunched = AthkarReaderSettings(defaults: defaults)
        relaunched.setLayout(.horizontal)

        XCTAssertEqual(AthkarReaderSettings(defaults: defaults).layout, .horizontal)
    }

    func testRepeatingTheSameLayoutSelectionIsIgnored() {
        let defaults = AthkarReaderFixture.defaults()
        let settings = AthkarReaderSettings(defaults: defaults)

        settings.setLayout(.horizontal)

        XCTAssertNil(defaults.string(forKey: "athkar.reader.layoutMode"))
        XCTAssertEqual(settings.layout, .horizontal)
    }

    // MARK: - Progress

    func testSwitchingLayoutKeepsCounterProgressAndPosition() {
        let items = AthkarReaderFixture.items(ids: [1, 2, 3], count: 3)
        let pack = AthkarReaderFixture.pack(itemCount: items.count)
        let settings = AthkarReaderSettings(defaults: AthkarReaderFixture.defaults())
        let completion = AthkarCompletionStore(defaults: AthkarReaderFixture.defaults())

        let viewModel = AthkarReaderViewModel(
            coordinator: AdhkarCoordinatorDouble(),
            pack: pack,
            items: items,
            settings: settings,
            completion: completion,
            audio: AthkarAudioPlayerDouble(playableItemIDs: [])
        )

        viewModel.onAppear()
        viewModel.count()
        viewModel.count()

        let tallyBefore = viewModel.tally
        let indexBefore = viewModel.index

        viewModel.setLayout(.vertical)

        XCTAssertEqual(viewModel.layout, .vertical)
        XCTAssertEqual(viewModel.tally, tallyBefore)
        XCTAssertEqual(viewModel.tally, 2)
        XCTAssertEqual(viewModel.index, indexBefore)
        XCTAssertEqual(viewModel.completedCount, 0)
        XCTAssertFalse(viewModel.isFinished)
    }

    func testSwitchingLayoutDoesNotInterruptPlayback() async {
        let items = AthkarReaderFixture.items(ids: [1, 2, 3])
        let audio = AthkarAudioPlayerDouble(playableItemIDs: [1, 2, 3])

        let viewModel = AthkarReaderViewModel(
            coordinator: AdhkarCoordinatorDouble(),
            pack: AthkarReaderFixture.pack(itemCount: items.count),
            items: items,
            settings: AthkarReaderSettings(defaults: AthkarReaderFixture.defaults()),
            completion: AthkarCompletionStore(defaults: AthkarReaderFixture.defaults()),
            audio: audio
        )

        viewModel.onAppear()
        viewModel.toggleAudio()

        viewModel.setLayout(.vertical)
        await Task.yield()

        XCTAssertEqual(audio.playingItemID, 1)
        XCTAssertEqual(audio.stopCount, 0)
        XCTAssertEqual(audio.playedItemIDs, [1])
    }
}
