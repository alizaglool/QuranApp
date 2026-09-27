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
    let sheikhName: String
    let playerType: PlayerType
    let player: YouTubePlayer

    @Published var currentTitle: String
    @Published var nowPlayingId: String?
    @Published var relatedVideos: [LessonVideo]

    var isTabBarVisible: Bool { false }

    init(
        source: PlayerSource,
        title: String,
        sheikhName: String,
        playerType: PlayerType = .regular,
        relatedVideos: [LessonVideo] = []
    ) {
        self.source = source
        self.sheikhName = sheikhName
        self.playerType = playerType
        self.currentTitle = title
        self.relatedVideos = relatedVideos
        self.player = Self.makePlayer(from: source, playerType: playerType)

        if case .video(let id) = source {
            self.nowPlayingId = id
            self.relatedVideos = relatedVideos.filter { $0.id != id }
        }
    }

    func onAppear() {}
    func onDisappear() {}

    func onRelatedVideoTapped(_ video: LessonVideo) {
        currentTitle = video.title
        nowPlayingId = video.id
        player.source = .video(id: video.id)
    }

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
