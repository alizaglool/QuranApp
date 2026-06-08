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

    enum PlayerType {
        case regular
        case short
    }

    let source: PlayerSource
    let title: String
    let sheikhName: String
    let playerType: PlayerType
    let player: YouTubePlayer

    var isTabBarVisible: Bool { false }

    init(source: PlayerSource, title: String, sheikhName: String, playerType: PlayerType = .regular) {
        self.source = source
        self.title = title
        self.sheikhName = sheikhName
        self.playerType = playerType
        self.player = Self.makePlayer(from: source, playerType: playerType)
    }

    func onAppear() {}
    func onDisappear() {}

    private static func makePlayer(from source: PlayerSource, playerType: PlayerType) -> YouTubePlayer {
        let ytSource: YouTubePlayer.Source
        switch source {
        case .video(let id):
            ytSource = .video(id: id)
        case .playlist(let id):
            ytSource = .playlist(id: id)
        }
        
        let playInline = playerType == .regular
        return YouTubePlayer(
            source: ytSource,
            configuration: .init(
                fullscreenMode: .system,
                autoPlay: true,
                showFullscreenButton: true,
                playInline: playInline
            )
        )
    }
}
