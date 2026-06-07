//
//  PlaylistItemsViewModel.swift
//  QuranApp
//

import Foundation
import Core

@MainActor
final class PlaylistItemsViewModel: MainViewModel {

    @Published var videos: [LessonVideo] = []
    @Published var isLoading = false
    @Published var hasMore = false

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
        coordinator?.coordinateToPlayer(
            source: .video(id: video.id),
            title: video.title,
            sheikhName: sheikhName
        )
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
