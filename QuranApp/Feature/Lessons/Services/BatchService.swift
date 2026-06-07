//
//  BatchService.swift
//  QuranApp
//

import Foundation
import Core

final class BatchService {
    static let shared = BatchService()
    private init() {}

    func fetchSheikhs(from channelIds: [String]) async throws -> [Sheikh] {
        let chunks = channelIds.chunked(into: 50)

        return try await withThrowingTaskGroup(of: [Sheikh].self) { group in
            for chunk in chunks {
                group.addTask {
                    try await YouTubeChannelService.shared.fetchChannels(ids: chunk)
                }
            }
            var result: [Sheikh] = []
            for try await sheikhs in group {
                result.append(contentsOf: sheikhs)
            }
            return result
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
