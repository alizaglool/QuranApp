//
//  YouTubeContentService.swift
//  QuranApp
//

import Foundation
import Core

// MARK: - Content Buckets

/// The four video tabs on the sheikh detail screen. A single upload belongs to
/// exactly one bucket — classification happens on the client from the real
/// duration, because YouTube's `videoDuration` search filter uses different
/// boundaries (short < 4 min, medium 4–20 min, long > 20 min) than the tabs do.
enum SheikhContentBucket: CaseIterable {
    case videos, shorts, podcasts, live
}

// MARK: - Errors

enum YouTubeContentError: LocalizedError {
    case badStatus(Int)
    case decodingFailed
    case missingUploadsPlaylist
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .badStatus(let code):     return "YouTube API returned HTTP \(code)."
        case .decodingFailed:          return "YouTube API response could not be decoded."
        case .missingUploadsPlaylist:  return "This channel exposes no uploads playlist."
        case .quotaExceeded:           return "The YouTube API daily quota is exhausted."
        }
    }
}

// MARK: - Service

/// Serves the sheikh detail screen from a server-prefetched artifact, and only
/// falls back to the live YouTube API for deep pagination or when the artifact
/// is unreachable.
///
/// The live API quota is 10,000 units per *API key*, not per install, so every
/// app on every device draws from the same daily budget — a few hundred active
/// users is enough to exhaust it. A scheduled job publishes each channel as
/// static JSON next to the remote config, and reading that costs zero quota.
///
/// An `actor` because the enriched-page cache and the per-channel artifact
/// cache are mutable state reached from every tab's load task concurrently.
actor YouTubeContentService {
    static let shared = YouTubeContentService()

    private var apiKey: String { AppConfig.youtubeApiKey }
    private let baseURL = "https://www.googleapis.com/youtube/v3"

    /// A bucket counts as filled at this many items — auto-paging stops there.
    private static let minimumItemsPerCall = 12
    /// Hard ceiling on upstream `playlistItems` pages fetched in one call, so a
    /// channel that publishes only Shorts can never spin the loop indefinitely.
    private static let maxUpstreamPagesPerCall = 5
    /// Bucket boundaries in seconds.
    private static let shortsMaxSeconds = 180
    private static let videosMaxSeconds = 1_200
    /// Upstream pages retained after classification.
    private static let pageCacheLimit = 10
    /// Playlists per prefetched page — matches the live path's `maxResults`, so
    /// the two sources page identically.
    private static let playlistsPerCall = 50

    /// Directory the prefetched channel artifacts are published under.
    private static let artifactDirectory = "channels"
    /// How long a downloaded artifact is served without re-checking upstream.
    private static let artifactTTL: TimeInterval = 3600
    /// How long a failure suppresses the next attempt, so an unpublished
    /// channel is not re-requested on every tab switch.
    private static let artifactNegativeTTL: TimeInterval = 300

    private var pageCache: [String: CachedPage] = [:]
    private var pageCacheKeys: [String] = []

    /// Prefetched artifacts by channel id. Actor-isolated, so no lock.
    private var artifactCache: [String: CachedArtifact] = [:]
    /// Channels whose cache file has already been consulted, so a missing file
    /// is not re-read on every call.
    private var artifactDidReadDisk: Set<String> = []
    /// When the last attempt failed, per channel. Memory only, never persisted:
    /// a fresh launch is always worth one attempt.
    private var artifactFailureAt: [String: Date] = [:]
    /// The one attempt every tab of a channel shares while it is running.
    private var artifactInFlight: [String: Task<ChannelArtifact, Error>] = [:]

    /// Cache-file writes are serialized here, off the actor.
    private let ioQueue = DispatchQueue(label: "com.wird.youtubecontent.io", qos: .utility)

    private init() {}

    // MARK: Playlists

    /// The channel's playlists, prefetched copy first.
    ///
    /// `pageToken` is the opaque namespaced token this method returned last
    /// time — never a raw YouTube token. See `ContentCursor`.
    func fetchPlaylists(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonPlaylist], nextPageToken: String?) {
        switch Self.cursor(from: pageToken) {
        case .prefetched(let offset):
            if let artifact = try? await channelArtifact(channelId) {
                return Self.prefetchedPlaylists(artifact, offset: offset)
            }
            // No artifact and no cache — the live API is the only way to fill
            // the tab, so the screen still works with the config repo down.
            return try await livePlaylists(channelId: channelId, rawPageToken: nil)

        case .live(let token):
            return try await livePlaylists(channelId: channelId, rawPageToken: token)
        }
    }

    // MARK: Channel Content

    /// Uploads belonging to `bucket`, prefetched copy first.
    ///
    /// The artifact carries the channel's most recent uploads already classified
    /// by the publisher, which covers every tab without spending a single quota
    /// unit. Paging past the end of it resumes against the live API from
    /// `uploadsNextPageToken`, so deep scrolling still works.
    ///
    /// `pageToken` is the opaque namespaced token this method returned last
    /// time — never a raw YouTube token. See `ContentCursor`.
    func fetchContent(
        channelId: String,
        uploadsPlaylistId: String,
        bucket: SheikhContentBucket,
        pageToken: String? = nil
    ) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        switch Self.cursor(from: pageToken) {
        case .prefetched(let offset):
            if let artifact = try? await channelArtifact(channelId) {
                return Self.prefetchedContent(artifact, bucket: bucket, offset: offset)
            }
            return try await liveContent(
                channelId: channelId,
                uploadsPlaylistId: uploadsPlaylistId,
                bucket: bucket,
                rawPageToken: nil
            )

        case .live(let token):
            return try await liveContent(
                channelId: channelId,
                uploadsPlaylistId: uploadsPlaylistId,
                bucket: bucket,
                rawPageToken: token
            )
        }
    }

    // MARK: Playlist Items

    /// Unlike `fetchContent`, this takes and returns **raw** YouTube tokens:
    /// a playlist's items are not part of the prefetched artifact, so there is
    /// only one source and nothing to disambiguate.
    func fetchPlaylistItems(playlistId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        let page = try await uploadsPage(playlistId: playlistId, pageToken: pageToken)
        let enriched = await enrichWithDetails(page.items)
        return (enriched, page.nextPageToken)
    }

    // MARK: Video Details Enrichment

    /// Attaches duration and view count. Never throws: a failed enrichment costs
    /// metadata, not content, so the caller still gets its items.
    func enrichWithDetails(_ videos: [LessonVideo]) async -> [LessonVideo] {
        guard !videos.isEmpty else { return videos }
        guard let details = try? await videoDetails(ids: videos.map(\.id)) else { return videos }

        return videos.map { video in
            guard let detail = details[video.id] else { return video }
            return video.applying(detail)
        }
    }

    // MARK: Cache

    func invalidate() {
        pageCache.removeAll()
        pageCacheKeys.removeAll()

        // Artifacts are aged out, never dropped: a refresh while offline must
        // still be able to serve the last good copy rather than falling all the
        // way back to the quota-billed API.
        for (channelId, entry) in artifactCache {
            artifactCache[channelId] = CachedArtifact(
                artifact: entry.artifact,
                etag: entry.etag,
                fetchedAt: .distantPast
            )
        }
        artifactFailureAt.removeAll()
    }
}

