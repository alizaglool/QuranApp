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
                itemCount: item.contentDetails?.itemCount ?? 0
            )
        }

        return (playlists, decoded.nextPageToken)
    }

    // MARK: Videos (medium + long duration)

    func fetchVideos(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        return try await fetchSearchResults(
            channelId: channelId,
            duration: "medium,long",
            pageToken: pageToken,
            isReel: false
        )
    }

    // MARK: Reels (short duration)

    func fetchReels(channelId: String, pageToken: String? = nil) async throws -> (items: [LessonVideo], nextPageToken: String?) {
        return try await fetchSearchResults(
            channelId: channelId,
            duration: "short",
            pageToken: pageToken,
            isReel: true
        )
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

        let videos = decoded.items.compactMap { item -> LessonVideo? in
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

        return (videos, decoded.nextPageToken)
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

private struct Thumbnails: Decodable {
    let `default`: ThumbnailEntry?
    let medium: ThumbnailEntry?
    let high: ThumbnailEntry?

    struct ThumbnailEntry: Decodable {
        let url: String?
    }
}
