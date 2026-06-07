//
//  LessonPlaylist.swift
//  Core
//

import Foundation

public struct LessonPlaylist: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let thumbnailUrl: String
    public let itemCount: Int

    public init(id: String, title: String, thumbnailUrl: String, itemCount: Int) {
        self.id = id
        self.title = title
        self.thumbnailUrl = thumbnailUrl
        self.itemCount = itemCount
    }
}