// MARK: - Private: Page Tokens

private extension YouTubeContentService {

    /// Where the next page comes from. Every token `fetchContent` and
    /// `fetchPlaylists` hand out is namespaced, so the caller can store it as an
    /// opaque `String?` and can never mix the two sources up:
    ///
    /// - `p:<offset>` more items remain in the prefetched, already-classified array
    /// - `y:<token>`  continue against the live YouTube API
    /// - `nil`        done
    enum ContentCursor {
        case prefetched(offset: Int)
        case live(token: String)
    }

    static var prefetchedTokenPrefix: String { "p:" }
    static var liveTokenPrefix: String { "y:" }

    static func cursor(from token: String?) -> ContentCursor {
        guard let token, !token.isEmpty else { return .prefetched(offset: 0) }

        if token.hasPrefix(prefetchedTokenPrefix) {
            let offset = Int(token.dropFirst(prefetchedTokenPrefix.count)) ?? 0
            return .prefetched(offset: offset)
        }
        if token.hasPrefix(liveTokenPrefix) {
            return .live(token: String(token.dropFirst(liveTokenPrefix.count)))
        }

        // These two prefixes are the only tokens this service ever emits, so an
        // unprefixed one came from somewhere else. Restart rather than forward
        // it upstream as if it were a YouTube token.
        return .prefetched(offset: 0)
    }

