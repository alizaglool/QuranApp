//
//  RadioCatalogService.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation
import os

// MARK: - RadioCatalogService

final class RadioCatalogService {

    static let shared = RadioCatalogService()

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.Quran.wird",
        category: "RadioCatalog"
    )

    private static let documentName = "radios.json"
    private static let seedResourceName = "radios"
    private static let cacheFileName = "remote-radios.json"

    private let cacheTTL: TimeInterval = 3600
    private let negativeTTL: TimeInterval = 300

    private let cacheLock = NSLock()
    private var cached: CachedRadioCatalog?
    private var didReadDisk = false
    private var lastFailureAt: Date?
    private var inFlight: Task<[RadioStation], Error>?

    private let ioQueue = DispatchQueue(label: "com.wird.radiocatalog.io", qos: .utility)

    private let cacheFileURL: URL? = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first?
        .appending(path: RadioCatalogService.cacheFileName)

    private init() {}

    // MARK: - Warm Up

    func warmUp() {
        ioQueue.async { _ = self.currentStations() }
    }

    // MARK: - Synchronous Read

    func currentStations() -> [RadioStation] {
        if let entry = currentCache(), !entry.stations.isEmpty {
            return entry.stations
        }
        return loadSeed() ?? []
    }

    // MARK: - Refresh

    @discardableResult
    func refresh() async throws -> [RadioStation] {
        if let fresh = cachedStations(maxAge: cacheTTL) { return fresh }

        if isInsideNegativeWindow() {
            Self.log.info("Recent failure still inside the negative window — skipping the network")
            return try fallback(after: RadioCatalogError.noDataAvailable, recordFailure: false)
        }

        guard let base = AppConfig.remoteConfigBaseURL else {
            Self.log.error("Remote config base URL is not configured")
            return try fallback(after: RadioCatalogError.missingBaseURL)
        }

        let url = base.appending(path: Self.documentName)

        let attempt = sharedAttempt {
            Task.detached(priority: .userInitiated) { [self] () -> [RadioStation] in
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

    private func load(from url: URL) async throws -> [RadioStation] {
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
            Self.log.error("Radio catalog request failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw RadioCatalogError.noDataAvailable
        }

        switch http.statusCode {
        case 200:
            let catalog = try decodeCatalog(from: data)
            store(CachedRadioCatalog(
                stations: catalog.stations,
                etag: http.value(forHTTPHeaderField: "Etag"),
                fetchedAt: Date()
            ))
            return catalog.stations

        case 304:
            guard let entry = currentCache() else { throw RadioCatalogError.noDataAvailable }
            store(CachedRadioCatalog(
                stations: entry.stations,
                etag: entry.etag,
                fetchedAt: Date()
            ))
            return entry.stations

        default:
            Self.log.error("Radio catalog returned HTTP \(http.statusCode, privacy: .public)")
            throw RadioCatalogError.badStatus(http.statusCode)
        }
    }

    // MARK: - Decoding

    private func decodeCatalog(from data: Data) throws -> RadioCatalog {
        guard let catalog = try? JSONDecoder().decode(RadioCatalog.self, from: data) else {
            Self.log.error("Radio catalog payload could not be decoded")
            throw RadioCatalogError.decodingFailed
        }
        guard !catalog.stations.isEmpty else {
            Self.log.error("Radio catalog held no usable stations")
            throw RadioCatalogError.decodingFailed
        }
        return catalog
    }

    // MARK: - Fallback

    private func fallback(after error: Error, recordFailure: Bool = true) throws -> [RadioStation] {
        if recordFailure {
            cacheLock.lock()
            lastFailureAt = Date()
            cacheLock.unlock()
        }

        if let stale = cachedStations(maxAge: nil) {
            Self.log.info("Falling back to the cached radio catalog")
            return stale
        }
        if let seed = loadSeed() {
            Self.log.info("Falling back to the bundled seed radio catalog")
            return seed
        }
        Self.log.error("No radio catalog available: \(error.localizedDescription, privacy: .public)")
        throw error as? RadioCatalogError ?? RadioCatalogError.noDataAvailable
    }

    private func loadSeed() -> [RadioStation]? {
        guard
            let url = Bundle.main.url(forResource: Self.seedResourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let catalog = try? decodeCatalog(from: data)
        else { return nil }
        return catalog.stations
    }

    private func isInsideNegativeWindow() -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        guard let lastFailureAt else { return false }
        return Date().timeIntervalSince(lastFailureAt) < negativeTTL
    }

    private func sharedAttempt(
        _ make: () -> Task<[RadioStation], Error>
    ) -> Task<[RadioStation], Error> {
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

    private func cachedStations(maxAge: TimeInterval?) -> [RadioStation]? {
        guard let entry = currentCache() else { return nil }
        if let maxAge, Date().timeIntervalSince(entry.fetchedAt) >= maxAge { return nil }
        return entry.stations
    }

    private func currentCache() -> CachedRadioCatalog? {
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

    private func store(_ entry: CachedRadioCatalog) {
        cacheLock.lock()
        cached = entry
        didReadDisk = true
        lastFailureAt = nil
        cacheLock.unlock()

        writeCacheFile(entry)
    }

    private func readCacheFile() -> CachedRadioCatalog? {
        guard
            let cacheFileURL,
            let data = try? Data(contentsOf: cacheFileURL),
            let entry = try? JSONDecoder().decode(CachedRadioCatalog.self, from: data),
            !entry.stations.isEmpty
        else { return nil }
        return entry
    }

    private func writeCacheFile(_ entry: CachedRadioCatalog) {
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

private struct CachedRadioCatalog: Codable {
    let stations: [RadioStation]
    let etag: String?
    let fetchedAt: Date
}

// MARK: - Error

enum RadioCatalogError: LocalizedError {
    case missingBaseURL
    case badStatus(Int)
    case decodingFailed
    case noDataAvailable

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:      return "Remote config base URL is not configured"
        case .badStatus(let code): return "Radio catalog request failed with HTTP \(code)"
        case .decodingFailed:      return "Radio catalog payload could not be decoded"
        case .noDataAvailable:     return "No radio catalog data available"
        }
    }
}
