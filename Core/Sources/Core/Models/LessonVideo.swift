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

    public init(
        id: String,
        title: String,
        thumbnailUrl: String,
        publishedAt: String,
        channelTitle: String,
        isReel: Bool = false
    ) {
        self.id = id
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.publishedAt = publishedAt
        self.channelTitle = channelTitle
        self.isReel = isReel
    }
}
