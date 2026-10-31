//
//  QuranDownloadIntegrityTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
import Combine
@testable import QuranApp

// MARK: - Page coverage

final class QuranPackCoverageTests: XCTestCase {

    private var root: URL!

    private let manifest = QuranImagePackFixture.manifest(
        packs: [QuranImagePackFixture.detailedPack(juz: 1, firstPage: 1, pageCount: 21),
                QuranImagePackFixture.detailedPack(juz: 2, firstPage: 22, pageCount: 20)]
    )

    override func setUp() {
        super.setUp()
        root = QuranPackContentFixture.makeDirectory()
    }

    override func tearDown() {
        QuranPackContentFixture.remove(root)
        root = nil
        super.tearDown()
    }

    private func packDirectory(juz: Int) -> URL {
        let directory = root.appendingPathComponent(QuranImagePackFixture.packKey(forJuz: juz), isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func isComplete(_ directory: URL) -> Bool {
        QuranImagePackStore.hasCompletePageCoverage(at: directory, manifest: manifest)
    }

    func testCompletePackCountsAsInstalled() {
        let directory = packDirectory(juz: 2)
        QuranPackContentFixture.writePages(22...41, in: directory)

        XCTAssertTrue(isComplete(directory))
    }

    func testPackMissingOnePageDirectoryIsNotInstalled() {
        let directory = packDirectory(juz: 2)
        QuranPackContentFixture.writePages(22...41, in: directory)
        QuranPackContentFixture.removePage(30, in: directory)

        XCTAssertFalse(isComplete(directory))
    }

    func testPackWithAnEmptyPageDirectoryIsNotInstalled() {
        let directory = packDirectory(juz: 2)
        QuranPackContentFixture.writePages(22...41, in: directory)
        QuranPackContentFixture.blankPage(30, in: directory)

        XCTAssertFalse(isComplete(directory))
    }

    func testPackMissingOneLineImageIsNotInstalled() {
        let directory = packDirectory(juz: 2)
        QuranPackContentFixture.writePages(22...41, in: directory)
        QuranPackContentFixture.removeLine(7, onPage: 30, in: directory)

        XCTAssertFalse(isComplete(directory))
    }

    func testSinglePopulatedPageIsNotInstalled() {
        let directory = packDirectory(juz: 2)
        QuranPackContentFixture.writePages(22...22, in: directory)

        XCTAssertFalse(isComplete(directory))
    }

    func testPackMissingTrailingPagesIsNotInstalled() {
        let directory = packDirectory(juz: 2)
        QuranPackContentFixture.writePages(22...35, in: directory)

        XCTAssertFalse(isComplete(directory))
    }

    func testEmptyDirectoryIsNotInstalled() {
        XCTAssertFalse(isComplete(packDirectory(juz: 2)))
    }

    func testMissingDirectoryIsNotInstalled() {
        XCTAssertFalse(isComplete(root.appendingPathComponent("juz_02", isDirectory: true)))
    }

    func testStagedDirectoryResolvesThePackFromItsLowestPage() {
        let staged = root.appendingPathComponent("pages", isDirectory: true)
        try? FileManager.default.createDirectory(at: staged, withIntermediateDirectories: true)
        QuranPackContentFixture.writePages(22...41, in: staged)

        XCTAssertTrue(isComplete(staged))
    }

    func testStagedDirectoryWithUnmappablePagesIsNotInstalled() {
        let staged = root.appendingPathComponent("pages", isDirectory: true)
        try? FileManager.default.createDirectory(at: staged, withIntermediateDirectories: true)
        QuranPackContentFixture.writePages(900...901, in: staged)

        XCTAssertFalse(isComplete(staged))
    }

    func testWrappedArchiveLayoutIsNotInstalled() {
        let directory = packDirectory(juz: 2)
        let wrapper = directory.appendingPathComponent("quran_images_juz_2", isDirectory: true)
        try? FileManager.default.createDirectory(at: wrapper, withIntermediateDirectories: true)
        QuranPackContentFixture.writePages(22...41, in: wrapper)

        XCTAssertFalse(isComplete(directory))
    }

    func testReceiptAndOtherNonPageEntriesAreTolerated() {
        let directory = packDirectory(juz: 2)
        QuranPackContentFixture.writePages(22...41, in: directory)
        try? Data("receipt".utf8).write(to: directory.appendingPathComponent(".content_receipt"))

        XCTAssertTrue(isComplete(directory))
    }
}

// MARK: - Transfer validation

final class ContentTransferValidationTests: XCTestCase {

    private let url = URL(string: "https://example.invalid/pack.zip")!

    private func response(status: Int, length: Int64) -> HTTPURLResponse {
        HTTPURLResponse(url: url,
                        statusCode: status,
                        httpVersion: "HTTP/1.1",
                        headerFields: ["Content-Length": "\(length)"])!
    }

    func testMatchingTransferIsAccepted() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 200, length: 4_096),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: 4_096)
        XCTAssertNil(rejection)
    }

    func testNotFoundFailsAsUnavailableRatherThanCorrupt() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 404, length: 512),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: 512)

        XCTAssertEqual(rejection?.contentDownloadFailure, .unavailable)
        XCTAssertNotEqual(rejection?.contentDownloadFailure, .corrupt)
    }

    func testServerErrorFailsAsUnavailable() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 500, length: 4_096),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: 4_096)

        XCTAssertEqual(rejection?.contentDownloadFailure, .unavailable)
    }

    func testRedirectBodyFailsAsUnavailable() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 302, length: 4_096),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: 4_096)

        XCTAssertEqual(rejection?.contentDownloadFailure, .unavailable)
    }

    func testAdvertisedLengthBelowTheManifestSizeFailsAsCorrupt() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 200, length: 1_024),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: nil)

        XCTAssertEqual(rejection?.contentDownloadFailure, .corrupt)
    }

    func testAdvertisedLengthAboveTheManifestSizeFailsAsCorrupt() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 200, length: 9_999),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: nil)

        XCTAssertEqual(rejection?.contentDownloadFailure, .corrupt)
    }

    func testTruncatedPayloadFailsAsCorruptEvenWhenHeadersAgree() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 200, length: 4_096),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: 2_048)

        XCTAssertEqual(rejection?.contentDownloadFailure, .corrupt)
    }

    func testUnknownAdvertisedLengthFallsBackToTheReceivedSize() {
        let unknown = URLResponse(url: url,
                                  mimeType: "application/zip",
                                  expectedContentLength: -1,
                                  textEncodingName: nil)

        XCTAssertNil(ContentDownloader.transferRejection(for: unknown,
                                                         declaredBytes: 4_096,
                                                         receivedBytes: 4_096))

        XCTAssertEqual(ContentDownloader.transferRejection(for: unknown,
                                                           declaredBytes: 4_096,
                                                           receivedBytes: 10)?.contentDownloadFailure,
                       .corrupt)
    }

    func testStatusCodeIsCheckedBeforeTheDeclaredSize() {
        let rejection = ContentDownloader.transferRejection(for: response(status: 404, length: 4_096),
                                                            declaredBytes: 4_096,
                                                            receivedBytes: 4_096)

        XCTAssertEqual(rejection?.contentDownloadFailure, .unavailable)
    }

    func testCatalogWithoutADeclaredSizeSkipsTheSizeCheck() {
        XCTAssertNil(ContentDownloader.transferRejection(for: response(status: 200, length: 7),
                                                         declaredBytes: 0,
                                                         receivedBytes: 9))
    }

    func testMissingResponseStillChecksTheReceivedSize() {
        XCTAssertEqual(ContentDownloader.transferRejection(for: nil,
                                                           declaredBytes: 4_096,
                                                           receivedBytes: 11)?.contentDownloadFailure,
                       .corrupt)

        XCTAssertNil(ContentDownloader.transferRejection(for: nil,
                                                         declaredBytes: 4_096,
                                                         receivedBytes: 4_096))
    }
}

