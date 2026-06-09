//
//  Sheikh.swift
//  Core
//

import Foundation

public struct Sheikh: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let thumbnailUrl: String
    public let bannerImageUrl: String
    public let subscriberCount: Int
    public let videoCount: Int
    public let channelHandle: String
    public let channelDescription: String

    public init(
        id: String,
        name: String,
        thumbnailUrl: String,
        bannerImageUrl: String = "",
        subscriberCount: Int,
        videoCount: Int,
        channelHandle: String,
        channelDescription: String
    ) {
        self.id = id
        self.name = name
        self.thumbnailUrl = thumbnailUrl
        self.bannerImageUrl = bannerImageUrl
        self.subscriberCount = subscriberCount
        self.videoCount = videoCount
        self.channelHandle = channelHandle
        self.channelDescription = channelDescription
    }

    public static func == (lhs: Sheikh, rhs: Sheikh) -> Bool { lhs.id == rhs.id }
}

public extension Sheikh {
    var formattedSubscriberCount: String {
        let count = subscriberCount
        if count >= 1_000_000 {
            let value = Double(count) / 1_000_000
            return String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fM" : "%.1fM", value)
        } else if count >= 1_000 {
            let value = Double(count) / 1_000
            return String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0fK" : "%.1fK", value)
        }
        return "\(count)"
    }
}