    static func prefetchedToken(offset: Int) -> String { prefetchedTokenPrefix + String(offset) }

    /// The single place a YouTube token is allowed to leave this service, and it
    /// is namespaced on the way out.
    static func liveToken(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        return liveTokenPrefix + raw
    }
}

// MARK: - Private: Prefetched Artifact Paths

private extension YouTubeContentService {

    /// One page of `bucket` read straight out of the artifact.
    ///
    /// Classification is deterministic over the whole `uploads` array, so the
    /// filtered result is stable and `offset` can index it directly.
    static func prefetchedContent(
        _ artifact: ChannelArtifact,
        bucket: SheikhContentBucket,
        offset: Int
    ) -> (items: [LessonVideo], nextPageToken: String?) {
        let matches = artifact.uploads.filter {
            Self.bucket(seconds: $0.durationSeconds, isPastBroadcast: $0.isPastBroadcast) == bucket
        }

        let start = min(max(offset, 0), matches.count)
        let end   = min(start + minimumItemsPerCall, matches.count)
        let items = matches[start..<end].map { lessonVideo(from: $0, isReel: bucket == .shorts) }

        let next: String?
        if end < matches.count {
            next = prefetchedToken(offset: end)
        } else {
            // Prefetched uploads exhausted — hand the caller the upstream token
            // the publisher stopped at so deep paging continues from there.
            next = liveToken(artifact.uploadsNextPageToken)
        }

        return (items, next)
    }

    /// The artifact carries every playlist the channel exposes, so there is no
    /// upstream token to continue from — running out means done.
    static func prefetchedPlaylists(
        _ artifact: ChannelArtifact,
        offset: Int
    ) -> (items: [LessonPlaylist], nextPageToken: String?) {
        let all   = artifact.playlists
        let start = min(max(offset, 0), all.count)
        let end   = min(start + playlistsPerCall, all.count)
        let items = all[start..<end].map { $0.lessonPlaylist }

        return (items, end < all.count ? prefetchedToken(offset: end) : nil)
    }

    /// The artifact has no per-upload channel title; nothing on this screen
    /// reads `channelTitle`, so it stays empty rather than being guessed.
    static func lessonVideo(from upload: ChannelArtifact.Upload, isReel: Bool) -> LessonVideo {
        LessonVideo(
            id: upload.id,
            title: upload.title ?? "",
            thumbnailUrl: upload.thumbnailUrl ?? "",
            publishedAt: upload.publishedAt ?? "",
            channelTitle: "",
            isReel: isReel,
            duration: upload.durationSeconds.flatMap { displayDuration(seconds: $0) },
            viewCount: upload.viewCount
        )
    }
}

// MARK: - Private: Live API Paths

private extension YouTubeContentService {

    /// Pages the channel's uploads playlist and returns only the items belonging
    /// to `bucket`.
    ///
    /// One upstream page of 50 uploads is rarely a screenful for any single tab —
    /// a channel's latest 50 uploads can be 48 Shorts and 2 videos — so this keeps
    /// pulling upstream pages until the bucket has a screenful or the ceiling is
    /// reached. The returned token resumes exactly where this call stopped.
    func liveContent(
        channelId: String,
        uploadsPlaylistId: String,
        bucket: SheikhContentBucket,
        rawPageToken: String?
    ) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        let playlistId = await resolvedUploadsPlaylistId(channelId: channelId, fallback: uploadsPlaylistId)
        guard !playlistId.isEmpty else {
            throw YouTubeContentError.missingUploadsPlaylist
        }

        var kept: [LessonVideo] = []
        var token = rawPageToken
        var pagesFetched = 0

