//
//  PlaylistItemsViewModel.swift
//  QuranApp
//

import Foundation
import Core
import YouTubePlayerKit

@MainActor
final class PlaylistItemsViewModel: MainViewModel {

    @Published var videos: [LessonVideo] = []
    @Published var isLoading = false
    @Published var hasMore = false
    @Published var nowPlayingVideoId: String?
    @Published var player: YouTubePlayer?

    let playlist: LessonPlaylist
    let sheikhName: String
    weak var coordinator: (any LessonsCoordinating)?

    private var pageToken: String? = nil
    var isTabBarVisible: Bool { false }

    init(playlist: LessonPlaylist, sheikhName: String, coordinator: (any LessonsCoordinating)?) {
        self.playlist = playlist
        self.sheikhName = sheikhName
        self.coordinator = coordinator
    }

    func onAppear() {
        guard videos.isEmpty else { return }
        Task { await fetchItems() }
    }

    func onDisappear() {}

    func loadMore() {
        guard !isLoading, hasMore else { return }
        Task { await fetchItems() }
    }

    func onVideoTapped(_ video: LessonVideo) {
        nowPlayingVideoId = video.id
        if let existing = player {
            existing.source = .video(id: video.id)
        } else {
            player = YouTubePlayer(
                source: .video(id: video.id),
                configuration: .init(
                    fullscreenMode: .system,
                    autoPlay: true,
                    showFullscreenButton: true,
                    playInline: true
                )
            )
        }
    }

    private func fetchItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await YouTubeContentService.shared.fetchPlaylistItems(
                playlistId: playlist.id,
                pageToken: pageToken
            )
            videos.append(contentsOf: result.items)
            pageToken = result.nextPageToken
            hasMore = result.nextPageToken != nil
        } catch {}
    }
}
