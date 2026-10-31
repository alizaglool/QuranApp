//
//  QuranFullDownloadStatusTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
@testable import QuranApp

final class QuranFullDownloadStatusTests: XCTestCase {

    // MARK: - Availability

    func testEmptyCatalogIsNotReportedAsDownloaded() {
        let status = QuranFullDownloadStatus.resolve(packs: [],
                                                     currentKeys: [],
                                                     states: [:],
                                                     waitingKeys: [])

        XCTAssertFalse(status.isComplete)
        XCTAssertFalse(status.isAvailable)
        XCTAssertEqual(status.stage, .notDownloaded)
        XCTAssertEqual(status.totalBytes, 0)
        XCTAssertEqual(status.fraction, 0)
    }

    func testIdleCatalogReportsEveryPackAsRemaining() {
        let status = QuranFullDownloadStatus.resolve(packs: QuranImagePackFixture.packs(juzNumbers: [2, 3, 4],
                                                                                        sizeBytes: 1_000),
                                                     currentKeys: [],
                                                     states: [:],
                                                     waitingKeys: [])

        XCTAssertEqual(status.stage, .notDownloaded)
        XCTAssertEqual(status.downloadedBytes, 0)
        XCTAssertEqual(status.totalBytes, 3_000)
        XCTAssertEqual(status.remainingBytes, 3_000)
        XCTAssertEqual(status.installedPackCount, 0)
        XCTAssertEqual(status.totalPackCount, 3)
        XCTAssertEqual(status.remainingPackCount, 3)
        XCTAssertEqual(status.percent, 0)
        XCTAssertTrue(status.isAvailable)
    }

    // MARK: - Progress

    func testProgressIsWeightedByArchiveSizeNotPackCount() {
        let status = QuranFullDownloadStatus.resolve(packs: QuranImagePackFixture.packs(sizesByJuz: [2: 1_000,
                                                                                                     3: 9_000]),
                                                     currentKeys: [QuranImagePackFixture.packKey(forJuz: 2)],
                                                     states: [:],
                                                     waitingKeys: [])

        XCTAssertEqual(status.downloadedBytes, 1_000)
        XCTAssertEqual(status.totalBytes, 10_000)
        XCTAssertEqual(status.percent, 10)
        XCTAssertEqual(status.installedPackCount, 1)
        XCTAssertEqual(status.totalPackCount, 2)
    }

    func testTransferProgressIsUnscaledFromTheDownloaderShare() {
        let halfShare = ContentDownloader.transferShare / 2

        XCTAssertEqual(QuranFullDownloadStatus.transferredBytes(of: 1_000, progress: halfShare), 500)
        XCTAssertEqual(QuranFullDownloadStatus.transferredBytes(of: 1_000, progress: 0), 0)
        XCTAssertEqual(QuranFullDownloadStatus.transferredBytes(of: 1_000,
                                                                progress: ContentDownloader.transferShare),
                       1_000)
    }

