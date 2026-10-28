//
//  FeaturedSheikhsCache.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 21/10/2026.
//

import Foundation
import Core

final class FeaturedSheikhsCache {

    static let shared = FeaturedSheikhsCache()

    private static let fileName = "home-featured-sheikhs.json"

    private let cacheFileURL: URL? = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)
        .first?
        .appendingPathComponent(FeaturedSheikhsCache.fileName)
}

// MARK: - Access

extension FeaturedSheikhsCache {

    func storedSheikhs() -> [Sheikh] {
        guard
            let cacheFileURL,
            let data = try? Data(contentsOf: cacheFileURL),
            let entry = try? JSONDecoder().decode(CachedFeaturedSheikhs.self, from: data)
        else { return [] }

        return entry.sheikhs
    }

    func store(_ sheikhs: [Sheikh]) {
        guard
            !sheikhs.isEmpty,
            let cacheFileURL,
            let data = try? JSONEncoder().encode(CachedFeaturedSheikhs(sheikhs: sheikhs, savedAt: Date()))
        else { return }

        try? data.write(to: cacheFileURL, options: .atomic)
    }
}

// MARK: - Entry

private struct CachedFeaturedSheikhs: Codable {
    let sheikhs: [Sheikh]
    let savedAt: Date
}
