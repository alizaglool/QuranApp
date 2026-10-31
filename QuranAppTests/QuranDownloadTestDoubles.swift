//
//  QuranDownloadTestDoubles.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import Foundation
import Combine
@testable import QuranApp

// MARK: - Fixtures

enum QuranImagePackFixture {

    static func pack(juz: Int, sizeBytes: Int = 1_000_000) -> QuranImagePack {
        let firstPage = (juz - 1) * 20 + 1

        return QuranImagePack(juz: juz,
                              firstPage: firstPage,
                              lastPage: firstPage + 19,
                              imageCount: 20,
                              archiveSizeBytes: sizeBytes,
                              archiveSha256: String(format: "sha256-juz-%02d", juz),
                              archiveURL: "https://example.invalid/quran_images_juz_\(juz).zip")
    }

    static func packs(juzNumbers: [Int], sizeBytes: Int = 1_000_000) -> [QuranImagePack] {
        juzNumbers.map { pack(juz: $0, sizeBytes: sizeBytes) }
    }

    static func packs(sizesByJuz: [Int: Int]) -> [QuranImagePack] {
        sizesByJuz.keys.sorted().map { pack(juz: $0, sizeBytes: sizesByJuz[$0] ?? 0) }
    }

    static func manifest(packs: [QuranImagePack], bundledLastPage: Int = 20) -> QuranImageManifest {
        QuranImageManifest(schemaVersion: 1,
                           dataVersion: "tests",
                           totalPages: 604,
                           linesPerPage: 15,
                           bundledFirstPage: bundledLastPage > 0 ? 1 : 0,
                           bundledLastPage: bundledLastPage,
                           packs: packs)
    }

    static func packKey(forJuz juz: Int) -> String {
        String(format: "juz_%02d", juz)
    }

    static func packKeys(forJuzNumbers juzNumbers: [Int]) -> Set<String> {
        Set(juzNumbers.map(packKey(forJuz:)))
    }
}

// MARK: - Pack store double

final class QuranImagePackStoreDouble: ObservableObject, QuranImagePackProviding {

    @Published private(set) var states: [String: ContentDownloadState] = [:]
    @Published private(set) var waitingKeys: Set<String> = []

    var manifest: QuranImageManifest
    var bundledJuzNumbers: Set<Int>
    var currentKeys: Set<String> = []

    private(set) var downloadedJuzNumbers: [Int] = []
    private(set) var cancelledJuzNumbers: [Int] = []
    private(set) var cancelAllCount: Int = 0
    private(set) var refreshCount: Int = 0

    init(juzNumbers: [Int] = Array(1...4),
         sizeBytes: Int = 1_000_000,
         bundledJuzNumbers: Set<Int> = [1]) {
        manifest = QuranImagePackFixture.manifest(
            packs: QuranImagePackFixture.packs(juzNumbers: juzNumbers, sizeBytes: sizeBytes)
        )
        self.bundledJuzNumbers = bundledJuzNumbers
    }

    var downloadablePacks: [QuranImagePack] {
        manifest.sortedPacks.filter { !bundledJuzNumbers.contains($0.juz) }
    }

    var statePublisher: AnyPublisher<[String: ContentDownloadState], Never> {
        $states.eraseToAnyPublisher()
    }

    var waitingKeysPublisher: AnyPublisher<Set<String>, Never> {
        $waitingKeys.eraseToAnyPublisher()
    }

    func isBundled(pack: QuranImagePack) -> Bool {
        bundledJuzNumbers.contains(pack.juz)
    }

    func isCurrent(_ pack: QuranImagePack) -> Bool {
        currentKeys.contains(pack.key)
    }

    func download(juz: Int) {
        downloadedJuzNumbers.append(juz)
        simulate(juz: juz, state: .downloading(progress: 0))
    }

    func cancel(juz: Int) {
        cancelledJuzNumbers.append(juz)
        simulate(juz: juz, state: .notDownloaded)
    }

    func cancelAll() {
        cancelAllCount += 1

        let busyKeys = states.filter { $0.value.isBusy }.map(\.key)
        var updated = states

        for key in busyKeys {
            updated[key] = .notDownloaded
        }

        states = updated
        waitingKeys = []
    }

    @discardableResult
    func refreshCatalog() async -> QuranImageManifest {
        refreshCount += 1
        return manifest
    }

    // MARK: - Simulation

    func simulate(juz: Int, state: ContentDownloadState) {
        var updated = states
        updated[QuranImagePackFixture.packKey(forJuz: juz)] = state
        states = updated
    }

    func complete(juz: Int) {
        currentKeys.insert(QuranImagePackFixture.packKey(forJuz: juz))
        simulate(juz: juz, state: .downloaded)
    }

    func complete(juzNumbers: [Int]) {
        for juz in juzNumbers {
            complete(juz: juz)
        }
    }

    func fail(juz: Int, reason: ContentDownloadFailure) {
        simulate(juz: juz, state: .failed(reason))
    }

    func setWaiting(juzNumbers: [Int]) {
        waitingKeys = QuranImagePackFixture.packKeys(forJuzNumbers: juzNumbers)
    }
}

// MARK: - Coordinator double

final class QuranPackDownloadsCoordinatorDouble: QuranPackDownloadsCoordinating {

    private(set) var didCoordinateBack: Bool = false

    func coordinateBack() {
        didCoordinateBack = true
    }
}

// MARK: - Main queue settling

