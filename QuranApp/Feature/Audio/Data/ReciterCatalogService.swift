//
//  ReciterCatalogService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 11/10/2026
//

import Foundation
import os

// MARK: - ReciterCatalogService

final class ReciterCatalogService {

    static let shared = ReciterCatalogService()

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.Quran.wird",
        category: "ReciterCatalog"
    )

    private static let documentName = "reciters.json"
    private static let seedResourceName = "reciters"
    private static let cacheFileName = "remote-reciters.json"

    private let cacheTTL: TimeInterval = 3600
    private let negativeTTL: TimeInterval = 300

    private let cacheLock = NSLock()
    private var cached: CachedCatalog?
    private var didReadDisk = false
    private var lastFailureAt: Date?
    private var inFlight: Task<[ReciterInfo], Error>?

    private let ioQueue = DispatchQueue(label: "com.wird.recitercatalog.io", qos: .utility)

    private let cacheFileURL: URL? = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first?
        .appending(path: ReciterCatalogService.cacheFileName)

    private init() {}

    // MARK: - Synchronous Read

    func currentReciters() -> [ReciterInfo] {
        if let entry = currentCache(), !entry.reciters.isEmpty {
            return entry.reciters
        }
        return loadSeed() ?? []
    }

    func currentFeatured() -> [FeaturedReciter] {
        if let entry = currentCache(), !entry.featured.isEmpty {
            return entry.featured
        }
        return seedCatalog()?.featured ?? []
    }

    // MARK: - Refresh

    @discardableResult
    func refresh() async throws -> [ReciterInfo] {
        if let fresh = cachedReciters(maxAge: cacheTTL) { return fresh }

        if isInsideNegativeWindow() {
            Self.log.info("Recent failure still inside the negative window — skipping the network")
            return try fallback(after: ReciterCatalogError.noDataAvailable, recordFailure: false)
        }

        guard let base = AppConfig.remoteConfigBaseURL else {
            Self.log.error("Remote config base URL is not configured")
            return try fallback(after: ReciterCatalogError.missingBaseURL)
        }

        let url = base.appending(path: Self.documentName)

        let attempt = sharedAttempt {
            Task.detached(priority: .userInitiated) { [self] () -> [ReciterInfo] in
                defer { clearInFlight() }
                do {
                    return try await load(from: url)
                } catch {
                    return try fallback(after: error)
                }
            }
        }

        return try await attempt.value
    }

    // MARK: - Networking

    private func load(from url: URL) async throws -> [ReciterInfo] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let etag = currentCache()?.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            Self.log.error("Reciter catalog request failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw ReciterCatalogError.noDataAvailable
        }

        switch http.statusCode {
        case 200:
            let catalog = try decodeCatalog(from: data)
            let reciters = catalog.reciters.map { $0.reciterInfo }
            store(CachedCatalog(
                reciters: reciters,
                featured: catalog.featured,
                etag: http.value(forHTTPHeaderField: "Etag"),
                fetchedAt: Date()
            ))
            return reciters

        case 304:
            guard let entry = currentCache() else { throw ReciterCatalogError.noDataAvailable }
            store(CachedCatalog(
                reciters: entry.reciters,
                featured: entry.featured,
                etag: entry.etag,
                fetchedAt: Date()
            ))
            return entry.reciters

        default:
            Self.log.error("Reciter catalog returned HTTP \(http.statusCode, privacy: .public)")
            throw ReciterCatalogError.badStatus(http.statusCode)
        }
    }

    // MARK: - Decoding

    private func decodeCatalog(from data: Data) throws -> ReciterCatalog {
        guard let catalog = try? JSONDecoder().decode(ReciterCatalog.self, from: data) else {
            Self.log.error("Reciter catalog payload could not be decoded")
            throw ReciterCatalogError.decodingFailed
        }
        guard !catalog.reciters.isEmpty else {
            Self.log.error("Reciter catalog held no usable reciters")
            throw ReciterCatalogError.decodingFailed
        }
        return catalog
    }

    // MARK: - Fallback

    private func fallback(after error: Error, recordFailure: Bool = true) throws -> [ReciterInfo] {
        if recordFailure {
            cacheLock.lock()
            lastFailureAt = Date()
            cacheLock.unlock()
        }

        if let stale = cachedReciters(maxAge: nil) {
            Self.log.info("Falling back to the cached reciter catalog")
            return stale
        }
        if let seed = loadSeed() {
            Self.log.info("Falling back to the bundled seed reciter catalog")
            return seed
        }
        Self.log.error("No reciter catalog available: \(error.localizedDescription, privacy: .public)")
        throw error as? ReciterCatalogError ?? ReciterCatalogError.noDataAvailable
    }

    private func seedCatalog() -> ReciterCatalog? {
        guard
            let url = Bundle.main.url(forResource: Self.seedResourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? decodeCatalog(from: data)
    }

    private func loadSeed() -> [ReciterInfo]? {
        guard let catalog = seedCatalog() else { return nil }
        return catalog.reciters.map { $0.reciterInfo }
    }

    private func isInsideNegativeWindow() -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        guard let lastFailureAt else { return false }
        return Date().timeIntervalSince(lastFailureAt) < negativeTTL
    }

    private func sharedAttempt(
        _ make: () -> Task<[ReciterInfo], Error>
    ) -> Task<[ReciterInfo], Error> {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let inFlight { return inFlight }
        let attempt = make()
        inFlight = attempt
        return attempt
    }

    private func clearInFlight() {
        cacheLock.lock()
        inFlight = nil
        cacheLock.unlock()
    }

    // MARK: - Cache

    private func cachedReciters(maxAge: TimeInterval?) -> [ReciterInfo]? {
        guard let entry = currentCache() else { return nil }
        if let maxAge, Date().timeIntervalSince(entry.fetchedAt) >= maxAge { return nil }
        return entry.reciters
    }

    private func currentCache() -> CachedCatalog? {
        cacheLock.lock()
        if let cached {
            cacheLock.unlock()
            return cached
        }
        if didReadDisk {
            cacheLock.unlock()
            return nil
        }
        cacheLock.unlock()

        let onDisk = readCacheFile()

        cacheLock.lock()
        defer { cacheLock.unlock() }
        didReadDisk = true
        if cached == nil { cached = onDisk }
        return cached
    }

    private func store(_ entry: CachedCatalog) {
        cacheLock.lock()
        cached = entry
        didReadDisk = true
        lastFailureAt = nil
        cacheLock.unlock()

        writeCacheFile(entry)
    }

    private func readCacheFile() -> CachedCatalog? {
        guard
            let cacheFileURL,
            let data = try? Data(contentsOf: cacheFileURL),
            let entry = try? JSONDecoder().decode(CachedCatalog.self, from: data),
            !entry.reciters.isEmpty
        else { return nil }
        return entry
    }

    private func writeCacheFile(_ entry: CachedCatalog) {
        guard
            let cacheFileURL,
            let data = try? JSONEncoder().encode(entry)
        else { return }
        ioQueue.async {
            try? data.write(to: cacheFileURL, options: .atomic)
        }
    }
}

// MARK: - Cache Envelope

private struct CachedCatalog: Codable {
    let reciters: [ReciterInfo]
    let featured: [FeaturedReciter]
    let etag: String?
    let fetchedAt: Date
}

// MARK: - Error

enum ReciterCatalogError: LocalizedError {
    case missingBaseURL
    case badStatus(Int)
    case decodingFailed
    case noDataAvailable

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:      return "Remote config base URL is not configured"
        case .badStatus(let code): return "Reciter catalog request failed with HTTP \(code)"
        case .decodingFailed:      return "Reciter catalog payload could not be decoded"
        case .noDataAvailable:     return "No reciter catalog data available"
        }
    }
}
