//
//  SheikhDetailViewModel.swift
//  QuranApp
//

import Foundation
import Core

enum SheikhDetailTab: String, CaseIterable {
    case playlists = "قوائم التشغيل"
    case videos    = "فيديوهات"
    case reels     = "ريلز"
}

@MainActor
final class SheikhDetailViewModel: MainViewModel {

    @Published var selectedTab: SheikhDetailTab = .playlists
    @Published var playlists: [LessonPlaylist] = []
    @Published var videos: [LessonVideo] = []
    @Published var reels: [LessonVideo] = []
    @Published var isLoadingPlaylists = false
    @Published var isLoadingVideos    = false
    @Published var isLoadingReels     = false
    @Published var hasMorePlaylists   = false
    @Published var hasMoreVideos      = false
    @Published var hasMoreReels       = false

    let sheikh: Sheikh
    weak var coordinator: (any LessonsCoordinating)?

    private var playlistsPageToken: String? = nil
    private var videosPageToken: String?    = nil
    private var reelsPageToken: String?     = nil

    private var loadedTabs: Set<SheikhDetailTab> = []

    var isTabBarVisible: Bool { false }

    init(sheikh: Sheikh, coordinator: (any LessonsCoordinating)?) {
        self.sheikh = sheikh
        self.coordinator = coordinator
    }

    func onAppear() {
        loadTabIfNeeded(.playlists)
    }

    func onDisappear() {}

    func onTabSelected(_ tab: SheikhDetailTab) {
        selectedTab = tab
        loadTabIfNeeded(tab)
    }

    // MARK: Load More

    func loadMorePlaylists() {
        guard !isLoadingPlaylists, hasMorePlaylists else { return }
        Task { await fetchPlaylists() }
    }

    func loadMoreVideos() {
        guard !isLoadingVideos, hasMoreVideos else { return }
        Task { await fetchVideos() }
    }

    func loadMoreReels() {
        guard !isLoadingReels, hasMoreReels else { return }
        Task { await fetchReels() }
    }

    // MARK: Navigation

    func onPlaylistTapped(_ playlist: LessonPlaylist) {
        coordinator?.coordinateToPlayer(
            source: .playlist(id: playlist.id),
            title: playlist.title,
            sheikhName: sheikh.name
        )
    }

    func onVideoTapped(_ video: LessonVideo) {
        coordinator?.coordinateToPlayer(
            source: .video(id: video.id),
            title: video.title,
            sheikhName: sheikh.name
        )
    }

    // MARK: Private

    private func loadTabIfNeeded(_ tab: SheikhDetailTab) {
        guard !loadedTabs.contains(tab) else { return }
        loadedTabs.insert(tab)
        switch tab {
        case .playlists: Task { await fetchPlaylists() }
        case .videos:    Task { await fetchVideos() }
        case .reels:     Task { await fetchReels() }
        }
    }

    private func fetchPlaylists() async {
        isLoadingPlaylists = true
        defer { isLoadingPlaylists = false }
        do {
            let result = try await YouTubeContentService.shared.fetchPlaylists(
                channelId: sheikh.id,
                pageToken: playlistsPageToken
            )
            playlists.append(contentsOf: result.items)
            playlistsPageToken = result.nextPageToken
            hasMorePlaylists = result.nextPageToken != nil
        } catch {}
    }

    private func fetchVideos() async {
        isLoadingVideos = true
        defer { isLoadingVideos = false }
        do {
            let result = try await YouTubeContentService.shared.fetchVideos(
                channelId: sheikh.id,
                pageToken: videosPageToken
            )
            videos.append(contentsOf: result.items)
            videosPageToken = result.nextPageToken
            hasMoreVideos = result.nextPageToken != nil
        } catch {}
    }

    private func fetchReels() async {
        isLoadingReels = true
        defer { isLoadingReels = false }
        do {
            let result = try await YouTubeContentService.shared.fetchReels(
                channelId: sheikh.id,
                pageToken: reelsPageToken
            )
            reels.append(contentsOf: result.items)
            reelsPageToken = result.nextPageToken
            hasMoreReels = result.nextPageToken != nil
        } catch {}
    }
}