// MARK: - Digest verification

final class AthkarArchiveDigestTests: XCTestCase {

    private let digest = String(repeating: "b", count: 64)

    private func assertRejected(_ expected: String, _ message: String) {
        XCTAssertThrowsError(try AthkarArchive.verify(digest: digest, matches: expected), message) { error in
            XCTAssertEqual((error as? AthkarDataError)?.contentDownloadFailure, .corrupt)
        }
    }

    func testEmptyExpectedDigestFails() {
        assertRejected("", "a catalog entry without a checksum must not pass verification")
    }

    func testWhitespaceOnlyExpectedDigestFails() {
        assertRejected("   \n", "a blank checksum must not pass verification")
    }

    func testTruncatedExpectedDigestFails() {
        assertRejected(String(repeating: "b", count: 40), "a short checksum must not pass verification")
    }

    func testOverlongExpectedDigestFails() {
        assertRejected(String(repeating: "b", count: 65), "an overlong checksum must not pass verification")
    }

    func testNonHexExpectedDigestFails() {
        assertRejected(String(repeating: "z", count: 64), "a non hex checksum must not pass verification")
    }

    func testMismatchedDigestFails() {
        assertRejected(String(repeating: "c", count: 64), "a different checksum must not pass verification")
    }

    func testMatchingDigestPasses() {
        XCTAssertNoThrow(try AthkarArchive.verify(digest: digest, matches: digest))
    }