    func testTransferringPackContributesPartialBytes() {
        let status = QuranFullDownloadStatus.resolve(
            packs: QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000),
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .downloading(progress: ContentDownloader.transferShare / 2)],
            waitingKeys: []
        )

        XCTAssertEqual(status.stage, .downloading)
        XCTAssertEqual(status.downloadedBytes, 500)
        XCTAssertEqual(status.totalBytes, 2_000)
        XCTAssertEqual(status.percent, 25)
        XCTAssertEqual(status.installedPackCount, 0)
    }

    func testInstallingPackCountsItsFullBytesButBlocksCompletion() {
        let status = QuranFullDownloadStatus.resolve(
            packs: QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000),
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .installing,
                     QuranImagePackFixture.packKey(forJuz: 3): .installing],
            waitingKeys: []
        )

        XCTAssertEqual(status.stage, .downloading)
        XCTAssertTrue(status.isInstalling)
        XCTAssertEqual(status.downloadedBytes, 2_000)
        XCTAssertEqual(status.fraction, 1)
        XCTAssertFalse(status.isComplete)
    }

    func testPercentNeverReachesHundredBeforeValidation() {
        let status = QuranFullDownloadStatus.resolve(
            packs: QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000),
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .downloading(progress: ContentDownloader.transferShare),
                     QuranImagePackFixture.packKey(forJuz: 3): .downloading(progress: ContentDownloader.transferShare)],
            waitingKeys: []
        )

        XCTAssertEqual(status.fraction, 1)
        XCTAssertEqual(status.percent, 99)
        XCTAssertFalse(status.isComplete)
    }

    // MARK: - Resume

    func testInstalledBytesAreKeptWhileRemainingPacksTransfer() {
        let status = QuranFullDownloadStatus.resolve(
            packs: QuranImagePackFixture.packs(juzNumbers: [2, 3, 4], sizeBytes: 1_000),
            currentKeys: [QuranImagePackFixture.packKey(forJuz: 2)],
            states: [QuranImagePackFixture.packKey(forJuz: 3): .downloading(progress: ContentDownloader.transferShare / 2)],
            waitingKeys: []
        )

        XCTAssertEqual(status.stage, .downloading)
        XCTAssertEqual(status.downloadedBytes, 1_500)
        XCTAssertEqual(status.installedPackCount, 1)
        XCTAssertEqual(status.remainingPackCount, 2)
        XCTAssertEqual(status.remainingBytes, 1_500)
    }

    func testRetryAfterFailureKeepsInstalledProgress() {
        let packs = QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000)
        let installed = [QuranImagePackFixture.packKey(forJuz: 2)]

        let failed = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: Set(installed),
            states: [QuranImagePackFixture.packKey(forJuz: 3): .failed(.transfer)],
            waitingKeys: []
        )

        let retried = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: Set(installed),
            states: [QuranImagePackFixture.packKey(forJuz: 3): .downloading(progress: 0)],
            waitingKeys: []
        )

        XCTAssertEqual(failed.stage, .failed(.transfer))
        XCTAssertEqual(failed.downloadedBytes, 1_000)
        XCTAssertEqual(retried.stage, .downloading)
        XCTAssertEqual(retried.downloadedBytes, 1_000)
    }

    func testCancellationReturnsToIdleAndKeepsInstalledBytes() {
        let status = QuranFullDownloadStatus.resolve(
            packs: QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000),
            currentKeys: [QuranImagePackFixture.packKey(forJuz: 2)],
            states: [QuranImagePackFixture.packKey(forJuz: 3): .notDownloaded],
            waitingKeys: []
        )

        XCTAssertEqual(status.stage, .notDownloaded)
        XCTAssertEqual(status.downloadedBytes, 1_000)
        XCTAssertEqual(status.remainingPackCount, 1)
    }

    // MARK: - Completion validation

    func testCompletionRequiresEveryPackValidated() {
        let packs = QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000)

        let partial = QuranFullDownloadStatus.resolve(packs: packs,
                                                      currentKeys: [QuranImagePackFixture.packKey(forJuz: 2)],
                                                      states: [:],
                                                      waitingKeys: [])

        let whole = QuranFullDownloadStatus.resolve(packs: packs,
                                                    currentKeys: QuranImagePackFixture.packKeys(forJuzNumbers: [2, 3]),
                                                    states: [:],
                                                    waitingKeys: [])

        XCTAssertFalse(partial.isComplete)
        XCTAssertEqual(partial.stage, .notDownloaded)
        XCTAssertTrue(whole.isComplete)
        XCTAssertEqual(whole.stage, .downloaded)
        XCTAssertEqual(whole.percent, 100)
        XCTAssertEqual(whole.remainingBytes, 0)
        XCTAssertEqual(whole.remainingPackCount, 0)
    }

    func testDownloadedEngineStateWithoutValidationDoesNotCompleteTheDownload() {
        let status = QuranFullDownloadStatus.resolve(
            packs: QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000),
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .downloaded,
                     QuranImagePackFixture.packKey(forJuz: 3): .downloaded],
            waitingKeys: []
        )

        XCTAssertFalse(status.isComplete)
        XCTAssertEqual(status.stage, .notDownloaded)
        XCTAssertEqual(status.downloadedBytes, 0)
        XCTAssertEqual(status.installedPackCount, 0)
    }

    // MARK: - Failure

    func testFailureSurfacesOnlyWhenNothingIsBusy() {
        let packs = QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000)

        let busy = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .failed(.transfer),
                     QuranImagePackFixture.packKey(forJuz: 3): .downloading(progress: 0)],
            waitingKeys: []
        )

        let settled = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .failed(.transfer),
                     QuranImagePackFixture.packKey(forJuz: 3): .notDownloaded],
            waitingKeys: []
        )

        XCTAssertEqual(busy.stage, .downloading)
        XCTAssertFalse(busy.hasFailed)
        XCTAssertEqual(settled.stage, .failed(.transfer))
        XCTAssertTrue(settled.hasFailed)
    }

    func testNoSpaceOutranksOtherFailures() {
        let packs = QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000)

        let noSpaceLast = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .failed(.transfer),
                     QuranImagePackFixture.packKey(forJuz: 3): .failed(.noSpace)],
            waitingKeys: []
        )

        let noSpaceFirst = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: [],
            states: [QuranImagePackFixture.packKey(forJuz: 2): .failed(.noSpace),
                     QuranImagePackFixture.packKey(forJuz: 3): .failed(.corrupt)],
            waitingKeys: []
        )

        XCTAssertEqual(noSpaceLast.stage, .failed(.noSpace))
        XCTAssertEqual(noSpaceFirst.stage, .failed(.noSpace))
    }

    // MARK: - Network

    func testWaitingForNetworkRequiresEveryBusyPackToBeWaiting() {
        let packs = QuranImagePackFixture.packs(juzNumbers: [2, 3], sizeBytes: 1_000)
        let states: [String: ContentDownloadState] = [
            QuranImagePackFixture.packKey(forJuz: 2): .downloading(progress: 0),
            QuranImagePackFixture.packKey(forJuz: 3): .downloading(progress: 0)
        ]

        let partiallyWaiting = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: [],
            states: states,
            waitingKeys: QuranImagePackFixture.packKeys(forJuzNumbers: [2])
        )

        let fullyWaiting = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: [],
            states: states,
            waitingKeys: QuranImagePackFixture.packKeys(forJuzNumbers: [2, 3])
        )

        let idle = QuranFullDownloadStatus.resolve(
            packs: packs,
            currentKeys: [],
            states: [:],
            waitingKeys: QuranImagePackFixture.packKeys(forJuzNumbers: [2, 3])
        )

        XCTAssertFalse(partiallyWaiting.isWaitingForNetwork)
        XCTAssertTrue(fullyWaiting.isWaitingForNetwork)
        XCTAssertFalse(idle.isWaitingForNetwork)
    }

    // MARK: - Storage

    func testRequiredFreeBytesDoublesTheRemainingPlusMargin() {
        XCTAssertEqual(QuranFullDownloadStatus.requiredFreeBytes(forRemaining: 1_000),
                       2_000 + QuranFullDownloadStatus.spaceMarginBytes)
        XCTAssertEqual(QuranFullDownloadStatus.requiredFreeBytes(forRemaining: 0),
                       QuranFullDownloadStatus.spaceMarginBytes)
    }

    func testStorageBoundaryRejectsExactlyTheRequiredCapacity() {
        let required = QuranFullDownloadStatus.requiredFreeBytes(forRemaining: 1_000)

        XCTAssertFalse(QuranFullDownloadStatus.hasRoom(forRemaining: 1_000, availableBytes: required))
        XCTAssertFalse(QuranFullDownloadStatus.hasRoom(forRemaining: 1_000, availableBytes: required - 1))
        XCTAssertTrue(QuranFullDownloadStatus.hasRoom(forRemaining: 1_000, availableBytes: required + 1))
    }

    func testUnknownCapacityDoesNotBlockTheDownload() {
        XCTAssertTrue(QuranFullDownloadStatus.hasRoom(forRemaining: 1_000_000_000, availableBytes: nil))
    }

    func testMarkingInsufficientStoragePreservesProgressAndClearsBusyFlags() {
        let resolved = QuranFullDownloadStatus.resolve(
            packs: QuranImagePackFixture.packs(juzNumbers: [2, 3, 4], sizeBytes: 1_000),
            currentKeys: [QuranImagePackFixture.packKey(forJuz: 2)],
            states: [:],
            waitingKeys: []
        )

        let blocked = resolved.markingInsufficientStorage()

        XCTAssertEqual(blocked.stage, .failed(.noSpace))
        XCTAssertEqual(blocked.downloadedBytes, resolved.downloadedBytes)
        XCTAssertEqual(blocked.totalBytes, resolved.totalBytes)
        XCTAssertEqual(blocked.installedPackCount, 1)
        XCTAssertEqual(blocked.totalPackCount, 3)
        XCTAssertFalse(blocked.isInstalling)
        XCTAssertFalse(blocked.isWaitingForNetwork)
        XCTAssertEqual(blocked.requiredFreeBytes,
                       4_000 + QuranFullDownloadStatus.spaceMarginBytes)
    }
}