        repeat {
            let page = try await classifiedPage(uploadsPlaylistId: playlistId, pageToken: token)
            pagesFetched += 1
            token = page.nextPageToken
            kept.append(contentsOf: page.items.lazy.filter { $0.bucket == bucket }.map(\.video))
        } while token != nil
            && kept.count < Self.minimumItemsPerCall
            && pagesFetched < Self.maxUpstreamPagesPerCall

        return (kept, Self.liveToken(token))
    }

    func livePlaylists(
        channelId: String,
        rawPageToken: String?
    ) async throws -> (items: [LessonPlaylist], nextPageToken: String?) {
        var queryItems: [URLQueryItem] = [
            .init(name: "part", value: "snippet,contentDetails"),
            .init(name: "channelId", value: channelId),
            .init(name: "maxResults", value: "50"),
            .init(name: "key", value: apiKey)
        ]
        if let rawPageToken {
            queryItems.append(.init(name: "pageToken", value: rawPageToken))
        }

        let decoded: YouTubePlaylistResponse = try await get("playlists", queryItems)

        let playlists = decoded.items.compactMap { item -> LessonPlaylist? in
            guard let snippet = item.snippet else { return nil }
            return LessonPlaylist(
                id: item.id,
                title: snippet.title ?? "",
                thumbnailUrl: snippet.thumbnails?.bestUrl ?? "",
                itemCount: item.contentDetails?.itemCount ?? 0,
                description: snippet.description ?? ""
            )
        }

        return (playlists, Self.liveToken(decoded.nextPageToken))
    }

    /// A channel published before the uploads playlist was recorded in the
    /// remote config has an empty id here, but the artifact always knows it.
    func resolvedUploadsPlaylistId(channelId: String, fallback: String) async -> String {
        guard fallback.isEmpty else { return fallback }
        guard let artifact = try? await channelArtifact(channelId) else { return "" }
        return artifact.uploadsPlaylistId ?? ""
    }
}

// MARK: - Private: Channel Artifact

private extension YouTubeContentService {

    /// The prefetched artifact for `channelId`, freshest copy first.
    ///
    /// Mirrors `RemoteConfigService`: a fresh on-disk copy short-circuits the
    /// network, an `ETag` turns the hourly refresh into a `304`, and a failure
    /// opens a short negative window. A stale copy of *any* age beats going to
    /// the quota-billed API, so the only throwing path is "nothing cached at
    /// all" — which is exactly when the caller falls back to the live API.
    func channelArtifact(_ channelId: String) async throws -> ChannelArtifact {
        guard !channelId.isEmpty else { throw YouTubeContentError.decodingFailed }

        if let fresh = cachedArtifact(channelId, maxAge: Self.artifactTTL) { return fresh }

        // Four tabs open the same channel — the second one joins the attempt
        // already running instead of downloading the same document again.
        if let running = artifactInFlight[channelId] {
            return try await running.value
        }

        if isInsideNegativeWindow(channelId) {
            guard let stale = cachedArtifact(channelId, maxAge: nil) else {
                throw YouTubeContentError.decodingFailed
            }
            return stale
        }

        guard let base = AppConfig.remoteConfigBaseURL else {
            throw YouTubeContentError.decodingFailed
        }
        let url = base
            .appending(path: Self.artifactDirectory)
            .appending(path: "\(channelId).json")

        // Detached on purpose: the attempt is shared between tabs, so it must
        // not inherit cancellation from whichever one happened to create it.
        // No await between the lookup above and this assignment, so two callers
        // can never both start one.
        let attempt = Task.detached(priority: .userInitiated) { [self] () -> ChannelArtifact in
            try await loadArtifact(channelId: channelId, from: url)
        }
        artifactInFlight[channelId] = attempt
        defer { artifactInFlight[channelId] = nil }

        do {
            return try await attempt.value
        } catch {
            artifactFailureAt[channelId] = Date()
            // Serve-stale is the whole point: any cached copy beats the API.
            if let stale = cachedArtifact(channelId, maxAge: nil) {
                print("⚠️ YouTubeContentService: serving stale artifact for \(channelId)")
                return stale
            }
            print("❌ YouTubeContentService: no artifact for \(channelId): \(error)")
            throw error
        }
    }

