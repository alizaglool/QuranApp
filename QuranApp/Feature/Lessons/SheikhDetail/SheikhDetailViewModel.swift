//
//  SheikhDetailViewModel.swift
//  QuranApp
//

import Foundation
import Core

enum SheikhDetailTab: String, CaseIterable {
    case playlists = "قوائم التشغيل"
    case videos    = "فيديوهات"
    case shorts    = "شورتس"
    case podcasts  = "بودكاست"
    case live      = "مباشر"

    var localizedTitle: String {
        switch self {
        case .playlists: return AppLocalizedKeys.detailTabPlaylists.value
        case .videos:    return AppLocalizedKeys.detailTabVideos.value
        case .shorts:    return AppLocalizedKeys.detailTabShorts.value
        case .podcasts:  return AppLocalizedKeys.detailTabPodcasts.value
        case .live:      return AppLocalizedKeys.detailTabLive.value
        }
    }
}

@MainActor
final class SheikhDetailViewModel: MainViewModel {

    @Published var selectedTab: SheikhDetailTab = .playlists

    // Playlists
    @Published var playlists: [LessonPlaylist] = []
    @Published var isLoadingPlaylists = false
    @Published var hasMorePlaylists   = false

    // Videos
    @Published var videos: [LessonVideo] = []
    @Published var isLoadingVideos = false
    @Published var hasMoreVideos   = false

    // Shorts
    @Published var shorts: [LessonVideo] = []
    @Published var isLoadingShorts = false
    @Published var hasMoreShorts   = false
    @Published var showShortsPlayer = false
    @Published var shortsStartIndex = 0

    // Podcasts
    @Published var podcasts: [LessonVideo] = []
    @Published var isLoadingPodcasts = false
    @Published var hasMorePodcasts   = false

    // Live
    @Published var liveVideos: [LessonVideo] = []
    @Published var isLoadingLive = false
    @Published var hasMoreLive   = false

    let sheikh: Sheikh
    weak var coordinator: (any LessonsCoordinating)?

    private var playlistsPageToken: String? = nil
    private var videosPageToken: String?    = nil
    private var shortsPageToken: String?    = nil
    private var podcastsPageToken: String?  = nil
    private var livePageToken: String?      = nil

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

    func loadMoreShorts() {
        guard !isLoadingShorts, hasMoreShorts else { return }
        Task { await fetchShorts() }
    }

    func loadMorePodcasts() {
        guard !isLoadingPodcasts, hasMorePodcasts else { return }
        Task { await fetchPodcasts() }
    }

    func loadMoreLive() {
        guard !isLoadingLive, hasMoreLive else { return }
        Task { await fetchLive() }
    }

    // MARK: Navigation

    func onPlaylistTapped(_ playlist: LessonPlaylist) {
        coordinator?.coordinateToPlaylistItems(playlist: playlist, sheikhName: sheikh.name)
    }

    func onVideoTapped(_ video: LessonVideo) {
        coordinator?.coordinateToPlayer(
            source: .video(id: video.id),
            title: video.title,
            sheikhName: sheikh.name,
            playerType: .regular,
            relatedVideos: videos
        )
    }

    func onShortTapped(_ video: LessonVideo) {
        guard let index = shorts.firstIndex(where: { $0.id == video.id }) else { return }
        shortsStartIndex = index
        showShortsPlayer = true
    }

    // MARK: Private

    private func loadTabIfNeeded(_ tab: SheikhDetailTab) {
        guard !loadedTabs.contains(tab) else { return }
        loadedTabs.insert(tab)
        switch tab {
        case .playlists: Task { await fetchPlaylists() }
        case .videos:    Task { await fetchVideos() }
        case .shorts:    Task { await fetchShorts() }
        case .podcasts:  Task { await fetchPodcasts() }
        case .live:      Task { await fetchLive() }
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

    private func fetchShorts() async {
        isLoadingShorts = true
        defer { isLoadingShorts = false }
        do {
            let result = try await YouTubeContentService.shared.fetchShorts(
                channelId: sheikh.id,
                pageToken: shortsPageToken
            )
            shorts.append(contentsOf: result.items)
            shortsPageToken = result.nextPageToken
            hasMoreShorts = result.nextPageToken != nil
        } catch {}
    }

    private func fetchPodcasts() async {
        isLoadingPodcasts = true
        defer { isLoadingPodcasts = false }
        do {
            let result = try await YouTubeContentService.shared.fetchPodcasts(
                channelId: sheikh.id,
                pageToken: podcastsPageToken
            )
            podcasts.append(contentsOf: result.items)
            podcastsPageToken = result.nextPageToken
            hasMorePodcasts = result.nextPageToken != nil
        } catch {}
    }

    private func fetchLive() async {
        isLoadingLive = true
        defer { isLoadingLive = false }
        do {
            let result = try await YouTubeContentService.shared.fetchLive(
                channelId: sheikh.id,
                pageToken: livePageToken
            )
            liveVideos.append(contentsOf: result.items)
            livePageToken = result.nextPageToken
            hasMoreLive = result.nextPageToken != nil
        } catch {}
    }
}
