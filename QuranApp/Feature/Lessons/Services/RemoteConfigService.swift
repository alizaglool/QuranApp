//
//  RemoteConfigService.swift
//  QuranApp
//

import Foundation

final class RemoteConfigService {
    static let shared = RemoteConfigService()

    // Google Sheets published-to-web CSV URL
    // Sheet: https://docs.google.com/spreadsheets/d/1yrQFXcEoAuakuDljBrWR40bJMebmjyJGIBt3dj9hZNs
    private let configURL = "https://docs.google.com/spreadsheets/d/1yrQFXcEoAuakuDljBrWR40bJMebmjyJGIBt3dj9hZNs/pub?output=csv&gid=52017434"
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
            let ids = try parseChannelIds(from: data)
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

    // MARK: - CSV Parsing

    private func parseChannelIds(from data: Data) throws -> [String] {
        guard let csv = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }

        var ids: [String] = []
        let rows = csv.components(separatedBy: "\n")

        for row in rows {
            let cols = row.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            // Find the column that contains a YouTube channel ID (starts with "UC", 24 chars)
            if let id = cols.first(where: { $0.hasPrefix("UC") && $0.count == 24 }) {
                ids.append(id)
            }
        }

        guard !ids.isEmpty else {
            throw URLError(.cannotParseResponse)
        }

        return ids
    }

    // MARK: - Cache

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