@MainActor
func settleDownloadUpdates() async {
    for _ in 0..<3 {
        await Task.yield()

        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}

// MARK: - Pack geometry fixtures

extension QuranImagePackFixture {

    static let linesPerPage = 15

    static func detailedPack(juz: Int,
                             firstPage: Int,
                             pageCount: Int,
                             sizeBytes: Int = 1_000,
                             sha256: String = String(repeating: "a", count: 64)) -> QuranImagePack {
        QuranImagePack(juz: juz,
                       firstPage: firstPage,
                       lastPage: firstPage + pageCount - 1,
                       imageCount: pageCount * linesPerPage,
                       archiveSizeBytes: sizeBytes,
                       archiveSha256: sha256,
                       archiveURL: "https://example.invalid/quran_images_juz_\(juz).zip")
    }
}

// MARK: - Installed content fixtures

enum QuranPackContentFixture {

    static func makeDirectory(_ name: String = UUID().uuidString) -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quran-download-tests", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)

        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @discardableResult
    static func writePages(_ pages: ClosedRange<Int>,
                           lines: Int = QuranImagePackFixture.linesPerPage,
                           in directory: URL) -> URL {
        for page in pages {
            let pageDirectory = directory.appendingPathComponent("\(page)", isDirectory: true)
            try? FileManager.default.createDirectory(at: pageDirectory, withIntermediateDirectories: true)

            for line in 1...max(1, lines) {
                let file = pageDirectory.appendingPathComponent("\(line).png")
                try? Data("page-\(page)-line-\(line)".utf8).write(to: file)
            }
        }
        return directory
    }

    static func removeLine(_ line: Int, onPage page: Int, in directory: URL) {
        let file = directory
            .appendingPathComponent("\(page)", isDirectory: true)
            .appendingPathComponent("\(line).png")

        try? FileManager.default.removeItem(at: file)
    }

    static func removePage(_ page: Int, in directory: URL) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent("\(page)", isDirectory: true))
    }

    static func blankPage(_ page: Int, in directory: URL) {
        removePage(page, in: directory)

        try? FileManager.default.createDirectory(
            at: directory.appendingPathComponent("\(page)", isDirectory: true),
            withIntermediateDirectories: true
        )
    }

    static func pageImageCount(in directory: URL) -> Int {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else { return 0 }

        return entries.compactMap { Int($0) }.reduce(0) { total, page in
            let pageDirectory = directory.appendingPathComponent("\(page)", isDirectory: true)
            let lines = (try? FileManager.default.contentsOfDirectory(atPath: pageDirectory.path)) ?? []
            return total + lines.filter { $0.hasSuffix(".png") }.count
        }
    }

    @discardableResult
    static func writeOpaqueArchive(bytes: Int, at url: URL) -> String {
        let payload = Data((0..<bytes).map { UInt8($0 % 251) })
        try? payload.write(to: url, options: .atomic)
        return (try? AthkarArchive.sha256(ofFileAt: url)) ?? ""
    }
}

// MARK: - Stored zip fixtures

enum QuranStoredArchiveFixture {

    static func write(pages: ClosedRange<Int>, lines: Int, to url: URL) throws {
        var files: [(path: String, contents: Data)] = []

        for page in pages {
            for line in 1...max(1, lines) {
                files.append((path: "\(page)/\(line).png", contents: Data("page-\(page)-line-\(line)".utf8)))
            }
        }

        try write(files: files, to: url)
    }

    static func write(files: [(path: String, contents: Data)], to url: URL) throws {
        var payload = Data()
        var directory = Data()
        var offsets: [Int] = []

        for file in files {
            offsets.append(payload.count)

            let name = Data(file.path.utf8)
            let size = UInt32(file.contents.count)

            payload.append(littleEndian: UInt32(0x0403_4b50))
            payload.append(littleEndian: UInt16(20))
            payload.append(littleEndian: UInt16(0))
            payload.append(littleEndian: UInt16(0))
            payload.append(littleEndian: UInt16(0))
            payload.append(littleEndian: UInt16(0))
            payload.append(littleEndian: UInt32(0))
            payload.append(littleEndian: size)
            payload.append(littleEndian: size)
            payload.append(littleEndian: UInt16(name.count))
            payload.append(littleEndian: UInt16(0))
            payload.append(name)
            payload.append(file.contents)
        }

        for (index, file) in files.enumerated() {
            let name = Data(file.path.utf8)
            let size = UInt32(file.contents.count)

            directory.append(littleEndian: UInt32(0x0201_4b50))
            directory.append(littleEndian: UInt16(20))
            directory.append(littleEndian: UInt16(20))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt32(0))
            directory.append(littleEndian: size)
            directory.append(littleEndian: size)
            directory.append(littleEndian: UInt16(name.count))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt16(0))
            directory.append(littleEndian: UInt32(0))
            directory.append(littleEndian: UInt32(offsets[index]))
            directory.append(name)
        }

        let directoryOffset = payload.count
        payload.append(directory)

        payload.append(littleEndian: UInt32(0x0605_4b50))
        payload.append(littleEndian: UInt16(0))
        payload.append(littleEndian: UInt16(0))
        payload.append(littleEndian: UInt16(files.count))
        payload.append(littleEndian: UInt16(files.count))
        payload.append(littleEndian: UInt32(directory.count))
        payload.append(littleEndian: UInt32(directoryOffset))
        payload.append(littleEndian: UInt16(0))

        try payload.write(to: url, options: .atomic)
    }
}

private extension Data {

    mutating func append(littleEndian value: UInt16) {
        append(contentsOf: [UInt8(value & 0xFF), UInt8((value >> 8) & 0xFF)])
    }

    mutating func append(littleEndian value: UInt32) {
        append(contentsOf: [UInt8(value & 0xFF),
                            UInt8((value >> 8) & 0xFF),
                            UInt8((value >> 16) & 0xFF),
                            UInt8((value >> 24) & 0xFF)])
    }
}