    func testMatchingDigestIgnoresCaseAndSurroundingWhitespace() {
        XCTAssertNoThrow(try AthkarArchive.verify(digest: digest, matches: "  \(digest.uppercased())\n"))
    }

    func testBundledCatalogsDeclareWellFormedDigests() throws {
        let names = ["quran_images_manifest.json", "zikr_athkar_manifest.json"]
        var inspected = 0

        for url in Self.bundledManifestURLs(named: names) {
            let json = try JSONSerialization.jsonObject(with: try Data(contentsOf: url)) as? [String: Any]
            let packs = json?["packs"] as? [[String: Any]] ?? []

            XCTAssertFalse(packs.isEmpty, "\(url.lastPathComponent) declares no packs")
            inspected += 1

            for pack in packs {
                let digest = (pack["sha256"] as? String ?? "").lowercased()
                XCTAssertTrue(AthkarArchive.isWellFormedDigest(digest),
                              "\(url.lastPathComponent) entry \(pack["key"] ?? "?") has no usable sha256")
            }
        }

        XCTAssertEqual(inspected, names.count, "both shipped catalogs must be inspectable")
    }

    private static func bundledManifestURLs(named names: [String]) -> [URL] {
        let bundle = Bundle(for: QuranImagePackStore.self)
        guard let root = bundle.resourceURL,
              let walker = FileManager.default.enumerator(at: root,
                                                          includingPropertiesForKeys: nil) else { return [] }

        var found: [URL] = []

        for case let url as URL in walker where names.contains(url.lastPathComponent) {
            found.append(url)
        }

        return found
    }
}

// MARK: - Cancellable extraction

final class AthkarArchiveExtractionTests: XCTestCase {

    private var root: URL!
    private var archive: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = QuranPackContentFixture.makeDirectory()
        archive = root.appendingPathComponent("pack.zip")
        try QuranStoredArchiveFixture.write(pages: 22...26, lines: 3, to: archive)
    }

    override func tearDown() {
        QuranPackContentFixture.remove(root)
        root = nil
        archive = nil
        super.tearDown()
    }

    func testExtractionWritesEveryPageImage() throws {
        let destination = root.appendingPathComponent("pages", isDirectory: true)
        let written = try AthkarArchive.extract(archiveAt: archive,
                                                to: destination,
                                                where: { $0.path.hasSuffix(".png") })

        XCTAssertEqual(written.count, 15)
        XCTAssertEqual(QuranPackContentFixture.pageImageCount(in: destination), 15)
    }

    func testCancelledExtractionStopsImmediately() {
        let destination = root.appendingPathComponent("pages", isDirectory: true)

        XCTAssertThrowsError(try AthkarArchive.extract(archiveAt: archive,
                                                       to: destination,
                                                       isCancelled: { true },
                                                       where: { $0.path.hasSuffix(".png") })) { error in
            XCTAssertTrue(error is CancellationError)
        }

        XCTAssertEqual(QuranPackContentFixture.pageImageCount(in: destination), 0)
    }

    func testExtractionStopsPartWayThroughWhenCancelled() {
        let destination = root.appendingPathComponent("pages", isDirectory: true)
        var seen = 0

        XCTAssertThrowsError(try AthkarArchive.extract(archiveAt: archive,
                                                       to: destination,
                                                       isCancelled: {
            seen += 1
            return seen > 4
        },
                                                       where: { $0.path.hasSuffix(".png") }))

        let written = QuranPackContentFixture.pageImageCount(in: destination)
        XCTAssertEqual(written, 4)
        XCTAssertLessThan(written, 15)
    }
}

// MARK: - Install, space and cancellation

final class ContentDownloaderInstallTests: XCTestCase {

    private final class DownloaderBox {
        var downloader: ContentDownloader?
    }

    private var root: URL!
    private var contentRoot: URL!
    private var stagingRoot: URL!
    private var archive: URL!
    private var digest: String!

    private let manifest = QuranImagePackFixture.manifest(
        packs: [QuranImagePackFixture.detailedPack(juz: 1, firstPage: 1, pageCount: 21),
                QuranImagePackFixture.detailedPack(juz: 2, firstPage: 22, pageCount: 20)]
    )

