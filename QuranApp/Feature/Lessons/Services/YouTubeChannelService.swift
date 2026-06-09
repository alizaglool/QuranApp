//
//  YouTubeChannelService.swift
//  QuranApp
//

import Foundation
import Core

final class YouTubeChannelService {
    static let shared = YouTubeChannelService()

    private var apiKey: String { AppConfig.youtubeApiKey }
    private let baseURL = "https://www.googleapis.com/youtube/v3"

    private init() {}

    func fetchChannels(ids: [String]) async throws -> [Sheikh] {
        let joinedIds = ids.joined(separator: ",")
        var components = URLComponents(string: "\(baseURL)/channels")!
        components.queryItems = [
            .init(name: "part", value: "snippet,statistics,brandingSettings"),
            .init(name: "id", value: joinedIds),
            .init(name: "key", value: apiKey)
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(YouTubeChannelResponse.self, from: data)
        return decoded.items.compactMap { item in
            guard
                let snippet = item.snippet,
                let statistics = item.statistics
            else { return nil }

            let thumbnail = snippet.thumbnails?.high?.url
                ?? snippet.thumbnails?.medium?.url
                ?? snippet.thumbnails?.default?.url
                ?? ""

            let subscribers = Int(statistics.subscriberCount ?? "0") ?? 0
            let videos = Int(statistics.videoCount ?? "0") ?? 0
            let banner = item.brandingSettings?.image?.bannerExternalUrl ?? ""

            return Sheikh(
                id: item.id,
                name: snippet.title ?? "",
                thumbnailUrl: thumbnail,
                bannerImageUrl: banner,
                subscriberCount: subscribers,
                videoCount: videos,
                channelHandle: snippet.customUrl ?? "",
                channelDescription: snippet.description ?? ""
            )
        }
    }
}

// MARK: - Response Models

private struct YouTubeChannelResponse: Decodable {
    let items: [YouTubeChannelItem]
}

private struct YouTubeChannelItem: Decodable {
    let id: String
    let snippet: Snippet?
    let statistics: Statistics?
    let brandingSettings: BrandingSettings?

    struct Snippet: Decodable {
        let title: String?
        let description: String?
        let customUrl: String?
        let thumbnails: Thumbnails?
    }

    struct Thumbnails: Decodable {
        let `default`: ThumbnailEntry?
        let medium: ThumbnailEntry?
        let high: ThumbnailEntry?
    }

    struct ThumbnailEntry: Decodable {
        let url: String?
    }

    struct Statistics: Decodable {
        let subscriberCount: String?
        let videoCount: String?
    }

    struct BrandingSettings: Decodable {
        let image: BrandingImage?

        struct BrandingImage: Decodable {
            let bannerExternalUrl: String?
        }
    }
}