    func loadArtifact(channelId: String, from url: URL) async throws -> ChannelArtifact {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // This service owns its own caching and TTL; URLSession's HTTP cache
        // would otherwise shadow the ETag round trip below.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        if let etag = currentArtifact(channelId)?.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw YouTubeContentError.decodingFailed
        }

        switch http.statusCode {
        case 200:
            guard let artifact = try? JSONDecoder().decode(ChannelArtifact.self, from: data) else {
                print("❌ YouTubeContentService: artifact for \(channelId) could not be decoded")
                throw YouTubeContentError.decodingFailed
            }
            store(CachedArtifact(
                artifact: artifact,
                etag: http.value(forHTTPHeaderField: "Etag"),
                fetchedAt: Date()
            ), for: channelId)
            return artifact

        case 304:
            // Unchanged upstream — keep the payload, just restart the TTL.
            guard let entry = currentArtifact(channelId) else {
                throw YouTubeContentError.decodingFailed
            }
            store(CachedArtifact(
                artifact: entry.artifact,
                etag: entry.etag,
                fetchedAt: Date()
            ), for: channelId)
            return entry.artifact

        default:
            print("❌ YouTubeContentService: artifact for \(channelId) → HTTP \(http.statusCode)")
            throw YouTubeContentError.badStatus(http.statusCode)
        }
    }

    // MARK: Artifact cache

    /// The cached artifact, or nil when it is missing or older than `maxAge`.
    /// Pass `nil` for `maxAge` to accept a copy of any age.
    func cachedArtifact(_ channelId: String, maxAge: TimeInterval?) -> ChannelArtifact? {
        guard let entry = currentArtifact(channelId) else { return nil }
        if let maxAge, Date().timeIntervalSince(entry.fetchedAt) >= maxAge { return nil }
        return entry.artifact
    }

    func currentArtifact(_ channelId: String) -> CachedArtifact? {
        if let entry = artifactCache[channelId] { return entry }
        if artifactDidReadDisk.contains(channelId) { return nil }

        artifactDidReadDisk.insert(channelId)
        let onDisk = readArtifactFile(channelId)
        artifactCache[channelId] = onDisk
        return onDisk
    }

    func store(_ entry: CachedArtifact, for channelId: String) {
        artifactCache[channelId] = entry
        artifactDidReadDisk.insert(channelId)
        // A round trip that reached the artifact reopens the network path.
        artifactFailureAt[channelId] = nil
        writeArtifactFile(entry, for: channelId)
    }

    func isInsideNegativeWindow(_ channelId: String) -> Bool {
        guard let last = artifactFailureAt[channelId] else { return false }
        return Date().timeIntervalSince(last) < Self.artifactNegativeTTL
    }

    /// Nil for an id that is not filename-safe, so a malformed channel id can
    /// never be written outside the caches directory.
    func artifactFileURL(_ channelId: String) -> URL? {
        let safe = channelId.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        guard safe, !channelId.isEmpty else { return nil }
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appending(path: "youtube-channel-\(channelId).json")
    }

    func readArtifactFile(_ channelId: String) -> CachedArtifact? {
        guard
            let url = artifactFileURL(channelId),
            let data = try? Data(contentsOf: url),
            let entry = try? JSONDecoder().decode(CachedArtifact.self, from: data)
        else { return nil }
        return entry
    }

    func writeArtifactFile(_ entry: CachedArtifact, for channelId: String) {
        guard
            let url = artifactFileURL(channelId),
            let data = try? JSONEncoder().encode(entry)
        else { return }
        // Serialized and off the actor, so two stores racing on the same file
        // cannot interleave.
        ioQueue.async {
            try? data.write(to: url, options: .atomic)
        }
    }
}

// MARK: - Private: Paging & Classification

private extension YouTubeContentService {

    struct ClassifiedVideo {
        let video: LessonVideo
        let bucket: SheikhContentBucket
    }

    struct CachedPage {
        let items: [ClassifiedVideo]
        let nextPageToken: String?
    }

