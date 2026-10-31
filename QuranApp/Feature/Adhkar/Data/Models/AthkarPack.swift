//
//  AthkarPack.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Core

// MARK: - Error

enum AthkarDataError: LocalizedError {
    case unsupportedGroup(String)
    case unsupportedKind(String)
    case unsupportedSchema(Int)
    case missingResource(String)
    case checksumMismatch(String)
    case corruptArchive(String)
    case insufficientSpace(Int64)

    var errorDescription: String? {
        switch self {
        case let .unsupportedGroup(value):   return "Unsupported athkar group: \(value)"
        case let .unsupportedKind(value):    return "Unsupported athkar kind: \(value)"
        case let .unsupportedSchema(value):  return "Unsupported athkar schema: \(value)"
        case let .missingResource(value):    return "Missing athkar resource: \(value)"
        case let .checksumMismatch(value):   return "Checksum mismatch for athkar pack: \(value)"
        case let .corruptArchive(value):     return "Corrupt athkar archive: \(value)"
        case let .insufficientSpace(value):  return "Not enough space for athkar audio: \(value) bytes"
        }
    }
}

// MARK: - Error · download failure mapping

extension AthkarDataError: ContentDownloadFailureConvertible {

    var contentDownloadFailure: ContentDownloadFailure {
        switch self {
        case .checksumMismatch, .corruptArchive: return .corrupt
        case .insufficientSpace:                 return .noSpace
        default:                                 return .transfer
        }
    }
}

// MARK: - Kind

enum AthkarPackKind: String, Codable, Hashable, CaseIterable {
    case reader
    case list
    case book
    case guide
    case sick
    case lovedOnes
    case ramadan
    case quiz
}

// MARK: - Group

enum AthkarPackGroup: String, Codable, Hashable, CaseIterable {
    case daily
    case duaa
    case worship
    case healing
    case seasons
    case lovedOnes = "loved_ones"
    case kids
}

// MARK: - Mood

enum AthkarPackMood: String, Codable, Hashable, CaseIterable {
    case morning
    case evening
    case sleep
    case general
}

// MARK: - Pack

struct AthkarPack: Identifiable, Hashable {
    let key: String
    let group: AthkarPackGroup
    let kind: AthkarPackKind
    let mood: AthkarPackMood
    let sort: Int
    let nameAr: String
    let nameEn: String
    let itemCount: Int
    let hasAudio: Bool
    let archiveSizeBytes: Int
    let archiveSha256: String
    let archiveURL: String

    var id: String { key }

    var name: String {
        LocalizationManager.shared.currentLanguage == .Arabic ? nameAr : nameEn
    }

    var fileName: String { "zikr_athkar_\(key)" }

    var archiveRemoteURL: URL? { URL(string: archiveURL) }

    var archiveSizeLabel: String {
        ByteCountFormatter.string(fromByteCount: Int64(archiveSizeBytes), countStyle: .file)
    }
}

// MARK: - Pack · decoding

extension AthkarPack: Decodable {

    private enum CodingKeys: String, CodingKey {
        case key, group, kind, mood, sort, nameAr, nameEn
        case itemCount, hasAudio, size, sha256, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        key = try container.decode(String.self, forKey: .key)

        let rawGroup = try container.decode(String.self, forKey: .group)
        guard let group = AthkarPackGroup(rawValue: rawGroup) else {
            throw AthkarDataError.unsupportedGroup(rawGroup)
        }
        self.group = group

        let rawKind = try container.decode(String.self, forKey: .kind)
        guard let kind = AthkarPackKind(rawValue: rawKind) else {
            throw AthkarDataError.unsupportedKind(rawKind)
        }
        self.kind = kind

        let rawMood = try container.decodeIfPresent(String.self, forKey: .mood) ?? ""
        mood = AthkarPackMood(rawValue: rawMood) ?? .general

        sort = try container.decodeIfPresent(Int.self, forKey: .sort) ?? 0
        nameAr = try container.decodeIfPresent(String.self, forKey: .nameAr) ?? ""
        nameEn = try container.decodeIfPresent(String.self, forKey: .nameEn) ?? ""
        itemCount = try container.decodeIfPresent(Int.self, forKey: .itemCount) ?? 0
        hasAudio = try container.decodeIfPresent(Bool.self, forKey: .hasAudio) ?? false
        archiveSizeBytes = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
        archiveSha256 = try container.decodeIfPresent(String.self, forKey: .sha256) ?? ""
        archiveURL = try container.decodeIfPresent(String.self, forKey: .url) ?? ""
    }
}

// MARK: - Manifest

struct AthkarManifest: Hashable {
    let schemaVersion: Int
    let dataVersion: String
    let packs: [AthkarPack]

    static let empty = AthkarManifest(schemaVersion: 0, dataVersion: "", packs: [])

    var isEmpty: Bool { packs.isEmpty }

    func packs(ofKind kinds: Set<AthkarPackKind>) -> [AthkarPack] {
        packs.filter { kinds.contains($0.kind) }.sorted { $0.sort < $1.sort }
    }

    func pack(key: String) -> AthkarPack? {
        packs.first { $0.key == key }
    }
}

// MARK: - Manifest · decoding

extension AthkarManifest: Decodable {

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, dataVersion, packs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0
        dataVersion = try container.decodeIfPresent(String.self, forKey: .dataVersion) ?? ""
        packs = try container
            .decodeIfPresent([AthkarLossyPack].self, forKey: .packs)?
            .compactMap(\.pack) ?? []
    }
}

// MARK: - Lossy pack

private struct AthkarLossyPack: Decodable {
    let pack: AthkarPack?

    init(from decoder: Decoder) throws {
        pack = try? AthkarPack(from: decoder)
    }
}
