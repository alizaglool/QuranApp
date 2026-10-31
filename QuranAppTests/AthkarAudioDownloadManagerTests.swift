//
//  AthkarAudioDownloadManagerTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
@testable import QuranApp

final class AthkarAudioDownloadManagerTests: XCTestCase {

    // MARK: - Fixtures

    private let packKey = "download_tests"
    private var root: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("athkar-audio-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let root { try? FileManager.default.removeItem(at: root) }
        root = nil
        try super.tearDownWithError()
    }

    private func makeManager(
        expected: Set<String>,
        published: String?
    ) -> AthkarAudioDownloadManager {
        AthkarAudioDownloadManager(
            rootDirectory: root,
            expectedAudioFileNames: { _ in expected },
            publishedArchiveChecksum: { _ in published }
        )
    }

    private func install(files: [String], receipt: String?) throws {
        let directory = root
            .appendingPathComponent("athkar_audio", isDirectory: true)
            .appendingPathComponent(packKey, isDirectory: true)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        for file in files {
            try Data("audio".utf8).write(to: directory.appendingPathComponent(file))
        }

        if let receipt {
            try Data(receipt.utf8).write(to: directory.appendingPathComponent(".content_receipt"))
        }
    }

    private func item(audio: String) -> AthkarItem {
        AthkarReaderFixture.item(id: 1, count: 1, audio: "audio/\(audio)")
    }

    // MARK: - Coverage

    func testPartialInstallIsNotReportedAsDownloaded() throws {
        try install(files: ["a.m4a", "b.m4a"], receipt: "abc123")
        let manager = makeManager(expected: ["a.m4a", "b.m4a", "c.m4a"], published: "abc123")

        XCTAssertFalse(manager.isDownloaded(packKey))
    }

    func testCompleteInstallIsReportedAsDownloaded() throws {
        try install(files: ["a.m4a", "b.m4a", "c.m4a"], receipt: "abc123")
        let manager = makeManager(expected: ["a.m4a", "b.m4a", "c.m4a"], published: "abc123")

        XCTAssertTrue(manager.isDownloaded(packKey))
    }

    func testExtraFilesDoNotBreakCoverage() throws {
        try install(files: ["a.m4a", "b.m4a", "extra.m4a"], receipt: "abc123")
        let manager = makeManager(expected: ["a.m4a", "b.m4a"], published: "abc123")

        XCTAssertTrue(manager.isDownloaded(packKey))
    }

    func testEmptyDirectoryIsNotReportedAsDownloaded() throws {
        try install(files: [], receipt: "abc123")
        let manager = makeManager(expected: ["a.m4a"], published: "abc123")

        XCTAssertFalse(manager.isDownloaded(packKey))
    }

    func testMissingAudioFileIsNotServedForPlayback() throws {
        try install(files: ["a.m4a", "b.m4a"], receipt: "abc123")
        let manager = makeManager(expected: ["a.m4a", "b.m4a"], published: "abc123")

        XCTAssertNotNil(manager.localURL(for: item(audio: "a.m4a"), inPack: packKey))
        XCTAssertNil(manager.localURL(for: item(audio: "missing.m4a"), inPack: packKey))
    }

    // MARK: - Staleness

    func testRefreshedManifestInvalidatesAStaleInstall() throws {
        try install(files: ["a.m4a"], receipt: "old-checksum")
        let manager = makeManager(expected: ["a.m4a"], published: "new-checksum")

        XCTAssertFalse(manager.isInstallCurrent(packKey))
        XCTAssertFalse(manager.isDownloaded(packKey))
        XCTAssertNil(manager.localURL(for: item(audio: "a.m4a"), inPack: packKey))
    }

    func testMatchingReceiptKeepsTheInstallCurrent() throws {
        try install(files: ["a.m4a"], receipt: "abc123")
        let manager = makeManager(expected: ["a.m4a"], published: "abc123")

        XCTAssertTrue(manager.isInstallCurrent(packKey))
        XCTAssertNotNil(manager.localURL(for: item(audio: "a.m4a"), inPack: packKey))
    }

    func testReceiptComparisonIgnoresChecksumCasing() throws {
        try install(files: ["a.m4a"], receipt: "ABC123")
        let manager = makeManager(expected: ["a.m4a"], published: "abc123")

        XCTAssertTrue(manager.isInstallCurrent(packKey))
    }

    func testMissingReceiptInvalidatesAPublishedPack() throws {
        try install(files: ["a.m4a"], receipt: nil)
        let manager = makeManager(expected: ["a.m4a"], published: "abc123")

        XCTAssertFalse(manager.isInstallCurrent(packKey))
        XCTAssertFalse(manager.isDownloaded(packKey))
    }

    func testUnpublishedPackIsJudgedByCoverageAlone() throws {
        try install(files: ["a.m4a"], receipt: nil)
        let manager = makeManager(expected: ["a.m4a"], published: nil)

        XCTAssertTrue(manager.isInstallCurrent(packKey))
        XCTAssertTrue(manager.isDownloaded(packKey))
    }

    func testUninstalledPackIsNotReportedAsDownloaded() {
        let manager = makeManager(expected: ["a.m4a"], published: "abc123")

        XCTAssertFalse(manager.isDownloaded(packKey))
        XCTAssertNil(manager.localURL(for: item(audio: "a.m4a"), inPack: packKey))
    }

    // MARK: - Declared contents

    func testDeclaredAudioFileNamesAreFlattenedBasenames() {
        let names = AthkarAudioDownloadManager.declaredAudioFileNames(inPack: "ruqyah_quran")

        for name in names {
            XCTAssertFalse(name.contains("/"))
            XCTAssertTrue(name.hasSuffix(".m4a"))
        }
    }
}