    /// One upstream page, enriched and bucketed. Cached so that switching between
    /// tabs re-reads the same pages instead of re-billing them against the quota.
    func classifiedPage(
        uploadsPlaylistId: String,
        pageToken: String?
    ) async throws -> (items: [ClassifiedVideo], nextPageToken: String?) {
        let key = "\(uploadsPlaylistId)|\(pageToken ?? "")"
        if let cached = pageCache[key] {
            return (cached.items, cached.nextPageToken)
        }

        let page = try await uploadsPage(playlistId: uploadsPlaylistId, pageToken: pageToken)
        let classified = try await classify(page.items)
        cache(CachedPage(items: classified, nextPageToken: page.nextPageToken), for: key)
        return (classified, page.nextPageToken)
    }

    func cache(_ page: CachedPage, for key: String) {
        if pageCache[key] == nil {
            pageCacheKeys.append(key)
        }
        pageCache[key] = page

        while pageCacheKeys.count > Self.pageCacheLimit {
            pageCache.removeValue(forKey: pageCacheKeys.removeFirst())
        }
    }

    /// Throws when enrichment fails, rather than defaulting the page to
    /// `.videos`. Defaulting hands Shorts, Podcasts and Live zero items plus a
    /// live page token and no error — indistinguishable from a bucket that is
    /// genuinely empty here — and it hides a drained quota behind the generic
    /// connection message.
    func classify(_ videos: [LessonVideo]) async throws -> [ClassifiedVideo] {
        guard !videos.isEmpty else { return [] }

        let details = try await videoDetails(ids: videos.map(\.id))

        return videos.map { video in
            guard let detail = details[video.id] else {
                return ClassifiedVideo(video: video, bucket: .videos)
            }
            let bucket = Self.bucket(seconds: detail.seconds, isPastBroadcast: detail.isPastBroadcast)
            return ClassifiedVideo(video: video.applying(detail, isReel: bucket == .shorts), bucket: bucket)
        }
    }

    /// The one classifier. Both the prefetched artifact and the live API run
    /// through it, so the two sources cannot drift into disagreeing about which
    /// tab a video belongs to.
    ///
    /// Priority: a past broadcast is Live whatever its length, then duration decides.
    static func bucket(seconds: Int?, isPastBroadcast: Bool) -> SheikhContentBucket {
        if isPastBroadcast { return .live }
        guard let seconds, seconds > 0 else { return .videos }
        if seconds <= shortsMaxSeconds { return .shorts }
        if seconds <= videosMaxSeconds { return .videos }
        return .podcasts
    }
}

// MARK: - Private: Requests

private extension YouTubeContentService {

    struct VideoDetail {
        let displayDuration: String?
        let seconds: Int?
        let viewCount: Int?
        let isPastBroadcast: Bool
    }

    /// `error.errors[].reason` values that mean the daily budget is gone. Any
    /// other 403 — a referrer or IP restriction on the key, for instance — is a
    /// different problem and must not be reported as a quota problem.
    static var quotaReasons: Set<String> { ["quotaExceeded", "dailyLimitExceeded"] }

    /// One page of the uploads playlist — 1 quota unit, and unlike `search.list`
    /// it enumerates every upload the channel has.
    func uploadsPage(playlistId: String, pageToken: String?) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        var queryItems: [URLQueryItem] = [
            .init(name: "part", value: "snippet"),
            .init(name: "playlistId", value: playlistId),
            .init(name: "maxResults", value: "50"),
            .init(name: "key", value: apiKey)
        ]
        if let pageToken {
            queryItems.append(.init(name: "pageToken", value: pageToken))
        }

        let decoded: YouTubePlaylistItemsResponse = try await get("playlistItems", queryItems)

        let items = decoded.items.compactMap { item -> LessonVideo? in
            guard
                let snippet = item.snippet,
                let videoId = snippet.resourceId?.videoId,
                !videoId.isEmpty
            else { return nil }

            return LessonVideo(
                id: videoId,
                title: snippet.title ?? "",
                thumbnailUrl: snippet.thumbnails?.bestUrl ?? "",
                publishedAt: snippet.publishedAt ?? "",
                channelTitle: snippet.videoOwnerChannelTitle ?? ""
            )
        }

