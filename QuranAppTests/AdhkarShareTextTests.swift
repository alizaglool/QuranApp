//
//  AdhkarShareTextTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class AdhkarShareTextTests: XCTestCase {

    private var root: URL!
    private var viewModel: AdhkarReadingViewModel!
    private var allAdhkar: [Dhikr] = []

    override func setUpWithError() throws {
        try super.setUpWithError()

        root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("adhkar-share-text-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let url = try XCTUnwrap(Bundle.main.url(forResource: "adhkar", withExtension: "json"))
        let decoded = try JSONDecoder().decode([DhikrCategory].self, from: try Data(contentsOf: url))
        allAdhkar = decoded.flatMap(\.adhkar)
        XCTAssertFalse(allAdhkar.isEmpty)

        let downloads = AthkarAudioDownloadManager(rootDirectory: root,
                                                   expectedAudioFileNames: { _ in [] },
                                                   publishedArchiveChecksum: { _ in nil })
        viewModel = AdhkarReadingViewModel(coordinator: AdhkarCoordinatorDouble(),
                                           category: DhikrCategory(id: "share_text_fixture",
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

    // MARK: - Helpers

    fileprivate func dhikr(id: String) throws -> Dhikr {
        try XCTUnwrap(allAdhkar.first { $0.id == id }, "missing legacy dhikr \(id)")
    }

    fileprivate func displayedBlocks(of dhikr: Dhikr) -> [String] {
        var blocks = viewModel.displaySegments(for: dhikr).compactMap { segment -> String? in
            guard let text = segment.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return nil }
            return text
        }
        if let label = dhikr.repeatLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
            blocks.append(label)
        }
        return blocks
    }

    fileprivate func previousShareText(for dhikr: Dhikr) -> String {
        var parts: [String] = [dhikr.textAr]
        if let description = dhikr.description, !description.isEmpty { parts.append(description) }
        if let reference = dhikr.title, !reference.isEmpty { parts.append(reference) }
        return parts.joined(separator: "\n\n")
    }

    fileprivate func occurrences(of needle: String, in haystack: String) -> Int {
        guard !needle.isEmpty else { return 0 }
        var total = 0
        var cursor = haystack.startIndex
        while let found = haystack.range(of: needle, range: cursor..<haystack.endIndex) {
            total += 1
            cursor = found.upperBound
        }
        return total
    }
}

// MARK: - Named Regression Items

extension AdhkarShareTextTests {

    func testTravelDuaSharesEveryDisplayedSegment() throws {
        try assertShareTextCoversEveryDisplayedBlock(forID: "prophets_duas_89")
    }

    func testQunutDuaSharesEveryDisplayedSegment() throws {
        try assertShareTextCoversEveryDisplayedBlock(forID: "prayer_adhkar_5")
    }

    func testTashahhudSharesEveryDisplayedSegment() throws {
        try assertShareTextCoversEveryDisplayedBlock(forID: "prayer_adhkar_7")
    }

    func testNamedItemsShareExactlyWhatTheReaderDisplays() throws {
        for id in ["prophets_duas_89", "prayer_adhkar_5", "prayer_adhkar_7"] {
            let item = try dhikr(id: id)

            XCTAssertEqual(viewModel.shareText(for: item),
                           displayedBlocks(of: item).joined(separator: "\n\n"),
                           "\(id) share text no longer mirrors the reader")
        }
    }

    func testNamedItemsShareEverySegmentTheOldBuilderFlattened() throws {
        for id in ["prophets_duas_89", "prayer_adhkar_5", "prayer_adhkar_7"] {
            let item = try dhikr(id: id)

            XCTAssertGreaterThan(displayedBlocks(of: item).count, 2,
                                 "\(id) is expected to display several ordered parts")
            XCTAssertNotEqual(viewModel.shareText(for: item), previousShareText(for: item))
        }
    }

    func testNamedItemsDoNotRepeatTheirReferenceTitle() throws {
        for id in ["prophets_duas_89", "prayer_adhkar_5", "prayer_adhkar_7"] {
            let item = try dhikr(id: id)
            let reference = try XCTUnwrap(item.title?.trimmingCharacters(in: .whitespacesAndNewlines))
            let body = displayedBlocks(of: item).joined(separator: "\n\n")
            let shared = viewModel.shareText(for: item)

            XCTAssertEqual(occurrences(of: reference, in: shared),
                           occurrences(of: reference, in: body),
                           "\(id) appends a reference title that the reader already displays")
        }
    }

    func testWitrDhikrRecoversSegmentsTheOldShareTextDropped() throws {
        for id in ["qiyam_1", "qiyam_2", "qiyam_3"] {
            let item = try dhikr(id: id)
            let previous = previousShareText(for: item)
            let shared = viewModel.shareText(for: item)

            let recovered = displayedBlocks(of: item).filter { !previous.contains($0) }
            XCTAssertFalse(recovered.isEmpty, "\(id) was expected to be missing content before the fix")

            for block in recovered {
                XCTAssertTrue(shared.contains(block), "\(id) still omits a displayed block")
            }
        }
    }

    func testWitrDhikrSharesReaderContentPlusItsReference() throws {
        let item = try dhikr(id: "qiyam_3")
        let reference = try XCTUnwrap(item.title?.trimmingCharacters(in: .whitespacesAndNewlines))
        let expected = displayedBlocks(of: item).joined(separator: "\n\n") + "\n\n" + reference

        XCTAssertEqual(viewModel.shareText(for: item), expected)
    }

    func testWitrDhikrKeepsReferenceThatAddsInformation() throws {
        let item = try dhikr(id: "qiyam_3")
        let reference = try XCTUnwrap(item.title?.trimmingCharacters(in: .whitespacesAndNewlines))

        XCTAssertFalse(displayedBlocks(of: item).contains { $0.contains(reference) })
        XCTAssertTrue(viewModel.shareText(for: item).contains(reference))
    }

    func testWitrDhikrSharesItsRepeatLabel() throws {
        let item = try dhikr(id: "qiyam_3")
        let label = try XCTUnwrap(item.repeatLabel?.trimmingCharacters(in: .whitespacesAndNewlines))

        XCTAssertTrue(viewModel.shareText(for: item).contains(label))
    }

    private func assertShareTextCoversEveryDisplayedBlock(forID id: String,
                                                          file: StaticString = #filePath,
                                                          line: UInt = #line) throws {
        let item = try dhikr(id: id)
        let shared = viewModel.shareText(for: item)

        for block in displayedBlocks(of: item) {
            XCTAssertTrue(shared.contains(block), "\(id) share text omits a displayed block", file: file, line: line)
        }
    }
}

// MARK: - Whole Catalogue Invariants

extension AdhkarShareTextTests {

    func testShareTextCoversEveryDisplayedBlockForEveryDhikr() {
        for item in allAdhkar {
            let shared = viewModel.shareText(for: item)
            for block in displayedBlocks(of: item) {
                XCTAssertTrue(shared.contains(block), "\(item.id) share text omits a displayed block")
            }
        }
    }

    func testShareTextPreservesDisplayedBlockOrderForEveryDhikr() {
        for item in allAdhkar {
            let shared = viewModel.shareText(for: item)
            var cursor = shared.startIndex

            for block in displayedBlocks(of: item) {
                guard let found = shared.range(of: block, range: cursor..<shared.endIndex) else {
                    XCTFail("\(item.id) share text reorders or omits a displayed block")
                    break
                }
                cursor = found.upperBound
            }
        }
    }

    func testShareTextAddsNothingBeyondOneCopyOfEachPart() {
        for item in allAdhkar {
            let shared = viewModel.shareText(for: item)
            let blocks = displayedBlocks(of: item)
            let reference = item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let budget = blocks.reduce(0) { $0 + $1.count }
                + reference.count
                + 2 * max(blocks.count, 1)

            XCTAssertLessThanOrEqual(shared.count, budget, "\(item.id) share text duplicates content")
        }
    }

    func testShareTextNeverEmitsBlankBlocksForRuleDividers() {
        for item in allAdhkar {
            let shared = viewModel.shareText(for: item)

            XCTAssertFalse(shared.contains("\n\n\n"), "\(item.id) share text contains a blank block")
            XCTAssertEqual(shared, shared.trimmingCharacters(in: .whitespacesAndNewlines),
                           "\(item.id) share text has padding at an edge")
        }
    }

    func testShareTextDropsRedundantTextArAndDescription() {
        var deduplicated = 0

        for item in allAdhkar where item.segments?.isEmpty == false {
            let shared = viewModel.shareText(for: item)
            let description = item.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !description.isEmpty,
                  !displayedBlocks(of: item).contains(where: { $0.contains(description) }) else { continue }
            XCTAssertFalse(shared.contains(description),
                           "\(item.id) still appends a description the reader does not display")
            deduplicated += 1
        }

        XCTAssertGreaterThan(deduplicated, 0)
    }

    func testShareTextIsNeverEmptyForDisplayableDhikr() {
        for item in allAdhkar where !displayedBlocks(of: item).isEmpty {
            XCTAssertFalse(viewModel.shareText(for: item).isEmpty, "\(item.id) shares nothing")
        }
    }
}
