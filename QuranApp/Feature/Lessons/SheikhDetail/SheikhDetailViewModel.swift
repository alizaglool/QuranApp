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
    @Published var isDescriptionExpanded = false

    // Playlists
    @Published var playlists: [LessonPlaylist] = []
    @Published var isLoadingPlaylists = false
    @Published var hasMorePlaylists   = false
    @Published var playlistsError: String?

    // Videos
    @Published var videos: [LessonVideo] = []
    @Published var isLoadingVideos = false
    @Published var hasMoreVideos   = false
    @Published var videosError: String?

    // Shorts
    @Published var shorts: [LessonVideo] = []
    @Published var isLoadingShorts = false
    @Published var hasMoreShorts   = false
    @Published var shortsError: String?
    @Published var showShortsPlayer = false
    @Published var shortsStartIndex = 0

    // Podcasts
    @Published var podcasts: [LessonVideo] = []
    @Published var isLoadingPodcasts = false
    @Published var hasMorePodcasts   = false
    @Published var podcastsError: String?

    // Live
    @Published var liveVideos: [LessonVideo] = []
    @Published var isLoadingLive = false
    @Published var hasMoreLive   = false
    @Published var liveError: String?

    let sheikh: Sheikh
    weak var coordinator: (any LessonsCoordinating)?

    private var playlistsPageToken: String? = nil
    private var videosPageToken: String?    = nil
    private var shortsPageToken: String?    = nil
    private var podcastsPageToken: String?  = nil
    private var livePageToken: String?      = nil

    private var videosSeenIds: Set<String>   = []
    private var shortsSeenIds: Set<String>   = []
    private var podcastsSeenIds: Set<String> = []
    private var liveSeenIds: Set<String>     = []

    private var loadedTabs: Set<SheikhDetailTab> = []

    var isTabBarVisible: Bool { false }

    /// Localized strings are resolved here, never in the view.
    var descriptionToggleTitle: String {
        isDescriptionExpanded ? AppLocalizedKeys.showLess.value : AppLocalizedKeys.showMore.value
    }

    var descriptionToggleHint: String {
        isDescriptionExpanded ? AppLocalizedKeys.showLessHint.value : AppLocalizedKeys.showMoreHint.value
    }

    var retryTitle: String { AppLocalizedKeys.retryAction.value }

    var loadMoreTitle: String { AppLocalizedKeys.lessonsLoadMore.value }

    /// Auto-paging stopped because this page held nothing for the bucket.
    /// The token is still good, so offer the user the next page by hand
    /// rather than showing an empty tab that is not the whole story.
    var canResumeVideos: Bool   { videosPageToken   != nil && videos.isEmpty }
    var canResumeShorts: Bool   { shortsPageToken   != nil && shorts.isEmpty }
    var canResumePodcasts: Bool { podcastsPageToken != nil && podcasts.isEmpty }
    var canResumeLive: Bool     { livePageToken     != nil && liveVideos.isEmpty }

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

    func onToggleDescription() {
        isDescriptionExpanded.toggle()
    }
}

// MARK: - Paging

extension SheikhDetailViewModel {

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

    /// A failed page clears `hasMore` so the pagination trigger stops firing.
    /// This is the only way back in.
    func onRetryTapped(_ tab: SheikhDetailTab) {
        loadedTabs.insert(tab)
        switch tab {
        case .playlists:
            guard !isLoadingPlaylists else { return }
            Task { await fetchPlaylists() }
        case .videos:
            guard !isLoadingVideos else { return }
            Task { await fetchVideos() }
        case .shorts:
            guard !isLoadingShorts else { return }
            Task { await fetchShorts() }
        case .podcasts:
            guard !isLoadingPodcasts else { return }
            Task { await fetchPodcasts() }
        case .live:
            guard !isLoadingLive else { return }
            Task { await fetchLive() }
        }
    }

    /// `loadMoreX` refuses once `hasMore` is cleared, which is exactly the state
    /// a sparse bucket parks in. This is the user-initiated way past it.
    func onLoadMoreTapped(_ tab: SheikhDetailTab) {
        switch tab {
        case .playlists:
            guard !isLoadingPlaylists else { return }
            Task { await fetchPlaylists() }
        case .videos:
            guard !isLoadingVideos else { return }
            Task { await fetchVideos() }
        case .shorts:
            guard !isLoadingShorts else { return }
            Task { await fetchShorts() }
        case .podcasts:
            guard !isLoadingPodcasts else { return }
            Task { await fetchPodcasts() }
        case .live:
            guard !isLoadingLive else { return }
            Task { await fetchLive() }
        }
    }
}

// MARK: - Navigation

extension SheikhDetailViewModel {

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
}

// MARK: - Loading

private extension SheikhDetailViewModel {

    enum ContentOutcome {
        case success(items: [LessonVideo], nextPageToken: String?)
        case failure(String)
    }

