//
//  LessonPlayerViewModel.swift
//  QuranApp
//

import Foundation
import YouTubePlayerKit
import Core

@MainActor
final class LessonPlayerViewModel: MainViewModel {

    enum PlayerSource {
        case playlist(id: String)
        case video(id: String)
    }

    let source: PlayerSource
    let title: String
    let sheikhName: String
    let player: YouTubePlayer

    var isTabBarVisible: Bool { false }

    init(source: PlayerSource, title: String, sheikhName: String) {
        self.source = source
        self.title = title
        self.sheikhName = sheikhName
        self.player = Self.makePlayer(from: source)
    }

    func onAppear() {}
    func onDisappear() {}

    private static func makePlayer(from source: PlayerSource) -> YouTubePlayer {
        let ytSource: YouTubePlayer.Source
        switch source {
        case .video(let id):
            ytSource = .video(id: id)
        case .playlist(let id):
            ytSource = .playlist(id: id)
        }
        return YouTubePlayer(
            source: ytSource,
            configuration: .init(autoPlay: true, playInline: false)
        )
    }
}
