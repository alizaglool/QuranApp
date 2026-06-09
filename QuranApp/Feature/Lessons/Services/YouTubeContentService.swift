//
//  YouTubeContentService.swift
//  QuranApp
//

import Foundation
import Core

final class YouTubeContentService {
    static let shared = YouTubeContentService()

    private var apiKey: String { AppConfig.youtubeApiKey }
    private let baseURL = "https://www.googleapis.com/youtube/v3"

    private init() {}

    // MARK: Playlists

    func fetchPlaylists(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonPlaylist], nextPageToken: String?) {
        var components = URLComponents(string: "\(baseURL)/playlists")!
        var queryItems: [URLQueryItem] = [
            .init(name: "part", value: "snippet,contentDetails"),
            .init(name: "channelId", value: channelId),
            .init(name: "maxResults", value: "50"),
            .init(name: "key", value: apiKey)
        ]
        if let token = pageToken {
            queryItems.append(.init(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(YouTubePlaylistResponse.self, from: data)

        let playlists = decoded.items.compactMap { item -> LessonPlaylist? in
            guard let snippet = item.snippet else { return nil }
            let thumbnail = snippet.thumbnails?.high?.url
                ?? snippet.thumbnails?.medium?.url
                ?? snippet.thumbnails?.default?.url
                ?? ""
            return LessonPlaylist(
                id: item.id,
                title: snippet.title ?? "",
                thumbnailUrl: thumbnail,
                itemCount: item.contentDetails?.itemCount ?? 0,
                description: snippet.description ?? ""
            )
        }

        return (playlists, decoded.nextPageToken)
    }

    // MARK: Videos (medium duration 4–20 min, distinct from Shorts)

    func fetchVideos(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        return try await fetchSearchResults(
            channelId: channelId,
            duration: "medium",
            pageToken: pageToken,
            isReel: false
        )
    }

    // MARK: Shorts (<4 min — YouTube Shorts)

    func fetchShorts(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        return try await fetchSearchResults(
            channelId: channelId,
            duration: "short",
            pageToken: pageToken,
            isReel: false
        )
    }

    // MARK: Podcasts (>20 min long-form content)

    func fetchPodcasts(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        return try await fetchSearchResults(
            channelId: channelId,
            duration: "long",
            pageToken: pageToken,
            isReel: false
        )
    }

    // MARK: Live (completed live streams)

    func fetchLive(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        var components = URLComponents(string: "\(baseURL)/search")!
        var queryItems: [URLQueryItem] = [
            .init(name: "part", value: "snippet"),
            .init(name: "channelId", value: channelId),
            .init(name: "type", value: "video"),
            .init(name: "eventType", value: "completed"),
            .init(name: "order", value: "date"),
            .init(name: "maxResults", value: "25"),
            .init(name: "key", value: apiKey)
        ]
        if let token = pageToken {
            queryItems.append(.init(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)

        let rawLive = decoded.items.compactMap { item -> LessonVideo? in
            guard
                let videoId = item.id.videoId,
                let snippet = item.snippet
            else { return nil }

            let thumbnail = snippet.thumbnails?.high?.url
                ?? snippet.thumbnails?.medium?.url
                ?? snippet.thumbnails?.default?.url
                ?? ""

            return LessonVideo(
                id: videoId,
                title: snippet.title ?? "",
                thumbnailUrl: thumbnail,
                publishedAt: snippet.publishedAt ?? "",
                channelTitle: snippet.channelTitle ?? "",
                isReel: false
            )
        }

        let enrichedLive = await enrichWithDetails(rawLive)
        return (enrichedLive, decoded.nextPageToken)
    }

    // MARK: Playlist Items

    func fetchPlaylistItems(playlistId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        var components = URLComponents(string: "\(baseURL)/playlistItems")!
        var queryItems: [URLQueryItem] = [
            .init(name: "part", value: "snippet"),
            .init(name: "playlistId", value: playlistId),
            .init(name: "maxResults", value: "50"),
            .init(name: "key", value: apiKey)
        ]
        if let token = pageToken {
            queryItems.append(.init(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(YouTubePlaylistItemsResponse.self, from: data)

        let rawItems = decoded.items.compactMap { item -> LessonVideo? in
            guard
                let snippet = item.snippet,
                let videoId = snippet.resourceId?.videoId,
                !videoId.isEmpty
            else { return nil }

            let thumbnail = snippet.thumbnails?.high?.url
                ?? snippet.thumbnails?.medium?.url
                ?? snippet.thumbnails?.default?.url
                ?? ""

            return LessonVideo(
                id: videoId,
                title: snippet.title ?? "",
                thumbnailUrl: thumbnail,
                publishedAt: snippet.publishedAt ?? "",
                channelTitle: "",
                isReel: false
            )
        }

        let enrichedItems = await enrichWithDetails(rawItems)
        return (enrichedItems, decoded.nextPageToken)
    }

    // MARK: Video Details Enrichment

    func enrichWithDetails(_ videos: [LessonVideo]) async -> [LessonVideo] {
        guard !videos.isEmpty else { return videos }
        let ids = videos.map { $0.id }.joined(separator: ",")
        var components = URLComponents(string: "\(baseURL)/videos")!
        components.queryItems = [
            .init(name: "part", value: "contentDetails,statistics"),
            .init(name: "id", value: ids),
            .init(name: "key", value: apiKey)
        ]
        guard let url = components.url,
              let (data, _) = try? await URLSession.shared.data(from: url),
              let decoded = try? JSONDecoder().decode(YouTubeVideoDetailsResponse.self, from: data)
        else { return videos }

        var detailsMap: [String: (String?, Int?)] = [:]
        for item in decoded.items {
            let dur = item.contentDetails?.duration.flatMap { parseDuration($0) }
            let views = item.statistics?.viewCount.flatMap { Int($0) }
            detailsMap[item.id] = (dur, views)
        }

        return videos.map { video in
            guard let details = detailsMap[video.id] else { return video }
            return LessonVideo(
                id: video.id,
                title: video.title,
                thumbnailUrl: video.thumbnailUrl,
                publishedAt: video.publishedAt,
                channelTitle: video.channelTitle,
                isReel: video.isReel,
                duration: details.0,
                viewCount: details.1
            )
        }
    }

    private func parseDuration(_ iso: String) -> String? {
        var hours = 0, minutes = 0, seconds = 0
        var current = ""
        for char in iso {
            if char.isNumber {
                current.append(char)
            } else if char == "H" {
                hours = Int(current) ?? 0; current = ""
            } else if char == "M" {
                minutes = Int(current) ?? 0; current = ""
            } else if char == "S" {
                seconds = Int(current) ?? 0; current = ""
            }
        }
        guard hours > 0 || minutes > 0 || seconds > 0 else { return nil }
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: Private

    private func fetchSearchResults(
        channelId: String,
        duration: String,
        pageToken: String?,
        isReel: Bool
    ) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        var components = URLComponents(string: "\(baseURL)/search")!
        var queryItems: [URLQueryItem] = [
            .init(name: "part", value: "snippet"),
            .init(name: "channelId", value: channelId),
            .init(name: "type", value: "video"),
            .init(name: "videoDuration", value: duration),
            .init(name: "order", value: "date"),
            .init(name: "maxResults", value: "25"),
            .init(name: "key", value: apiKey)
        ]
        if let token = pageToken {
            queryItems.append(.init(name: "pageToken", value: token))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)

        let raw = decoded.items.compactMap { item -> LessonVideo? in
            guard
                let videoId = item.id.videoId,
                let snippet = item.snippet
            else { return nil }

            let thumbnail = snippet.thumbnails?.high?.url
                ?? snippet.thumbnails?.medium?.url
                ?? snippet.thumbnails?.default?.url
                ?? ""

            return LessonVideo(
                id: videoId,
                title: snippet.title ?? "",
                thumbnailUrl: thumbnail,
                publishedAt: snippet.publishedAt ?? "",
                channelTitle: snippet.channelTitle ?? "",
                isReel: isReel
            )
        }

        let enriched = await enrichWithDetails(raw)
        return (enriched, decoded.nextPageToken)
    }
}

// MARK: - Response Models

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

private struct YouTubeSearchResponse: Decodable {
    let nextPageToken: String?
    let items: [SearchItem]

    struct SearchItem: Decodable {
        let id: ItemId
        let snippet: Snippet?

        struct ItemId: Decodable {
            let videoId: String?
        }

        struct Snippet: Decodable {
            let title: String?
            let publishedAt: String?
            let channelTitle: String?
            let thumbnails: Thumbnails?
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

            struct ResourceId: Decodable {
                let videoId: String?
            }
        }
    }
}

private struct Thumbnails: Decodable {
    let `default`: ThumbnailEntry?
    let medium: ThumbnailEntry?
    let high: ThumbnailEntry?

    struct ThumbnailEntry: Decodable {
        let url: String?
    }
}

private struct YouTubeVideoDetailsResponse: Decodable {
    let items: [VideoItem]

    struct VideoItem: Decodable {
        let id: String
        let contentDetails: ContentDetails?
        let statistics: Statistics?

        struct ContentDetails: Decodable {
            let duration: String?
        }

        struct Statistics: Decodable {
            let viewCount: String?
        }
    }
}