    override func setUp() {
        super.setUp()
        root = QuranPackContentFixture.makeDirectory()
        contentRoot = root.appendingPathComponent("content", isDirectory: true)
        stagingRoot = root.appendingPathComponent("staging", isDirectory: true)
        archive = root.appendingPathComponent("pack.zip")
        digest = QuranPackContentFixture.writeOpaqueArchive(bytes: 2_048, at: archive)
    }

    override func tearDown() {
        QuranPackContentFixture.remove(root)
        root = nil
        contentRoot = nil
        stagingRoot = nil
        archive = nil
        digest = nil
        super.tearDown()
    }

    private func request(juz: Int, sha256: String? = nil, sizeBytes: Int = 2_048) -> ContentDownloadRequest {
        ContentDownloadRequest(key: QuranImagePackFixture.packKey(forJuz: juz),
                              remoteURL: archive,
                              archiveSizeBytes: sizeBytes,
                              archiveSha256: sha256 ?? digest)
    }

    private func makeDownloader(capacity: @escaping ContentDownloader.VolumeCapacityProbe = { _ in 1 << 40 },
                                stage: @escaping ContentDownloader.CancellableStagedInstall) -> ContentDownloader {
        ContentDownloader(contentRoot: contentRoot,
                          stagingRoot: stagingRoot,
                          queueLabel: "tests.install.\(UUID().uuidString)",
                          sessionIdentifier: nil,
                          fileManager: .default,
                          availableCapacity: capacity,
                          isInstalled: { [manifest] directory in
                              QuranImagePackStore.hasCompletePageCoverage(at: directory, manifest: manifest)
                          },
                          cancellableStage: stage)
    }

