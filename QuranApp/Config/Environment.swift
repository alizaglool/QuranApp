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

    /// Base URL of the GitHub-hosted remote config, injected from
    /// `REMOTE_CONFIG_BASE_URL` in Secrets.xcconfig via Info.plist.
    static var remoteConfigBaseURL: URL? {
        guard
            let value = Bundle.main.infoDictionary?["RemoteConfigBaseURL"] as? String,
            !value.isEmpty,
            let url = URL(string: value),
            url.scheme != nil
        else {
            assertionFailure("RemoteConfigBaseURL missing — set REMOTE_CONFIG_BASE_URL in Secrets.xcconfig")
            return nil
        }
        return url
    }
}