    func loadTabIfNeeded(_ tab: SheikhDetailTab) {
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

    func fetchPlaylists() async {
        isLoadingPlaylists = true
        playlistsError = nil
        do {
            let result = try await YouTubeContentService.shared.fetchPlaylists(
                channelId: sheikh.id,
                pageToken: playlistsPageToken
            )
            playlists.append(contentsOf: result.items)
            playlistsPageToken = result.nextPageToken
            hasMorePlaylists = result.nextPageToken != nil
        } catch {
            // A channel whose playlists are all private returns an empty list,
            // not an error — reaching here means the request itself failed.
            print("❌ SheikhDetail playlists failed for \(sheikh.id): \(error)")
            hasMorePlaylists = false
            playlistsError = errorMessage(for: error)
        }
        isLoadingPlaylists = false
    }

    func fetchVideos() async {
        isLoadingVideos = true
        videosError = nil
        switch await loadBucket(.videos, pageToken: videosPageToken) {
        case .success(let items, let next):
            let fresh = appendUnique(items, to: &videos, seen: &videosSeenIds)
            videosPageToken = next
            // A page that yields nothing for this bucket still carries a live
            // token. Auto-paging on it walks the entire channel unattended, so
            // continuing is the user's call from here — see `canResumeVideos`.
            hasMoreVideos = next != nil && !fresh.isEmpty
        case .failure(let message):
            hasMoreVideos = false
            videosError = message
        }
        isLoadingVideos = false
    }

    func fetchShorts() async {
        isLoadingShorts = true
        shortsError = nil
        switch await loadBucket(.shorts, pageToken: shortsPageToken) {
        case .success(let items, let next):
            let fresh = appendUnique(items, to: &shorts, seen: &shortsSeenIds)
            shortsPageToken = next
            hasMoreShorts = next != nil && !fresh.isEmpty
        case .failure(let message):
            hasMoreShorts = false
            shortsError = message
        }
        isLoadingShorts = false
    }

    func fetchPodcasts() async {
        isLoadingPodcasts = true
        podcastsError = nil
        switch await loadBucket(.podcasts, pageToken: podcastsPageToken) {
        case .success(let items, let next):
            let fresh = appendUnique(items, to: &podcasts, seen: &podcastsSeenIds)
            podcastsPageToken = next
            hasMorePodcasts = next != nil && !fresh.isEmpty
        case .failure(let message):
            hasMorePodcasts = false
            podcastsError = message
        }
        isLoadingPodcasts = false
    }

    func fetchLive() async {
        isLoadingLive = true
        liveError = nil
        switch await loadBucket(.live, pageToken: livePageToken) {
        case .success(let items, let next):
            let fresh = appendUnique(items, to: &liveVideos, seen: &liveSeenIds)
            livePageToken = next
            hasMoreLive = next != nil && !fresh.isEmpty
        case .failure(let message):
            hasMoreLive = false
            liveError = message
        }
        isLoadingLive = false
    }

    /// The prefetched artifact and the live API are two views of the same
    /// playlist taken at different times. The page token is purely
    /// (playlist, offset), so a video inserted at the head between the two
    /// shifts every index and the page after the handoff repeats items
    /// already shown. `ForEach` over duplicate ids is undefined behaviour.
    func appendUnique(_ items: [LessonVideo],
                      to target: inout [LessonVideo],
                      seen: inout Set<String>) -> [LessonVideo] {
        let fresh = items.filter { seen.insert($0.id).inserted }
        target.append(contentsOf: fresh)
        return fresh
    }

    /// All four video tabs read the same channel content and differ only in the
    /// bucket they keep.
    func loadBucket(_ bucket: SheikhContentBucket, pageToken: String?) async -> ContentOutcome {
        guard !sheikh.id.isEmpty || !sheikh.uploadsPlaylistId.isEmpty else {
            // The prefetched artifact is keyed by channel id and the live API by
            // uploads playlist id — either one is enough. Only when both are
            // missing is there nothing to page.
            print("❌ SheikhDetail: no channel id or uploads playlist for \(sheikh.id)")
            return .failure(AppLocalizedKeys.lessonsContentLoadError.value)
        }

        do {
            let result = try await YouTubeContentService.shared.fetchContent(
                channelId: sheikh.id,
                uploadsPlaylistId: sheikh.uploadsPlaylistId,
                bucket: bucket,
                pageToken: pageToken
            )
            return .success(items: result.items, nextPageToken: result.nextPageToken)
        } catch {
            print("❌ SheikhDetail \(bucket) failed for \(sheikh.id): \(error)")
            return .failure(errorMessage(for: error))
        }
    }

    /// A drained daily quota is not a connection problem, and telling the user
    /// to check their connection would send them chasing the wrong thing.
    func errorMessage(for error: Error) -> String {
        if case YouTubeContentError.quotaExceeded = error {
            return AppLocalizedKeys.lessonsQuotaError.value
        }
        return AppLocalizedKeys.lessonsContentLoadError.value
    }
}
