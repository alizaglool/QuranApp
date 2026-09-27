//
//  BatchService.swift
//  QuranApp
//

import Foundation
import Core

final class BatchService {
    static let shared = BatchService()
    private init() {}

    func fetchSheikhs(from channels: [SheikhChannel]) async throws -> [Sheikh] {
        let chunks = channels.chunked(into: 50)

        let fetched = try await withThrowingTaskGroup(of: [Sheikh].self) { group in
            for chunk in chunks {
                let ids = chunk.map(\.id)
                group.addTask {
                    try await YouTubeChannelService.shared.fetchChannels(ids: ids)
                }
            }
            var result: [Sheikh] = []
            for try await sheikhs in group {
                result.append(contentsOf: sheikhs)
            }
            return result
        }

        return applyCuratedNames(to: fetched, from: channels)
    }

    // MARK: - Private

    /// YouTube's `snippet.title` follows whatever the channel owner renames to,
    /// so a rename would silently change the displayed list. The curated name
    /// from remote config wins whenever one is published.
    private func applyCuratedNames(to sheikhs: [Sheikh], from channels: [SheikhChannel]) -> [Sheikh] {
        let curatedNames = Dictionary(
            channels.map { ($0.id, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )

        return sheikhs.map { sheikh in
            let curated = curatedNames[sheikh.id]?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !curated.isEmpty else { return sheikh }

            // Every stored property must be forwarded by hand here: the init has
            // defaults, so a field left out compiles cleanly and silently resets.
            return Sheikh(
                id: sheikh.id,
                uploadsPlaylistId: sheikh.uploadsPlaylistId,
                name: curated,
                thumbnailUrl: sheikh.thumbnailUrl,
                bannerImageUrl: sheikh.bannerImageUrl,
                subscriberCount: sheikh.subscriberCount,
                videoCount: sheikh.videoCount,
                channelHandle: sheikh.channelHandle,
                channelDescription: sheikh.channelDescription
            )
        }
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