        return (items, decoded.nextPageToken)
    }

    /// `liveStreamingDetails` rides along at no extra quota cost and is what lets
    /// the Live tab exist without a 100-unit `search.list` call.
    func videoDetails(ids: [String]) async throws -> [String: VideoDetail] {
        guard !ids.isEmpty else { return [:] }

        let queryItems: [URLQueryItem] = [
            .init(name: "part", value: "contentDetails,statistics,liveStreamingDetails"),
            .init(name: "id", value: ids.joined(separator: ",")),
            .init(name: "key", value: apiKey)
        ]

        do {
            let decoded: YouTubeVideoDetailsResponse = try await get("videos", queryItems)
            var map: [String: VideoDetail] = [:]
            for item in decoded.items {
                let seconds = item.contentDetails?.duration.flatMap { Self.durationSeconds($0) }
                map[item.id] = VideoDetail(
                    displayDuration: seconds.flatMap { Self.displayDuration(seconds: $0) },
                    seconds: seconds,
                    viewCount: item.statistics?.viewCount.flatMap { Int($0) },
                    // `actualEndTime`, not `actualStartTime`: a stream that has
                    // started but not finished is still live, not a past broadcast.
                    // The prefetch publisher derives the flag the same way, so the
                    // two paths classify the same upload identically.
                    isPastBroadcast: item.liveStreamingDetails?.actualEndTime != nil
                )
            }
            return map
        } catch {
            print("❌ YouTubeContentService.videoDetails failed: \(error)")
            throw error
        }
    }

    func get<T: Decodable>(_ path: String, _ queryItems: [URLQueryItem]) async throws -> T {
        guard var components = URLComponents(string: "\(baseURL)/\(path)") else {
            throw URLError(.badURL)
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            print("❌ YouTubeContentService \(path) → HTTP \(http.statusCode)")
            if http.statusCode == 403, Self.isQuotaFailure(data) {
                throw YouTubeContentError.quotaExceeded
            }
            throw YouTubeContentError.badStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("❌ YouTubeContentService \(path) decode failed: \(error)")
            throw YouTubeContentError.decodingFailed
        }
    }

    /// True only when the 403 body names a quota reason. An undecodable body is
    /// deliberately *not* a quota failure — guessing would hide a key problem
    /// behind a "try again tomorrow" message that never comes true.
    static func isQuotaFailure(_ data: Data) -> Bool {
        guard
            let body = try? JSONDecoder().decode(YouTubeErrorResponse.self, from: data),
            let details = body.error?.errors
        else { return false }

        return details.contains { detail in
            guard let reason = detail.reason else { return false }
            return quotaReasons.contains(reason)
        }
    }
}

// MARK: - Private: Duration Parsing

private extension YouTubeContentService {

    /// ISO-8601 `PT#H#M#S`. Videos never carry a date component, so only the
    /// time designators are read.
    static func durationSeconds(_ iso: String) -> Int? {
        var total = 0
        var digits = ""
        var matchedUnit = false

        for character in iso {
            if character.isNumber {
                digits.append(character)
                continue
            }
            guard let value = Int(digits) else {
                digits = ""
                continue
            }
            switch character {
            case "H": total += value * 3_600; matchedUnit = true
            case "M": total += value * 60;    matchedUnit = true
            case "S": total += value;         matchedUnit = true
            default:  break
            }
            digits = ""
        }

        return matchedUnit ? total : nil
    }

