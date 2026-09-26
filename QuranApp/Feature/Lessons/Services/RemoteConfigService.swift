//
//  RemoteConfigService.swift
//  QuranApp
//

import Foundation
import os

// MARK: - RemoteConfigService

/// Fetches the curated sheikh channel list published at
/// `<AppConfig.remoteConfigBaseURL>/sheikhs.json`.
///
/// The list is small and changes rarely, so the service is aggressively cached:
/// a fresh on-disk copy short-circuits the network entirely, and an `ETag`
/// turns the hourly refresh into a zero-byte `304 Not Modified` round trip.
/// A failed attempt opens a short negative window, so an unreachable or
/// unpublished config is not re-requested on every screen appearance.
///
/// The caller never sees an empty list because of a network blip — a stale
/// cache, and failing that the bundled seed copy, always wins over throwing.
final class RemoteConfigService {

    static let shared = RemoteConfigService()

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.Quran.wird",
        category: "RemoteConfig"
    )

    /// Document name appended to the configured base URL.
    private static let documentName = "sheikhs.json"

    /// Bundled seed copy, used only when there is no cache at all.
    private static let seedResourceName = "sheikhs"

    private static let cacheFileName = "remote-sheikh-channels.json"

    /// A YouTube channel id is `UC` plus 22 more characters — anything else in
    /// the published list is a typo, not a channel.
    private static let channelIDPrefix = "UC"
    private static let channelIDLength = 24

    /// Legacy UserDefaults keys from the Google Sheets era, removed on first run.
    private static let legacyDefaultsKeys = [
        "lessons_channel_ids_cache",
        "lessons_channel_ids_cache_timestamp"
    ]

    private let cacheTTL: TimeInterval = 3600

    /// How long a failure suppresses the next attempt. Without it an
    /// unpublished config costs a fresh round trip on every single call.
    private let negativeTTL: TimeInterval = 300

    /// Protected by `cacheLock` — the Lessons list and the Home carousel can
    /// both call `fetchChannels()` at the same time.
    private let cacheLock = NSLock()
    private var cached: CachedConfig?

    /// True once the cache file has been consulted, so a missing file is not
    /// re-read on every call.
    private var didReadDisk = false

    /// When the last attempt failed. Memory only, never persisted: a fresh
    /// launch is always worth one network attempt.
    private var lastFailureAt: Date?

    /// The one attempt both callers share while it is running.
    private var inFlight: Task<[SheikhChannel], Error>?

    /// Bumped by `invalidateCache()`. `currentCache()` reads the file unlocked,
    /// so it uses this to tell whether the entry it is about to commit was
    /// invalidated while that read was in flight.
    private var cacheGeneration: Int = 0

    /// Cache-file writes are serialized here, off the calling thread.
    private let ioQueue = DispatchQueue(label: "com.wird.remoteconfig.io", qos: .utility)

    private let cacheFileURL: URL? = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first?
        .appending(path: RemoteConfigService.cacheFileName)

    private init() {
        removeLegacyDefaults()
    }

    // MARK: - Public

    /// Curated channels, newest available copy first.
    ///
    /// Throws only when there is genuinely nothing to show: no fresh response,
    /// no cache, and no readable seed.
    func fetchChannels() async throws -> [SheikhChannel] {
        if let fresh = cachedChannels(maxAge: cacheTTL) { return fresh }

        if isInsideNegativeWindow() {
            Self.log.info("Recent failure still inside the negative window — skipping the network")
            // Not recorded: the window has to measure from the last real
            // attempt, not the last call, or it never reopens.
            return try fallback(after: RemoteConfigError.noDataAvailable, recordFailure: false)
        }

        guard let base = AppConfig.remoteConfigBaseURL else {
            Self.log.error("Remote config base URL is not configured")
            return try fallback(after: RemoteConfigError.missingBaseURL)
        }

        let url = base.appending(path: Self.documentName)

        // Home and Lessons both fetch on launch. Without coalescing that is two
        // config requests and two full YouTube batches for the same list, so a
        // second caller joins the attempt already running instead of starting
        // its own. Detached on purpose: the attempt is shared between two
        // unrelated callers, so it must not inherit cancellation from whichever
        // one happened to create it.
        let attempt = sharedAttempt {
            Task.detached(priority: .userInitiated) { [self] () -> [SheikhChannel] in
                // Last act on both the success and the throwing path, so a
                // failed attempt cannot wedge the next one.
                defer { clearInFlight() }
                do {
                    return try await load(from: url)
                } catch {
                    // Runs inside the shared task, so a joining caller receives
                    // the same fallback instead of starting its own attempt.
                    return try fallback(after: error)
                }
            }
        }

        return try await attempt.value
    }

    /// Ages the cached copy out so the next fetch goes to the network.
    ///
    /// The entry itself is kept, never deleted: pull-to-refresh while offline
    /// must still be able to fall back to the last good list rather than
    /// downgrading the user to the build-time seed.
    func invalidateCache() {
        cacheLock.lock()
        cacheGeneration += 1
        // An explicit refresh always earns a network attempt, even inside the
        // negative window.
        lastFailureAt = nil
        let inMemory = cached
        cacheLock.unlock()

        // Disk I/O runs unlocked — same discipline as `currentCache()`.
        guard let entry = inMemory ?? readCacheFile() else { return }

        cacheLock.lock()
        // Same payload and ETag — a refresh that finds nothing changed can still
        // take the 304 path — but dated so `cachedChannels(maxAge: cacheTTL)`
        // reports it stale while `cachedChannels(maxAge: nil)` still serves it.
        cached = CachedConfig(channels: entry.channels, etag: entry.etag, fetchedAt: .distantPast)
        didReadDisk = true
        cacheLock.unlock()
    }

    // MARK: - Networking

    private func load(from url: URL) async throws -> [SheikhChannel] {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // This service owns its own caching and TTL; URLSession's HTTP cache
        // would otherwise shadow the ETag round trip below.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let etag = currentCache()?.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            Self.log.error("Remote config request failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        guard let http = response as? HTTPURLResponse else {
            throw RemoteConfigError.noDataAvailable
        }

        switch http.statusCode {
        case 200:
            let channels = try decodeChannels(from: data)
            store(CachedConfig(
                channels: channels,
                etag: http.value(forHTTPHeaderField: "Etag"),
                fetchedAt: Date()
            ))
            return channels

        case 304:
            // Unchanged upstream — keep the payload, just restart the TTL.
            guard let entry = currentCache() else { throw RemoteConfigError.noDataAvailable }
            store(CachedConfig(channels: entry.channels, etag: entry.etag, fetchedAt: Date()))
            return entry.channels

        default:
            Self.log.error("Remote config returned HTTP \(http.statusCode, privacy: .public)")
            throw RemoteConfigError.badStatus(http.statusCode)
        }
    }

    // MARK: - Decoding

    private func decodeChannels(from data: Data) throws -> [SheikhChannel] {
        guard let payload = try? JSONDecoder().decode(RemoteConfigPayload.self, from: data) else {
            Self.log.error("Remote config payload could not be decoded")
            throw RemoteConfigError.decodingFailed
        }

        let channels = payload.channels.filter {
            $0.id.hasPrefix(Self.channelIDPrefix) && $0.id.count == Self.channelIDLength
        }
        // An empty list is a broken publish, never a legitimate state — treat it
        // as a decode failure so it cannot overwrite a good cache.
        guard !channels.isEmpty else {
            Self.log.error("Remote config held no usable channel ids")
            throw RemoteConfigError.decodingFailed
        }
        return channels
    }

    // MARK: - Fallback

    /// Stale cache, then the bundled seed. Rethrows `error` only when both are gone.
    ///
    /// `recordFailure` opens the negative window. Only a branch that actually
    /// reached the network passes true — a call that was already suppressed
    /// must not push the window forward.
    private func fallback(after error: Error, recordFailure: Bool = true) throws -> [SheikhChannel] {
        if recordFailure {
            cacheLock.lock()
            lastFailureAt = Date()
            cacheLock.unlock()
        }

        if let stale = cachedChannels(maxAge: nil) {
            Self.log.info("Falling back to the cached channel list")
            return stale
        }
        if let seed = loadSeed() {
            Self.log.info("Falling back to the bundled seed channel list")
            return seed
        }
        Self.log.error("No channel list available: \(error.localizedDescription, privacy: .public)")
        throw error as? RemoteConfigError ?? RemoteConfigError.noDataAvailable
    }

    private func loadSeed() -> [SheikhChannel]? {
        guard
            let url = Bundle.main.url(forResource: Self.seedResourceName, withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else { return nil }
        return try? decodeChannels(from: data)
    }

    /// True while the last failure is still inside `negativeTTL`.
    private func isInsideNegativeWindow() -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        guard let lastFailureAt else { return false }
        return Date().timeIntervalSince(lastFailureAt) < negativeTTL
    }

    /// The attempt already running, or `make()` registered as the new one.
    ///
    /// Synchronous on purpose: `NSLock` is unavailable from an async context,
    /// and the lock still has to span the check and the assignment — clearing
    /// `inFlight` takes the same lock, so a task that finishes straight away
    /// cannot clear it before it has been stored.
    private func sharedAttempt(
        _ make: () -> Task<[SheikhChannel], Error>
    ) -> Task<[SheikhChannel], Error> {
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

    /// Cached channels, or nil when the cache is missing or older than `maxAge`.
    /// Pass `nil` for `maxAge` to accept a cache of any age.
    private func cachedChannels(maxAge: TimeInterval?) -> [SheikhChannel]? {
        guard let entry = currentCache() else { return nil }
        if let maxAge, Date().timeIntervalSince(entry.fetchedAt) >= maxAge { return nil }
        return entry.channels
    }

    private func currentCache() -> CachedConfig? {
        cacheLock.lock()
        if let cached {
            cacheLock.unlock()
            return cached
        }
        if didReadDisk {
            cacheLock.unlock()
            return nil
        }
        // Snapshot taken before unlocking: an `invalidateCache()` landing during
        // the read below must not be undone by committing the entry it aged out.
        let generation = cacheGeneration
        cacheLock.unlock()

        // Disk I/O runs unlocked — same discipline as TafsirService.
        let onDisk = readCacheFile()

        cacheLock.lock()
        defer { cacheLock.unlock() }
        didReadDisk = true
        guard generation == cacheGeneration else { return cached }
        if cached == nil { cached = onDisk }
        return cached
    }

    private func store(_ entry: CachedConfig) {
        cacheLock.lock()
        cached = entry
        didReadDisk = true
        // A round trip that reached the config reopens the network path at once.
        lastFailureAt = nil
        cacheLock.unlock()

        writeCacheFile(entry)
    }

    private func readCacheFile() -> CachedConfig? {
        guard
            let cacheFileURL,
            let data = try? Data(contentsOf: cacheFileURL),
            let entry = try? JSONDecoder().decode(CachedConfig.self, from: data),
            !entry.channels.isEmpty
        else { return nil }
        return entry
    }

    private func writeCacheFile(_ entry: CachedConfig) {
        guard
            let cacheFileURL,
            let data = try? JSONEncoder().encode(entry)
        else { return }
        // Serialized and off the calling thread, so two stores racing on the
        // same file cannot interleave.
        ioQueue.async {
            try? data.write(to: cacheFileURL, options: .atomic)
        }
    }

    /// The Google Sheets era stored a bare `[String]` of ids in UserDefaults.
    /// It can never be read again, so drop it instead of leaving it resident.
    private func removeLegacyDefaults() {
        let defaults = UserDefaults.standard
        for key in Self.legacyDefaultsKeys {
            defaults.removeObject(forKey: key)
        }
    }
}

// MARK: - Wire Format

/// Envelope published at `<base>/sheikhs.json`. `version` and `updatedAt` are
/// editorial metadata and are not required for the payload to be usable.
private struct RemoteConfigPayload: Decodable {
    let version: Int?
    let updatedAt: String?
    let channels: [SheikhChannel]
}

// MARK: - Cache Envelope

private struct CachedConfig: Codable {
    let channels: [SheikhChannel]
    let etag: String?
    let fetchedAt: Date
}

// MARK: - Error

enum RemoteConfigError: LocalizedError {
    case missingBaseURL
    case badStatus(Int)
    case decodingFailed
    case noDataAvailable

    var errorDescription: String? {
        switch self {
        case .missingBaseURL:      return "Remote config base URL is not configured"
        case .badStatus(let code): return "Remote config request failed with HTTP \(code)"
        case .decodingFailed:      return "Remote config payload could not be decoded"
        case .noDataAvailable:     return "No sheikh channel data available"
        }
    }
}
