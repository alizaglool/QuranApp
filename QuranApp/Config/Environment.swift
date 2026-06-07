//
//  Environment.swift
//  QuranApp
//

import Foundation

enum AppConfig {
    static var youtubeApiKey: String {
        guard
            let key = Bundle.main.infoDictionary?["YoutubeApiKey"] as? String,
            !key.isEmpty
        else {
            assertionFailure("YoutubeApiKey missing — set YOUTUBE_API_KEY in Secrets.xcconfig")
            return ""
        }
        return key
    }
}