    private func completeStage(pages: ClosedRange<Int>) -> ContentDownloader.CancellableStagedInstall {
        { _, _, staging, isCancelled in
            let destination = staging.appendingPathComponent("pages", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

            for page in pages {
                if isCancelled() { throw CancellationError() }
                QuranPackContentFixture.writePages(page...page, in: destination)
            }
            return destination
        }
    }

    private func installedImageCount(juz: Int) -> Int {
        let directory = contentRoot.appendingPathComponent(QuranImagePackFixture.packKey(forJuz: juz),
                                                           isDirectory: true)
        return QuranPackContentFixture.pageImageCount(in: directory)
    }

    private func awaitState(_ downloader: ContentDownloader,
                            key: String,
                            timeout: TimeInterval = 20,
                            until predicate: @escaping (ContentDownloadState) -> Bool) {
        let settled = expectation(description: "state for \(key)")
        settled.assertForOverFulfill = false

        let subscription = downloader.$states
            .receive(on: DispatchQueue.main)
            .sink { states in
                if let state = states[key], predicate(state) { settled.fulfill() }
            }

        wait(for: [settled], timeout: timeout)
        subscription.cancel()
    }

    private func awaitInstall(_ downloader: ContentDownloader, juz: Int, timeout: TimeInterval = 20) {
        awaitState(downloader,
                   key: QuranImagePackFixture.packKey(forJuz: juz),
                   timeout: timeout) { [self] state in
            state == .downloaded && installedImageCount(juz: juz) > 0
        }
    }

    // MARK: - Install

    func testCompleteInstallSucceeds() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))
        let outcome = downloader.performInstall(request(juz: 2), from: archive)

        XCTAssertEqual(outcome, .downloaded)
        XCTAssertEqual(installedImageCount(juz: 2), 20 * QuranImagePackFixture.linesPerPage)
        XCTAssertTrue(downloader.isCurrent(request(juz: 2)))
    }

    func testWrongDigestFailsAsCorruptAndInstallsNothing() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))
        let outcome = downloader.performInstall(request(juz: 2, sha256: String(repeating: "f", count: 64)),
                                                from: archive)

        XCTAssertEqual(outcome, .failed(.corrupt))
        XCTAssertEqual(installedImageCount(juz: 2), 0)
    }

    func testCatalogEntryWithoutAChecksumFailsAndInstallsNothing() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))
        let outcome = downloader.performInstall(request(juz: 2, sha256: ""), from: archive)

        XCTAssertEqual(outcome, .failed(.corrupt))
        XCTAssertEqual(installedImageCount(juz: 2), 0)
    }

    func testPartiallyExtractedPackFailsAsUnavailableAndInstallsNothing() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...30))
        let outcome = downloader.performInstall(request(juz: 2), from: archive)

        XCTAssertEqual(outcome, .failed(.unavailable))
        XCTAssertEqual(installedImageCount(juz: 2), 0)
        XCTAssertFalse(downloader.isDownloaded(QuranImagePackFixture.packKey(forJuz: 2)))
    }

    func testOutOfSpaceDuringStagingFailsAsNoSpace() {
        let downloader = makeDownloader(stage: { _, _, _, _ in
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError)
        })

        XCTAssertEqual(downloader.performInstall(request(juz: 2), from: archive), .failed(.noSpace))
    }

    // MARK: - Cancellation during extraction

    func testCancellingDuringExtractionInstallsNothing() {
        let box = DownloaderBox()
        var pagesWritten = 0

        let downloader = makeDownloader(stage: { request, _, staging, isCancelled in
            let destination = staging.appendingPathComponent("pages", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

            for page in 22...41 {
                if page == 25 { box.downloader?.cancel(key: request.key) }
                if isCancelled() { throw CancellationError() }

                QuranPackContentFixture.writePages(page...page, in: destination)
                pagesWritten += 1
            }
            return destination
        })

        box.downloader = downloader

        let outcome = downloader.performInstall(request(juz: 2), from: archive)

        XCTAssertEqual(outcome, .notDownloaded)
        XCTAssertEqual(installedImageCount(juz: 2), 0)
        XCTAssertLessThan(pagesWritten, 20)
        XCTAssertFalse(downloader.isDownloaded(QuranImagePackFixture.packKey(forJuz: 2)))
    }

    func testCancellationProbeStaysFalseForAnUncancelledInstall() {
        var observed: [Bool] = []

        let downloader = makeDownloader(stage: { _, _, staging, isCancelled in
            let destination = staging.appendingPathComponent("pages", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

            for page in 22...41 {
                observed.append(isCancelled())
                QuranPackContentFixture.writePages(page...page, in: destination)
            }
            return destination
        })

        XCTAssertEqual(downloader.performInstall(request(juz: 2), from: archive), .downloaded)
        XCTAssertEqual(observed.count, 20)
        XCTAssertFalse(observed.contains(true))
    }

    func testCancellingAfterExtractionStillInstallsNothing() {
        let box = DownloaderBox()

        let downloader = makeDownloader(stage: { request, _, staging, _ in
            let destination = staging.appendingPathComponent("pages", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            QuranPackContentFixture.writePages(22...41, in: destination)
            box.downloader?.cancel(key: request.key)
            return destination
        })

        box.downloader = downloader

        XCTAssertEqual(downloader.performInstall(request(juz: 2), from: archive), .notDownloaded)
        XCTAssertEqual(installedImageCount(juz: 2), 0)
    }

    // MARK: - Storage

    func testLowCapacityBlocksTheDownloadAndClearsItFromPending() {
        let downloader = makeDownloader(capacity: { _ in 1_000 }, stage: completeStage(pages: 22...41))
        let pending = request(juz: 2, sizeBytes: 95_000_000)

        downloader.download(pending)
        awaitState(downloader, key: pending.key) { $0 == .failed(.noSpace) }

        XCTAssertFalse(downloader.pendingKeys.contains(pending.key))
        XCTAssertEqual(installedImageCount(juz: 2), 0)
    }

    func testAmpleCapacityStartsTheDownload() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))
        let pending = request(juz: 2)

        downloader.download(pending)
        awaitInstall(downloader, juz: 2)

        XCTAssertEqual(installedImageCount(juz: 2), 20 * QuranImagePackFixture.linesPerPage)
    }

    func testUnreadableCapacityStillStartsTheDownload() {
        let downloader = makeDownloader(capacity: { _ in nil }, stage: completeStage(pages: 22...41))
        let pending = request(juz: 2)

        downloader.download(pending)
        awaitInstall(downloader, juz: 2)

        XCTAssertEqual(installedImageCount(juz: 2), 20 * QuranImagePackFixture.linesPerPage)
    }

    func testVolumeCapacityIsReadableForARealDirectory() {
        let capacity = ContentDownloader.volumeCapacity(at: root)

        XCTAssertNotNil(capacity, "the three probe chain must report capacity for an existing directory")
        XCTAssertGreaterThan(capacity ?? 0, 0)
    }

    func testVolumeCapacityIsReadableForADirectoryThatDoesNotExistYet() {
        let capacity = ContentDownloader.volumeCapacity(at: root.appendingPathComponent("absent", isDirectory: true))

        XCTAssertNotNil(capacity)
        XCTAssertGreaterThan(capacity ?? 0, 0)
    }

    func testOutOfSpaceErrorsMapToNoSpace() {
        let cocoa = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteOutOfSpaceError)
        let posix = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOSPC))
        let wrapped = NSError(domain: NSCocoaErrorDomain,
                              code: NSFileWriteUnknownError,
                              userInfo: [NSUnderlyingErrorKey: posix])

        XCTAssertEqual(ContentDownloader.failure(for: cocoa), .noSpace)
        XCTAssertEqual(ContentDownloader.failure(for: posix), .noSpace)
        XCTAssertEqual(ContentDownloader.failure(for: wrapped), .noSpace)
    }

    func testUnrelatedErrorsMapToTransfer() {
        let timeout = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        XCTAssertEqual(ContentDownloader.failure(for: timeout), .transfer)
        XCTAssertEqual(ContentDownloader.failure(for: AthkarDataError.missingResource("x")), .transfer)
        XCTAssertEqual(ContentDownloader.failure(for: ContentTransferError.unexpectedStatus(404)), .unavailable)
        XCTAssertEqual(ContentDownloader.failure(for: AthkarDataError.corruptArchive("x")), .corrupt)
    }

    // MARK: - Declared size over a real transfer

    func testDeclaredSizeMismatchFailsAsCorruptOverARealTransfer() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))
        let pending = request(juz: 2, sizeBytes: 4_096)

        downloader.download(pending)
        awaitState(downloader, key: pending.key) { $0 == .failed(.corrupt) }

        XCTAssertEqual(installedImageCount(juz: 2), 0)
    }

    // MARK: - Resume

    func testResumeDoesNotRefetchACompletedPack() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))
        let pending = request(juz: 2)

        downloader.download(pending)
        awaitInstall(downloader, juz: 2)

        let installed = installedImageCount(juz: 2)
        XCTAssertTrue(downloader.pendingKeys.isEmpty)

        downloader.resumeInterrupted()
        downloader.download(pending)

        XCTAssertTrue(downloader.pendingKeys.isEmpty)
        XCTAssertEqual(downloader.state(for: pending), .downloaded)
        XCTAssertEqual(installedImageCount(juz: 2), installed)
    }

    func testResumeWithNothingPendingStartsNothing() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))

        downloader.resumeInterrupted()

        XCTAssertTrue(downloader.pendingKeys.isEmpty)
        XCTAssertTrue(downloader.installedKeys().isEmpty)
    }

    func testAnInterruptedPackRestartsAloneAndCompletedPacksSurvive() {
        let downloader = makeDownloader(stage: { _, _, staging, _ in
            let destination = staging.appendingPathComponent("pages", isDirectory: true)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            QuranPackContentFixture.writePages(1...21, in: destination)
            QuranPackContentFixture.writePages(22...41, in: destination)
            return destination
        })

        let first = request(juz: 1)
        let second = request(juz: 2)

        downloader.download(first)
        awaitInstall(downloader, juz: 1)

        downloader.download(second)
        awaitInstall(downloader, juz: 2)

        XCTAssertEqual(downloader.installedKeys(), [first.key, second.key])

        try? FileManager.default.removeItem(at: contentRoot.appendingPathComponent(second.key, isDirectory: true))
        XCTAssertEqual(downloader.installedKeys(), [first.key])
        XCTAssertTrue(downloader.isCurrent(first))

        downloader.download(second)
        awaitInstall(downloader, juz: 2)

        XCTAssertEqual(downloader.installedKeys(), [first.key, second.key])
        XCTAssertTrue(downloader.isCurrent(first))
        XCTAssertTrue(downloader.isCurrent(second))
    }

    func testCancellingOnePackLeavesTheOtherInstalled() {
        let downloader = makeDownloader(stage: completeStage(pages: 22...41))
        let keep = request(juz: 2)

        downloader.download(keep)
        awaitInstall(downloader, juz: 2)

        let other = ContentDownloadRequest(key: QuranImagePackFixture.packKey(forJuz: 1),
                                           remoteURL: archive,
                                           archiveSizeBytes: 2_048,
                                           archiveSha256: digest)

        downloader.cancel(key: other.key)

        XCTAssertFalse(downloader.pendingKeys.contains(other.key))
        XCTAssertEqual(downloader.installedKeys(), [keep.key])
        XCTAssertTrue(downloader.isCurrent(keep))
    }
}
