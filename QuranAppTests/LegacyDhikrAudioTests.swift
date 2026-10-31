//
//  LegacyDhikrAudioTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class LegacyDhikrAudioTests: XCTestCase {

    // MARK: - Fixtures

    private static let takbeeratIdentifiers: Set<String> = ["takbir_1", "takbir_2", "takbir_3"]
    private static let hundredCountIdentifiers: Set<String> = ["morning_6", "morning_5", "morning_2", "evening_4", "evening_3"]

    private var root: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("legacy-dhikr-audio-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let root { try? FileManager.default.removeItem(at: root) }
        root = nil
        try super.tearDownWithError()
    }

    private func makeManager(published: String? = nil) -> AthkarAudioDownloadManager {
        AthkarAudioDownloadManager(
            rootDirectory: root,
            expectedAudioFileNames: { _ in [] },
            publishedArchiveChecksum: { _ in published }
        )
    }

    private func install(fileName: String, inPack key: String, receipt: String? = nil) throws {
        let directory = root
            .appendingPathComponent("athkar_audio", isDirectory: true)
            .appendingPathComponent(key, isDirectory: true)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("audio".utf8).write(to: directory.appendingPathComponent(fileName))

        if let receipt {
            try Data(receipt.utf8).write(to: directory.appendingPathComponent(".content_receipt"))
        }
    }

    private func legacyCategories() throws -> [DhikrCategory] {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "adhkar", withExtension: "json"))
        return try JSONDecoder().decode([DhikrCategory].self, from: try Data(contentsOf: url))
    }

    private func legacyAdhkarWithAudio() throws -> [Dhikr] {
        try legacyCategories().flatMap(\.adhkar).filter { $0.audio != nil }
    }

    private func makeViewModel(category: DhikrCategory) -> AdhkarReadingViewModel {
        AdhkarReadingViewModel(coordinator: AdhkarCoordinatorDouble(),
                               category: category,
                               downloads: makeManager())
    }

    private func dhikr(count: Int, audio: String?) -> Dhikr {
        Dhikr(id: "fixture_\(count)",
              textAr: "نص",
              description: nil,
              title: "عنوان",
              count: count,
              audio: audio,
              segments: nil,
              repeatLabel: nil)
    }
}

// MARK: - Catalog Coverage

extension LegacyDhikrAudioTests {

    func testEveryLegacyOccurrenceWithAudioIsResolvable() throws {
        let adhkar = try legacyAdhkarWithAudio()
        XCTAssertEqual(adhkar.count, 94)

        let mapped = adhkar.filter { LegacyDhikrAudioCatalog.source(forDhikrIdentifier: $0.id) != nil }
        let unmapped = adhkar.filter { LegacyDhikrAudioCatalog.source(forDhikrIdentifier: $0.id) == nil }

        XCTAssertEqual(mapped.count, 91)
        XCTAssertEqual(Set(unmapped.map(\.id)), Self.takbeeratIdentifiers)
    }

    func testCatalogSizeMatchesMappedOccurrences() {
        XCTAssertEqual(LegacyDhikrAudioCatalog.sources.count, 91)
    }

    func testCatalogIdentifiersAllExistInLegacyContent() throws {
        let known = Set(try legacyCategories().flatMap(\.adhkar).map(\.id))

        for identifier in LegacyDhikrAudioCatalog.sources.keys {
            XCTAssertTrue(known.contains(identifier), "unknown dhikr identifier \(identifier)")
        }
    }

    func testCatalogPackKeysAreAudioPacksInTheManifest() {
        let service = AthkarManifestService.shared

        for key in Set(LegacyDhikrAudioCatalog.sources.values.map(\.packKey)) {
            guard let pack = service.pack(key: key) else {
                XCTFail("pack \(key) is missing from the manifest")
                continue
            }
            XCTAssertTrue(pack.hasAudio, "pack \(key) does not declare audio")
        }
    }

    func testCatalogFileNamesAreFlatAudioFiles() {
        for source in LegacyDhikrAudioCatalog.sources.values {
            XCTAssertTrue(source.fileName.hasSuffix(".m4a"), "unexpected extension in \(source.fileName)")
            XCTAssertFalse(source.fileName.contains("/"), "file name must be flat: \(source.fileName)")
            XCTAssertFalse(source.packKey.isEmpty)
        }
    }

