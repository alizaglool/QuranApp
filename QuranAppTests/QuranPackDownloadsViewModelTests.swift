//
//  QuranPackDownloadsViewModelTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class QuranPackDownloadsViewModelTests: XCTestCase {

    private var coordinator: QuranPackDownloadsCoordinatorDouble!

    override func setUp() {
        super.setUp()
        coordinator = QuranPackDownloadsCoordinatorDouble()
    }

    override func tearDown() {
        coordinator = nil
        super.tearDown()
    }

    // MARK: - One action

    func testOneActionDownloadRequestsEveryMissingPack() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        viewModel.onFullDownloadTapped()

        guard let confirmation = viewModel.confirmation else {
            return XCTFail("The one-action download did not ask for confirmation")
        }

        XCTAssertEqual(confirmation.juzNumbers, [2, 3, 4])
        XCTAssertEqual(confirmation.id, "all")
        XCTAssertTrue(store.downloadedJuzNumbers.isEmpty)

        viewModel.confirmDownload(confirmation)
        await settleDownloadUpdates()

        XCTAssertEqual(store.downloadedJuzNumbers, [2, 3, 4])
        XCTAssertNil(viewModel.confirmation)
        XCTAssertEqual(viewModel.fullStatus.stage, .downloading)
    }

    func testOneActionDownloadNeverRequestsTheBundledJuz() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        viewModel.onFullDownloadTapped()
        viewModel.confirmDownload(viewModel.confirmation!)
        await settleDownloadUpdates()

        XCTAssertFalse(store.downloadedJuzNumbers.contains(1))
        XCTAssertEqual(viewModel.fullStatus.totalPackCount, 3)
        XCTAssertEqual(viewModel.rows.count, 4)
        XCTAssertTrue(viewModel.rows[0].isBundled)
    }

    func testOneActionDownloadSkipsPacksAlreadyInstalled() async {
        let store = QuranImagePackStoreDouble()
        store.complete(juz: 2)

        let viewModel = await makeViewModel(store: store)

        viewModel.onFullDownloadTapped()
        viewModel.confirmDownload(viewModel.confirmation!)
        await settleDownloadUpdates()

        XCTAssertEqual(store.downloadedJuzNumbers, [3, 4])
        XCTAssertEqual(viewModel.fullStatus.installedPackCount, 1)
    }

    func testCompletedDownloadDisablesTheActionAndIgnoresTaps() async {
        let store = QuranImagePackStoreDouble()
        store.complete(juzNumbers: [2, 3, 4])

        let viewModel = await makeViewModel(store: store)

        XCTAssertTrue(viewModel.fullStatus.isComplete)
        XCTAssertFalse(viewModel.isFullDownloadActionEnabled)
        XCTAssertEqual(viewModel.fullStatus.percent, 100)

        viewModel.onFullDownloadTapped()

        XCTAssertNil(viewModel.confirmation)
        XCTAssertTrue(store.downloadedJuzNumbers.isEmpty)
        XCTAssertEqual(store.cancelAllCount, 0)
    }

    // MARK: - States

    func testActionTitleDistinguishesTheFourStates() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        XCTAssertEqual(viewModel.fullDownloadActionTitle, AppLocalizedKeys.quranFullDownloadAction.value)

        store.simulate(juz: 2, state: .downloading(progress: 0.1))
        await settleDownloadUpdates()
        XCTAssertEqual(viewModel.fullStatus.stage, .downloading)
        XCTAssertEqual(viewModel.fullDownloadActionTitle, AppLocalizedKeys.quranFullDownloadCancelAction.value)

        store.fail(juz: 2, reason: .transfer)
        await settleDownloadUpdates()
        XCTAssertEqual(viewModel.fullStatus.stage, .failed(.transfer))
        XCTAssertEqual(viewModel.fullDownloadActionTitle, AppLocalizedKeys.quranFullDownloadRetryAction.value)

        store.complete(juzNumbers: [2, 3, 4])
        await settleDownloadUpdates()
        XCTAssertEqual(viewModel.fullStatus.stage, .downloaded)
        XCTAssertEqual(viewModel.fullDownloadActionTitle, AppLocalizedKeys.quranFullDownloadDoneAction.value)
    }

    func testProgressDetailReportsTransferredSizeAndPercent() async {
        let store = QuranImagePackStoreDouble(sizeBytes: 1_000)
        let viewModel = await makeViewModel(store: store)

        store.complete(juz: 2)
        store.simulate(juz: 3, state: .downloading(progress: ContentDownloader.transferShare / 2))
        await settleDownloadUpdates()

        let status = viewModel.fullStatus
        XCTAssertEqual(status.downloadedBytes, 1_500)
        XCTAssertEqual(status.totalBytes, 3_000)
        XCTAssertEqual(status.percent, 50)
        XCTAssertTrue(viewModel.fullDownloadDetail.contains(sizeLabel(1_500)))
        XCTAssertTrue(viewModel.fullDownloadDetail.contains(sizeLabel(3_000)))
    }

    func testVerifyingPacksIsSurfacedWhileInstalling() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        store.simulate(juz: 2, state: .installing)
        await settleDownloadUpdates()

        XCTAssertTrue(viewModel.fullStatus.isInstalling)
        XCTAssertFalse(viewModel.fullStatus.isComplete)
        XCTAssertEqual(viewModel.fullDownloadDetail, AppLocalizedKeys.quranFullDownloadInstalling.value)
    }

    func testWaitingForNetworkIsSurfacedWhileDownloading() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        store.simulate(juz: 2, state: .downloading(progress: 0))
        store.setWaiting(juzNumbers: [2])
        await settleDownloadUpdates()

        XCTAssertTrue(viewModel.fullStatus.isWaitingForNetwork)
        XCTAssertEqual(viewModel.fullDownloadDetail, viewModel.waitingNetworkLabel)
    }

    func testValidationIsRequiredBeforeTheQuranIsReportedAsDownloaded() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        store.simulate(juz: 2, state: .downloaded)
        store.simulate(juz: 3, state: .downloaded)
        store.simulate(juz: 4, state: .downloaded)
        await settleDownloadUpdates()

        XCTAssertFalse(viewModel.fullStatus.isComplete)
        XCTAssertTrue(viewModel.isFullDownloadActionEnabled)
        XCTAssertEqual(viewModel.fullStatus.installedPackCount, 0)
        XCTAssertNotEqual(viewModel.fullDownloadActionTitle, AppLocalizedKeys.quranFullDownloadDoneAction.value)
    }

    // MARK: - Cancellation

    func testTappingWhileDownloadingCancelsEverythingWithoutConfirmation() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        viewModel.onFullDownloadTapped()
        viewModel.confirmDownload(viewModel.confirmation!)
        await settleDownloadUpdates()

        viewModel.onFullDownloadTapped()
        await settleDownloadUpdates()

        XCTAssertEqual(store.cancelAllCount, 1)
        XCTAssertNil(viewModel.confirmation)
        XCTAssertEqual(viewModel.fullStatus.stage, .notDownloaded)
        XCTAssertEqual(viewModel.fullDownloadActionTitle, AppLocalizedKeys.quranFullDownloadAction.value)
    }

    func testCancellationKeepsAlreadyInstalledPacks() async {
        let store = QuranImagePackStoreDouble(sizeBytes: 1_000)
        store.complete(juz: 2)

        let viewModel = await makeViewModel(store: store)

        viewModel.onFullDownloadTapped()
        viewModel.confirmDownload(viewModel.confirmation!)
        await settleDownloadUpdates()

        viewModel.onFullDownloadTapped()
        await settleDownloadUpdates()

        XCTAssertEqual(viewModel.fullStatus.downloadedBytes, 1_000)
        XCTAssertEqual(viewModel.fullStatus.installedPackCount, 1)
        XCTAssertEqual(viewModel.fullStatus.remainingPackCount, 2)
    }

    // MARK: - Retry and resume

    func testRetryAfterFailureRequestsOnlyTheMissingPacksWithoutConfirmation() async {
        let store = QuranImagePackStoreDouble()
        store.complete(juzNumbers: [2, 4])

        let viewModel = await makeViewModel(store: store)

        store.fail(juz: 3, reason: .transfer)
        await settleDownloadUpdates()

        XCTAssertEqual(viewModel.fullStatus.stage, .failed(.transfer))

        viewModel.onFullDownloadTapped()
        await settleDownloadUpdates()

        XCTAssertEqual(store.downloadedJuzNumbers, [3])
        XCTAssertNil(viewModel.confirmation)
        XCTAssertEqual(viewModel.fullStatus.stage, .downloading)
    }

    func testResumeDoesNotRequestPacksThatAreAlreadyValid() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        viewModel.onFullDownloadTapped()
        viewModel.confirmDownload(viewModel.confirmation!)
        await settleDownloadUpdates()

        store.complete(juzNumbers: [2, 3])
        await settleDownloadUpdates()

        store.fail(juz: 4, reason: .transfer)
        await settleDownloadUpdates()

        viewModel.onFullDownloadTapped()
        await settleDownloadUpdates()

        XCTAssertEqual(store.downloadedJuzNumbers, [2, 3, 4, 4])
        XCTAssertEqual(viewModel.fullStatus.installedPackCount, 2)
    }

    // MARK: - Individual packs

    func testIndividualPackDownloadStillOpensItsOwnConfirmation() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        let row = viewModel.rows[2]
        viewModel.onRowActionTapped(row)

        XCTAssertEqual(viewModel.confirmation?.juzNumbers, [3])
        XCTAssertEqual(viewModel.confirmation?.id, QuranImagePackFixture.packKey(forJuz: 3))

        viewModel.confirmDownload(viewModel.confirmation!)
        await settleDownloadUpdates()

        XCTAssertEqual(store.downloadedJuzNumbers, [3])
    }

    func testIndividualPackCancelCancelsOnlyThatPack() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        store.simulate(juz: 3, state: .downloading(progress: 0.2))
        await settleDownloadUpdates()

        viewModel.onRowActionTapped(viewModel.rows[2])
        await settleDownloadUpdates()

        XCTAssertEqual(store.cancelledJuzNumbers, [3])
        XCTAssertEqual(store.cancelAllCount, 0)
    }

    func testBundledPackIsReportedAsDownloadedAndNotCancellable() async {
        let store = QuranImagePackStoreDouble()
        let viewModel = await makeViewModel(store: store)

        let bundled = viewModel.rows[0]
        XCTAssertEqual(viewModel.state(for: bundled), .downloaded)

        viewModel.onRowActionTapped(bundled)

        XCTAssertNil(viewModel.confirmation)
        XCTAssertTrue(store.downloadedJuzNumbers.isEmpty)
        XCTAssertTrue(store.cancelledJuzNumbers.isEmpty)
    }

    // MARK: - Storage

    func testInsufficientStorageIsReportedInsteadOfStartingTheDownload() async {
        let store = QuranImagePackStoreDouble(sizeBytes: 1_000)
        let viewModel = await makeViewModel(store: store, availableStorageBytes: { 1_000 })

        viewModel.onFullDownloadTapped()

        XCTAssertTrue(viewModel.hasInsufficientStorage)
        XCTAssertNil(viewModel.confirmation)
        XCTAssertTrue(store.downloadedJuzNumbers.isEmpty)
        XCTAssertEqual(viewModel.fullStatus.stage, .failed(.noSpace))
        XCTAssertEqual(viewModel.fullDownloadDetail,
                       String(format: AppLocalizedKeys.quranFullDownloadNoSpaceFormat.value,
                              sizeLabel(6_000 + QuranFullDownloadStatus.spaceMarginBytes)))
    }

    func testSufficientStorageStartsTheDownload() async {
        let store = QuranImagePackStoreDouble(sizeBytes: 1_000)
        let required = QuranFullDownloadStatus.requiredFreeBytes(forRemaining: 3_000)
        let viewModel = await makeViewModel(store: store, availableStorageBytes: { required + 1 })

        viewModel.onFullDownloadTapped()

        XCTAssertFalse(viewModel.hasInsufficientStorage)
        XCTAssertEqual(viewModel.confirmation?.juzNumbers, [2, 3, 4])
    }

    func testRetryIsBlockedWhenStorageIsStillInsufficient() async {
        let store = QuranImagePackStoreDouble(sizeBytes: 1_000)
        let viewModel = await makeViewModel(store: store, availableStorageBytes: { 1_000 })

        store.fail(juz: 2, reason: .transfer)
        await settleDownloadUpdates()

        viewModel.onFullDownloadTapped()

        XCTAssertTrue(viewModel.hasInsufficientStorage)
        XCTAssertTrue(store.downloadedJuzNumbers.isEmpty)
        XCTAssertEqual(viewModel.fullStatus.stage, .failed(.noSpace))
    }

    // MARK: - Navigation

    func testBackTapAsksTheCoordinatorToPop() async {
        let viewModel = await makeViewModel(store: QuranImagePackStoreDouble())

        viewModel.onBackTapped()

        XCTAssertTrue(coordinator.didCoordinateBack)
    }
}

// MARK: - Helpers

private extension QuranPackDownloadsViewModelTests {

    func makeViewModel(store: QuranImagePackStoreDouble,
                       availableStorageBytes: @escaping () -> Int64? = { Int64.max }) async -> QuranPackDownloadsViewModel {
        let viewModel = QuranPackDownloadsViewModel(coordinator: coordinator,
                                                    store: store,
                                                    availableStorageBytes: availableStorageBytes)
        viewModel.onAppear()
        await settleDownloadUpdates()
        return viewModel
    }

    func sizeLabel(_ bytes: Int64) -> String {
        let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        return "\u{2066}\(size)\u{2069}"
    }
}
