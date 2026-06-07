//
//  RemoteConfigService.swift
//  QuranApp
//

import Foundation

final class RemoteConfigService {
    static let shared = RemoteConfigService()

    private let configURL = "https://raw.githubusercontent.com/alizaglool/hadith-books/main/config/channels_config.json"
    private let cacheKey = "lessons_channel_ids_cache"
    private let cacheTimestampKey = "lessons_channel_ids_cache_timestamp"
    private let cacheTTL: TimeInterval = 3600

    private init() {}

    func fetchChannelIds() async throws -> [String] {
        if let cached = loadFromCache() {
            return cached
        }

        guard let url = URL(string: configURL) else {
            throw URLError(.badURL)
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ChannelsConfig.self, from: data)
            let ids = response.channelIds
            saveToCache(ids)
            return ids
        } catch {
            if let fallback = loadFromCacheIgnoringTTL() {
                return fallback
            }
            throw error
        }
    }

    func invalidateCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheTimestampKey)
    }

    private func loadFromCache() -> [String]? {
        guard
            let timestamp = UserDefaults.standard.object(forKey: cacheTimestampKey) as? Date,
            Date().timeIntervalSince(timestamp) < cacheTTL,
            let ids = UserDefaults.standard.stringArray(forKey: cacheKey)
        else { return nil }
        return ids
    }

    private func loadFromCacheIgnoringTTL() -> [String]? {
        UserDefaults.standard.stringArray(forKey: cacheKey)
    }

    private func saveToCache(_ ids: [String]) {
        UserDefaults.standard.set(ids, forKey: cacheKey)
        UserDefaults.standard.set(Date(), forKey: cacheTimestampKey)
    }
}

private struct ChannelsConfig: Decodable {
    let channelIds: [String]
}
