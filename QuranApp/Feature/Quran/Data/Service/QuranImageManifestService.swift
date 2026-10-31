//
//  QuranImageManifestService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation

// MARK: - Source

enum QuranImageManifestSource {
    case bundled
    case cached
    case remote
}

// MARK: - Service

final class QuranImageManifestService {

    static let shared = QuranImageManifestService()

    static let supportedSchemaVersion = 1
    static let bundledResourceName = "quran_images_manifest"
    static let releaseURL = URL(string: "https://github.com/alizaglool/quran-athkar-data/releases/latest/download/quran_images_manifest.json")!

    private(set) var source: QuranImageManifestSource = .bundled

    private let session: URLSession
    private let fileManager: FileManager
    private let bundle: Bundle
    private let cacheURL: URL

    private let lock = NSLock()
    private var cached: QuranImageManifest?

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
        self.cacheURL = directory.appendingPathComponent("quran_images_manifest.json")
    }

    // MARK: - Reading

    func load() -> QuranImageManifest {
        lock.lock(); defer { lock.unlock() }
        if let cached { return cached }

        if let data = try? Data(contentsOf: cacheURL),
           let decoded = try? decode(data),
           !decoded.isEmpty {
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
    func refresh() async -> QuranImageManifest {
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

    func packs() -> [QuranImagePack] {
        load().sortedPacks
    }

    func pack(juz: Int) -> QuranImagePack? {
        load().pack(juz: juz)
    }

    func pack(forPage page: Int) -> QuranImagePack? {
        load().pack(forPage: page)
    }

    func isBundled(page: Int) -> Bool {
        load().isBundled(page: page)
    }

    // MARK: - Decoding

    private func decode(_ data: Data) throws -> QuranImageManifest {
        let manifest = try JSONDecoder().decode(QuranImageManifest.self, from: data)
        guard manifest.schemaVersion <= Self.supportedSchemaVersion else {
            throw QuranImageDataError.unsupportedSchema(manifest.schemaVersion)
        }
        return manifest
    }

    private func loadBundled() -> QuranImageManifest {
        guard let url = bundle.url(forResource: Self.bundledResourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? decode(data) else { return .empty }
        return manifest
    }

    private func adopt(_ manifest: QuranImageManifest) {
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
            throw QuranImageDataError.missingResource(Self.bundledResourceName)
        }
        return data
    }
}
