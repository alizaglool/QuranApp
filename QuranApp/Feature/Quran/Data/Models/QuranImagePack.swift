//
//  QuranImagePack.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation
import Core

// MARK: - Error

enum QuranImageDataError: Error {
    case unsupportedSchema(Int)
    case missingResource(String)
}

// MARK: - Error · download failure mapping

extension QuranImageDataError: ContentDownloadFailureConvertible {

    var contentDownloadFailure: ContentDownloadFailure {
        switch self {
        case .unsupportedSchema: return .unavailable
        case .missingResource:   return .unavailable
        }
    }
}

// MARK: - Pack

struct QuranImagePack: Hashable {
    let juz: Int
    let firstPage: Int
    let lastPage: Int
    let imageCount: Int
    let archiveSizeBytes: Int
    let archiveSha256: String
    let archiveURL: String

    var key: String { String(format: "juz_%02d", juz) }

    var archiveFileName: String { "quran_images_\(key)" }

    var pageRange: ClosedRange<Int> { firstPage...max(firstPage, lastPage) }

    var pageCount: Int { pageRange.count }

    var archiveRemoteURL: URL? { URL(string: archiveURL) }

    var archiveSizeLabel: String {
        let size = ByteCountFormatter.string(fromByteCount: Int64(archiveSizeBytes), countStyle: .file)
        return "\u{2066}\(size)\u{2069}"
    }

    func contains(page: Int) -> Bool { pageRange.contains(page) }
}

// MARK: - Pack · decoding

extension QuranImagePack: Decodable {

    private enum CodingKeys: String, CodingKey {
        case juz, firstPage, lastPage, imageCount, size, sha256, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        juz = try container.decode(Int.self, forKey: .juz)
        firstPage = try container.decode(Int.self, forKey: .firstPage)
        lastPage = try container.decode(Int.self, forKey: .lastPage)
        imageCount = try container.decodeIfPresent(Int.self, forKey: .imageCount) ?? 0
        archiveSizeBytes = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
        archiveSha256 = try container.decodeIfPresent(String.self, forKey: .sha256) ?? ""
        archiveURL = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    }
}

// MARK: - Manifest

struct QuranImageManifest: Hashable {

    static let defaultTotalPages = 604
    static let defaultLinesPerPage = 15

    let schemaVersion: Int
    let dataVersion: String
    let totalPages: Int
    let linesPerPage: Int
    let bundledFirstPage: Int
    let bundledLastPage: Int
    let packs: [QuranImagePack]

    static let empty = QuranImageManifest(schemaVersion: 0,
                                          dataVersion: "",
                                          totalPages: defaultTotalPages,
                                          linesPerPage: defaultLinesPerPage,
                                          bundledFirstPage: 0,
                                          bundledLastPage: 0,
                                          packs: [])

    var isEmpty: Bool { packs.isEmpty }

    var sortedPacks: [QuranImagePack] { packs.sorted { $0.juz < $1.juz } }

    var totalSizeBytes: Int { packs.reduce(0) { $0 + $1.archiveSizeBytes } }

    var totalSizeLabel: String {
        let size = ByteCountFormatter.string(fromByteCount: Int64(totalSizeBytes), countStyle: .file)
        return "\u{2066}\(size)\u{2069}"
    }

    var bundledPageRange: ClosedRange<Int>? {
        guard bundledFirstPage > 0, bundledLastPage >= bundledFirstPage else { return nil }
        return bundledFirstPage...bundledLastPage
    }

    func isBundled(page: Int) -> Bool {
        bundledPageRange?.contains(page) ?? false
    }

    func isFullyBundled(_ pack: QuranImagePack) -> Bool {
        guard let range = bundledPageRange else { return false }
        return pack.firstPage >= range.lowerBound && pack.lastPage <= range.upperBound
    }

    func pack(juz: Int) -> QuranImagePack? {
        packs.first { $0.juz == juz }
    }

    func pack(forPage page: Int) -> QuranImagePack? {
        packs.first { $0.contains(page: page) }
    }

    func packs(forPages pages: [Int]) -> [QuranImagePack] {
        var seen = Set<Int>()
        var result: [QuranImagePack] = []
        for page in pages {
            guard let pack = pack(forPage: page), seen.insert(pack.juz).inserted else { continue }
            result.append(pack)
        }
        return result.sorted { $0.juz < $1.juz }
    }
}

// MARK: - Manifest · decoding

extension QuranImageManifest: Decodable {

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, dataVersion, totalPages, linesPerPage
        case bundledFirstPage, bundledLastPage, packs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0
        dataVersion = try container.decodeIfPresent(String.self, forKey: .dataVersion) ?? ""
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? Self.defaultTotalPages
        linesPerPage = try container.decodeIfPresent(Int.self, forKey: .linesPerPage) ?? Self.defaultLinesPerPage
        bundledFirstPage = try container.decodeIfPresent(Int.self, forKey: .bundledFirstPage) ?? 0
        bundledLastPage = try container.decodeIfPresent(Int.self, forKey: .bundledLastPage) ?? 0
        packs = try container
            .decodeIfPresent([QuranImageLossyPack].self, forKey: .packs)?
            .compactMap(\.pack) ?? []
    }
}

// MARK: - Lossy pack

private struct QuranImageLossyPack: Decodable {
    let pack: QuranImagePack?

    init(from decoder: Decoder) throws {
        pack = try? QuranImagePack(from: decoder)
    }
}
