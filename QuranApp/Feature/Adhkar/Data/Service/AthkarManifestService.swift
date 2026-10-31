//
//  AthkarManifestService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Core

// MARK: - Source

enum AthkarManifestSource {
    case bundled
    case cached
    case remote
}

// MARK: - Service

final class AthkarManifestService {

    static let shared = AthkarManifestService()

    static let supportedSchemaVersion = 1
    static let bundledResourceName = "zikr_athkar_manifest"
    static let bundledDirectory = "Athkar"
    static let releaseURL = URL(string: "https://github.com/alizaglool/quran-athkar-data/releases/latest/download/zikr_athkar_manifest.json")!

    private(set) var source: AthkarManifestSource = .bundled

    private let session: URLSession
    private let fileManager: FileManager
    private let bundle: Bundle
    private let cacheURL: URL

    private let lock = NSLock()
    private var cached: AthkarManifest?

    init(session: URLSession = .shared,
         fileManager: FileManager = .default,
         bundle: Bundle = .main,
         cacheDirectory: URL? = nil) {
        self.session = session
        self.fileManager = fileManager
        self.bundle = bundle
        let directory = cacheDirectory
            ?? fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.cacheURL = directory.appendingPathComponent("athkar_manifest.json")
    }

    // MARK: - Reading

    func load() -> AthkarManifest {
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }

        if let data = try? Data(contentsOf: cacheURL),
           let decoded = try? decode(data) {
            cached = decoded
            source = .cached
            return decoded
        }

        let bundled = loadBundled()
        cached = bundled
        source = .bundled
        return bundled
    }

    @discardableResult
    func refresh() async -> AthkarManifest {
        guard let data = try? await fetch(),
              let decoded = try? decode(data),
              !decoded.isEmpty else { return load() }

        try? data.write(to: cacheURL, options: .atomic)
        adopt(decoded)
        return decoded
    }

    func invalidate() {
        lock.lock(); defer { lock.unlock() }
        cached = nil
    }

    // MARK: - Queries

    func pack(key: String) -> AthkarPack? {
        load().pack(key: key)
    }

    func readablePacks() -> [AthkarPack] {
        load().packs(ofKind: [.reader, .list])
    }

    func packs(in group: AthkarPackGroup) -> [AthkarPack] {
        readablePacks().filter { $0.group == group }
    }

    func groups() -> [AthkarPackGroup] {
        let available = Set(readablePacks().map(\.group))
        return AthkarPackGroup.allCases.filter { available.contains($0) }
    }

    // MARK: - Decoding

    private func decode(_ data: Data) throws -> AthkarManifest {
        let manifest = try JSONDecoder().decode(AthkarManifest.self, from: data)
        guard manifest.schemaVersion <= Self.supportedSchemaVersion else {
            throw AthkarDataError.unsupportedSchema(manifest.schemaVersion)
        }
        return manifest
    }

    private func loadBundled() -> AthkarManifest {
        guard let url = bundledURL(),
              let data = try? Data(contentsOf: url),
              let manifest = try? decode(data) else { return .empty }
        return manifest
    }

    private func bundledURL() -> URL? {
        bundle.url(forResource: Self.bundledResourceName,
                   withExtension: "json",
                   subdirectory: Self.bundledDirectory)
            ?? bundle.url(forResource: Self.bundledResourceName, withExtension: "json")
    }

    private func adopt(_ manifest: AthkarManifest) {
        lock.lock(); defer { lock.unlock() }
        cached = manifest
        source = .remote
    }

    // MARK: - Fetching

    private func fetch() async throws -> Data {
        var request = URLRequest(url: Self.releaseURL)
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw AthkarDataError.missingResource(Self.bundledResourceName)
        }
        return data
    }
}
