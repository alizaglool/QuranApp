//
//  SheikhDetailView.swift
//  QuranApp
//

import SwiftUI
import Core

struct SheikhDetailView: View {
    @StateObject var viewModel: SheikhDetailViewModel

    init(sheikh: Sheikh, coordinator: any LessonsCoordinating) {
        _viewModel = StateObject(wrappedValue: SheikhDetailViewModel(sheikh: sheikh, coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .fullScreenCover(isPresented: $viewModel.showShortsPlayer) {
            ShortsPlayerView(
                videos: $viewModel.shorts,
                startIndex: viewModel.shortsStartIndex,
                onLoadMore: { viewModel.loadMoreShorts() }
            )
        }
    }
}

// MARK: - Main Content

extension SheikhDetailView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            SheikhHeaderView(sheikh: viewModel.sheikh)
            tabPicker
            tabContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension SheikhDetailView {

    var navBar: some View {
        HStack {
            BackButton(foregroundColor: .onSurface)
            Spacer()
            Text(viewModel.sheikh.name)
                .customStyle(.subheadline, .onSurface)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Tab Picker (scrollable, YouTube-style underline)

extension SheikhDetailView {

    var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(SheikhDetailTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
        }
        .background(alignment: .bottom) {
            Rectangle()
                .customFill(.neutral)
                .frame(height: 1)
        }
    }

    func tabButton(_ tab: SheikhDetailTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        return Button {
            viewModel.onTabSelected(tab)
        } label: {
            VStack(spacing: 0) {
                Text(tab.rawValue)
                    .customStyle(isSelected ? .subheadline : .bodySmall)
                    .customForeground(isSelected ? .secondary : .subtitle)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .fixedSize()

                Rectangle()
                    .customFill(isSelected ? .secondary : .clear)
                    .frame(height: 2)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedTab)
    }
}

// MARK: - Tab Content

extension SheikhDetailView {

    @ViewBuilder
    var tabContent: some View {
        switch viewModel.selectedTab {
        case .playlists: playlistsTab
        case .videos:    videosTab
        case .shorts:    shortsTab
        case .podcasts:  podcastsTab
        case .live:      liveTab
        }
    }

    // MARK: Playlists

    var playlistsTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.playlists) { playlist in
                    PlaylistCardView(playlist: playlist)
                        .onTapGesture { viewModel.onPlaylistTapped(playlist) }
                }
                paginationTrigger(
                    isLoading: viewModel.isLoadingPlaylists,
                    hasMore: viewModel.hasMorePlaylists,
                    loadMore: viewModel.loadMorePlaylists
                )
                if !viewModel.isLoadingPlaylists && viewModel.playlists.isEmpty {
                    emptyState(text: "لا توجد قوائم تشغيل")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: Videos

    var videosTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.videos) { video in
                    VideoCardView(video: video)
                        .onTapGesture { viewModel.onVideoTapped(video) }
                }
                paginationTrigger(
                    isLoading: viewModel.isLoadingVideos,
                    hasMore: viewModel.hasMoreVideos,
                    loadMore: viewModel.loadMoreVideos
                )
                if !viewModel.isLoadingVideos && viewModel.videos.isEmpty {
                    emptyState(text: "لا توجد فيديوهات")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: Shorts

    var shortsTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.shorts) { video in
                    VideoCardView(video: video)
                        .onTapGesture { viewModel.onShortTapped(video) }
                }
                paginationTrigger(
                    isLoading: viewModel.isLoadingShorts,
                    hasMore: viewModel.hasMoreShorts,
                    loadMore: viewModel.loadMoreShorts
                )
                if !viewModel.isLoadingShorts && viewModel.shorts.isEmpty {
                    emptyState(text: "لا توجد شورتس")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: Podcasts

    var podcastsTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.podcasts) { video in
                    VideoCardView(video: video)
                        .onTapGesture { viewModel.onVideoTapped(video) }
                }
                paginationTrigger(
                    isLoading: viewModel.isLoadingPodcasts,
                    hasMore: viewModel.hasMorePodcasts,
                    loadMore: viewModel.loadMorePodcasts
                )
                if !viewModel.isLoadingPodcasts && viewModel.podcasts.isEmpty {
                    emptyState(text: "لا توجد بودكاست")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: Live

    var liveTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.liveVideos) { video in
                    VideoCardView(video: video)
                        .onTapGesture { viewModel.onVideoTapped(video) }
                }
                paginationTrigger(
                    isLoading: viewModel.isLoadingLive,
                    hasMore: viewModel.hasMoreLive,
                    loadMore: viewModel.loadMoreLive
                )
                if !viewModel.isLoadingLive && viewModel.liveVideos.isEmpty {
                    emptyState(text: "لا توجد بثوث مباشرة")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: Shared Helpers

    @ViewBuilder
    func paginationTrigger(isLoading: Bool, hasMore: Bool, loadMore: @escaping () -> Void) -> some View {
        if isLoading {
            ProgressView().padding()
        } else if hasMore {
            Color.clear.frame(height: 1)
                .onAppear { loadMore() }
        }
    }

    func emptyState(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .customForeground(.subtitle)
            Text(text)
                .customStyle(.bodySmall, .subtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