    func testTakbeeratOccurrencesAreNotRemapped() {
        for identifier in Self.takbeeratIdentifiers {
            XCTAssertNil(LegacyDhikrAudioCatalog.source(forDhikrIdentifier: identifier))
        }
    }
}

// MARK: - Resolver Priority

extension LegacyDhikrAudioTests {

    func testDownloadedPackAudioResolvesFirst() throws {
        let source = try XCTUnwrap(LegacyDhikrAudioCatalog.source(forDhikrIdentifier: "evening_23"))
        try install(fileName: source.fileName, inPack: source.packKey)

        let service = DhikrAudioService(downloads: makeManager())
        let resolved = service.resourceURL(forDhikrIdentifier: "evening_23", resource: "1.mp3")

        XCTAssertEqual(resolved?.lastPathComponent, source.fileName)
        XCTAssertTrue(resolved?.path.hasPrefix(root.path) == true)
    }

    func testUndownloadedPackAudioDoesNotResolve() throws {
        let service = DhikrAudioService(downloads: makeManager())

        XCTAssertNil(service.resourceURL(forDhikrIdentifier: "evening_23", resource: "1.mp3"))
    }

    func testStaleInstallDoesNotResolve() throws {
        let source = try XCTUnwrap(LegacyDhikrAudioCatalog.source(forDhikrIdentifier: "evening_23"))
        try install(fileName: source.fileName, inPack: source.packKey, receipt: "old-checksum")

        let service = DhikrAudioService(downloads: makeManager(published: "new-checksum"))

        XCTAssertNil(service.downloadedPackURL(forDhikrIdentifier: "evening_23"))
    }

    func testMatchingInstallChecksumResolves() throws {
        let source = try XCTUnwrap(LegacyDhikrAudioCatalog.source(forDhikrIdentifier: "evening_23"))
        try install(fileName: source.fileName, inPack: source.packKey, receipt: "same-checksum")

        let service = DhikrAudioService(downloads: makeManager(published: "same-checksum"))

        XCTAssertEqual(service.downloadedPackURL(forDhikrIdentifier: "evening_23")?.lastPathComponent,
                       source.fileName)
    }
}

// MARK: - Bundle Fallback

extension LegacyDhikrAudioTests {

    func testBundledTakbeeratStillResolves() {
        let service = DhikrAudioService(downloads: makeManager())

        for identifier in Self.takbeeratIdentifiers {
            let resolved = service.resourceURL(forDhikrIdentifier: identifier, resource: "takbeerat")
            XCTAssertEqual(resolved?.lastPathComponent, "takbeerat.m4a", "takbeerat broke for \(identifier)")
        }
    }

    func testUnknownIdentifierFallsBackToBundle() {
        let service = DhikrAudioService(downloads: makeManager())
        let resolved = service.resourceURL(forDhikrIdentifier: "not_a_dhikr", resource: "takbeerat")

        XCTAssertEqual(resolved?.lastPathComponent, "takbeerat.m4a")
    }

    func testMissingResourceResolvesToNothing() {
        let service = DhikrAudioService(downloads: makeManager())

        XCTAssertNil(service.resourceURL(forDhikrIdentifier: "not_a_dhikr", resource: "no_such_clip.m4a"))
    }
}

// MARK: - Repeat Policy

extension LegacyDhikrAudioTests {

    func testCountsUpToTenRepeatInFull() throws {
        let category = try XCTUnwrap(try legacyCategories().first)
        let viewModel = makeViewModel(category: category)

        for count in [1, 3, 4, 7, 10] {
            XCTAssertEqual(viewModel.audioRepeats(for: dhikr(count: count, audio: "1.m4a")), count)
        }
    }

    func testCountsAboveTenPlayOnce() throws {
        let category = try XCTUnwrap(try legacyCategories().first)
        let viewModel = makeViewModel(category: category)

        for count in [11, 33, 100] {
            XCTAssertEqual(viewModel.audioRepeats(for: dhikr(count: count, audio: "1.m4a")), 1)
        }
    }

