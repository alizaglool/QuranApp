//
//  LessonVideo.swift
//  Core
//

import Foundation

public struct LessonVideo: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let thumbnailUrl: String
    public let publishedAt: String
    public let channelTitle: String
    public let isReel: Bool
    public let duration: String?
    public let viewCount: Int?

    public init(
        id: String,
        title: String,
        thumbnailUrl: String,
        publishedAt: String,
        channelTitle: String,
        isReel: Bool = false,
        duration: String? = nil,
        viewCount: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.publishedAt = publishedAt
        self.channelTitle = channelTitle
        self.isReel = isReel
        self.duration = duration
        self.viewCount = viewCount
    }
}

public extension LessonVideo {
    var formattedViewCount: String? {
        guard let count = viewCount, count > 0 else { return nil }
        if count >= 1_000_000 {
            let v = Double(count) / 1_000_000
            return String(format: v.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fM" : "%.1fM", v)
        } else if count >= 1_000 {
            let v = Double(count) / 1_000
            return String(format: v.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fK" : "%.1fK", v)
        }
        return "\(count)"
    }
}
