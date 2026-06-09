//
//  SheikhDetailView.swift
//  QuranApp
//

import SwiftUI
import Core

struct SheikhDetailView: View {
    @StateObject var viewModel: SheikhDetailViewModel
    @Environment(\.dismiss) private var dismiss

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
                sheikh: viewModel.sheikh,
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
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    SheikhHeaderView(sheikh: viewModel.sheikh)
                    Section {
                        tabContent
                    } header: {
                        tabPicker
                            .customBackground(.background)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension SheikhDetailView {

    var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(viewModel.sheikh.name)
                .customStyle(.subheadline, .onSurface)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Tab Picker (sticky, YouTube-style underline)

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
                Text(tab.localizedTitle)
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
        LazyVStack(spacing: 20) {
            if viewModel.isLoadingPlaylists && viewModel.playlists.isEmpty {
                ForEach(0..<4, id: \.self) { _ in playlistShimmer }
            } else {
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
                    emptyState(text: AppLocalizedKeys.emptyPlaylists.value)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    // MARK: Videos

    var videosTab: some View {
        LazyVStack(spacing: 20) {
            if viewModel.isLoadingVideos && viewModel.videos.isEmpty {
                ForEach(0..<4, id: \.self) { _ in videoShimmer }
            } else {
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
                    emptyState(text: AppLocalizedKeys.emptyVideos.value)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    // MARK: Shorts

    var shortsTab: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingShorts && viewModel.shorts.isEmpty {
                ForEach(0..<3, id: \.self) { _ in shortsRowShimmer }
            } else {
                ForEach(Array(stride(from: 0, to: viewModel.shorts.count, by: 2)), id: \.self) { i in
                    shortsRow(at: i)
                }
                paginationTrigger(
                    isLoading: viewModel.isLoadingShorts,
                    hasMore: viewModel.hasMoreShorts,
                    loadMore: viewModel.loadMoreShorts
                )
                if !viewModel.isLoadingShorts && viewModel.shorts.isEmpty {
                    emptyState(text: AppLocalizedKeys.emptyShorts.value)
                }
            }
        }
        .padding(.horizontal, .big)
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    @ViewBuilder
    private func shortsRow(at i: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            let left = viewModel.shorts[i]
            ShortsCardView(video: left)
                .onTapGesture { viewModel.onShortTapped(left) }

            if i + 1 < viewModel.shorts.count {
                let right = viewModel.shorts[i + 1]
                ShortsCardView(video: right)
                    .onTapGesture { viewModel.onShortTapped(right) }
            } else {
                Color.clear
            }
        }
    }

    // MARK: Podcasts

    var podcastsTab: some View {
        LazyVStack(spacing: 20) {
            if viewModel.isLoadingPodcasts && viewModel.podcasts.isEmpty {
                ForEach(0..<4, id: \.self) { _ in videoShimmer }
            } else {
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
                    emptyState(text: AppLocalizedKeys.emptyPodcasts.value)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
    }

    // MARK: Live

    var liveTab: some View {
        LazyVStack(spacing: 20) {
            if viewModel.isLoadingLive && viewModel.liveVideos.isEmpty {
                ForEach(0..<4, id: \.self) { _ in videoShimmer }
            } else {
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
                    emptyState(text: AppLocalizedKeys.emptyLive.value)
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 40)
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

// MARK: - Shimmer Placeholders

extension SheikhDetailView {

    // Playlist card skeleton — mirrors PlaylistCardView (4:3 + 2 text lines)
    var playlistShimmer: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .customFill(.container)
                .aspectRatio(4 / 3, contentMode: .fit)
                .withShimmerOverlay().redacted(reason: .placeholder)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(maxWidth: .infinity).frame(height: 22)
                    .withShimmerOverlay().redacted(reason: .placeholder)

                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(maxWidth: .infinity).frame(height: 16)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, .big)
        .padding(.bottom, 12)
    }

    // Video / podcast / live card skeleton — mirrors VideoCardView (4:3 + title + subtitle)
    var videoShimmer: some View {
        VStack(alignment: .leading, spacing: 14) {
            RoundedRectangle(cornerRadius: 16)
                .customFill(.container)
                .aspectRatio(4 / 3, contentMode: .fit)
                .withShimmerOverlay().redacted(reason: .placeholder)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(maxWidth: .infinity).frame(height: 22)
                    .withShimmerOverlay().redacted(reason: .placeholder)

                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(width: 160).frame(height: 14)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, .big)
        .padding(.bottom, 12)
    }

    // Shorts row skeleton — 2 side-by-side short card shapes (9:16 + 2 text lines)
    var shortsRowShimmer: some View {
        HStack(alignment: .top, spacing: 12) {
            shortCardShimmer
            shortCardShimmer
        }
    }

    private var shortCardShimmer: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .customFill(.container)
                .aspectRatio(9 / 16, contentMode: .fit)
                .withShimmerOverlay().redacted(reason: .placeholder)

            RoundedRectangle(cornerRadius: 4)
                .customFill(.container)
                .frame(maxWidth: .infinity).frame(height: 14)
                .withShimmerOverlay().redacted(reason: .placeholder)

            RoundedRectangle(cornerRadius: 4)
                .customFill(.container)
                .frame(width: 70).frame(height: 12)
                .withShimmerOverlay().redacted(reason: .placeholder)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