    func testZeroCountPlaysOnce() throws {
        let category = try XCTUnwrap(try legacyCategories().first)
        let viewModel = makeViewModel(category: category)

        XCTAssertEqual(viewModel.audioRepeats(for: dhikr(count: 0, audio: "1.m4a")), 1)
    }

    func testHundredCountOccurrencesKeepTheirCountAndPlayOnce() throws {
        let categories = try legacyCategories()
        let viewModel = makeViewModel(category: try XCTUnwrap(categories.first))
        let hundreds = categories.flatMap(\.adhkar).filter { Self.hundredCountIdentifiers.contains($0.id) }

        XCTAssertEqual(hundreds.count, 5)

        for dhikr in hundreds {
            XCTAssertEqual(dhikr.count, 100, "count was modified for \(dhikr.id)")
            XCTAssertEqual(viewModel.audioRepeats(for: dhikr), 1, "\(dhikr.id) would repeat 100 times")
        }
    }

    func testEveryLegacyOccurrenceRepeatsAtMostTenTimes() throws {
        let viewModel = makeViewModel(category: try XCTUnwrap(try legacyCategories().first))

        for dhikr in try legacyAdhkarWithAudio() {
            let repeats = viewModel.audioRepeats(for: dhikr)
            XCTAssertGreaterThanOrEqual(repeats, 1, "\(dhikr.id) would never play")
            XCTAssertLessThanOrEqual(repeats, 10, "\(dhikr.id) would repeat \(repeats) times")
        }
    }
}

// MARK: - Reader Behaviour

extension LegacyDhikrAudioTests {

    private func category(adhkar: [Dhikr]) -> DhikrCategory {
        DhikrCategory(id: "fixture_category",
                      titleAr: "فئة",
                      titleEn: "Category",
                      icon: "star",
                      adhkar: adhkar,
                      condition: nil,
                      section: "more")
    }

    func testTapToCountAdvancesWithoutResolvableAudio() {
        let viewModel = makeViewModel(category: category(adhkar: [dhikr(count: 3, audio: "no_such_clip.m4a"),
                                                                  dhikr(count: 2, audio: nil)]))
        viewModel.onAppear()

        XCTAssertFalse(viewModel.hasAudio)

        viewModel.onTap()
        viewModel.onTap()
        XCTAssertEqual(viewModel.currentIndex, 0)
        XCTAssertEqual(viewModel.currentTapCount, 2)

        viewModel.onTap()
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(viewModel.currentTapCount, 0)
        XCTAssertFalse(viewModel.isComplete)
    }

    func testAudioAvailabilityFollowsTheInstalledPack() throws {
        let source = try XCTUnwrap(LegacyDhikrAudioCatalog.source(forDhikrIdentifier: "evening_23"))
        try install(fileName: source.fileName, inPack: source.packKey)

        let evening = try XCTUnwrap(try legacyCategories().first { $0.id == "evening" })
        let viewModel = makeViewModel(category: evening)
        let installedIndex = try XCTUnwrap(viewModel.orderedAdhkar.firstIndex { $0.id == "evening_23" })

        viewModel.navigateToIndex(installedIndex)
        XCTAssertTrue(viewModel.hasAudio)
    }

    func testAudioAvailabilityIsFalseForUninstalledPacks() throws {
        let evening = try XCTUnwrap(try legacyCategories().first { $0.id == "evening" })
        let viewModel = makeViewModel(category: evening)
        let index = try XCTUnwrap(viewModel.orderedAdhkar.firstIndex { $0.id == "evening_23" })

        viewModel.navigateToIndex(index)
        XCTAssertFalse(viewModel.hasAudio)
    }

    func testNavigationResetsTapCountAndKeepsOrder() {
        let viewModel = makeViewModel(category: category(adhkar: [dhikr(count: 5, audio: nil),
                                                                  dhikr(count: 4, audio: nil)]))
        viewModel.onAppear()
        let ordered = viewModel.orderedAdhkar.map(\.id)

        viewModel.onTap()
        XCTAssertEqual(viewModel.currentTapCount, 1)

        viewModel.navigateToIndex(1)

        XCTAssertEqual(viewModel.currentTapCount, 0)
        XCTAssertEqual(viewModel.currentIndex, 1)
        XCTAssertEqual(viewModel.orderedAdhkar.map(\.id), ordered)
    }
}