    static func displayDuration(seconds: Int) -> String? {
        guard seconds > 0 else { return nil }
        let hours   = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let secs    = seconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, secs)
            : String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - LessonVideo Enrichment

private extension LessonVideo {
    func applying(_ detail: YouTubeContentService.VideoDetail, isReel: Bool? = nil) -> LessonVideo {
        LessonVideo(
            id: id,
            title: title,
            thumbnailUrl: thumbnailUrl,
            publishedAt: publishedAt,
            channelTitle: channelTitle,
            isReel: isReel ?? self.isReel,
            duration: detail.displayDuration,
            viewCount: detail.viewCount
        )
    }
}

// MARK: - Prefetched Artifact Wire Format

/// Envelope published at `<base>/channels/<channelId>.json` by the prefetch job.
///
/// Only the fields this screen reads are decoded; `schemaVersion`,
/// `generatedAt` and `channel` are present upstream and ignored here. Every
/// value is optional with a default so one malformed entry degrades a single
/// row instead of failing the whole document into the live API path.
private struct ChannelArtifact: Codable {
    let uploadsPlaylistId: String?
    let uploadsNextPageToken: String?
    private let uploadsList: [Upload]?
    private let playlistsList: [Playlist]?

    var uploads: [Upload] { uploadsList ?? [] }
    var playlists: [Playlist] { playlistsList ?? [] }

    enum CodingKeys: String, CodingKey {
        case uploadsPlaylistId
        case uploadsNextPageToken
        case uploadsList = "uploads"
        case playlistsList = "playlists"
    }

    struct Upload: Codable {
        let id: String
        let title: String?
        let thumbnailUrl: String?
        let publishedAt: String?
        let durationSeconds: Int?
        let viewCount: Int?
        private let pastBroadcast: Bool?

        var isPastBroadcast: Bool { pastBroadcast ?? false }

        enum CodingKeys: String, CodingKey {
            case id, title, thumbnailUrl, publishedAt, durationSeconds, viewCount
            case pastBroadcast = "isPastBroadcast"
        }
    }

    struct Playlist: Codable {
        let id: String
        let title: String?
        let thumbnailUrl: String?
        let itemCount: Int?
        let description: String?

        var lessonPlaylist: LessonPlaylist {
            LessonPlaylist(
                id: id,
                title: title ?? "",
                thumbnailUrl: thumbnailUrl ?? "",
                itemCount: itemCount ?? 0,
                description: description ?? ""
            )
        }
    }
}

// MARK: - Cache Envelope

private struct CachedArtifact: Codable {
    let artifact: ChannelArtifact
    let etag: String?
    let fetchedAt: Date
}

// MARK: - Response Models

private struct YouTubeErrorResponse: Decodable {
    let error: ErrorBody?

    struct ErrorBody: Decodable {
        let errors: [Detail]?

        struct Detail: Decodable {
            let reason: String?
        }
    }
}

private struct YouTubePlaylistResponse: Decodable {
    let nextPageToken: String?
    let items: [PlaylistItem]

    struct PlaylistItem: Decodable {
        let id: String
        let snippet: Snippet?
        let contentDetails: ContentDetails?

        struct Snippet: Decodable {
            let title: String?
            let description: String?
            let thumbnails: Thumbnails?
        }

        struct ContentDetails: Decodable {
            let itemCount: Int?
        }
    }
}

private struct YouTubePlaylistItemsResponse: Decodable {
    let nextPageToken: String?
    let items: [PlaylistItemEntry]

    struct PlaylistItemEntry: Decodable {
        let snippet: Snippet?

        struct Snippet: Decodable {
            let title: String?
            let publishedAt: String?
            let thumbnails: Thumbnails?
            let resourceId: ResourceId?
            let videoOwnerChannelTitle: String?

            struct ResourceId: Decodable {
                let videoId: String?
            }
        }
    }
}

private struct YouTubeVideoDetailsResponse: Decodable {
    let items: [VideoItem]

    struct VideoItem: Decodable {
        let id: String
        let contentDetails: ContentDetails?
        let statistics: Statistics?
        let liveStreamingDetails: LiveStreamingDetails?

        struct ContentDetails: Decodable {
            let duration: String?
        }

        struct Statistics: Decodable {
            let viewCount: String?
        }

        struct LiveStreamingDetails: Decodable {
            let actualEndTime: String?
        }
    }
}

private struct Thumbnails: Decodable {
    let `default`: ThumbnailEntry?
    let medium: ThumbnailEntry?
    let high: ThumbnailEntry?

    var bestUrl: String? {
        high?.url ?? medium?.url ?? `default`?.url
    }

    struct ThumbnailEntry: Decodable {
        let url: String?
    }
}
