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
    }
}

// MARK: - Main Content

extension SheikhDetailView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            SheikhHeaderView(sheikh: viewModel.sheikh)
            tabPicker
            Divider()
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

// MARK: - Tab Picker

extension SheikhDetailView {

    var tabPicker: some View {
        let tabs = SheikhDetailTab.allCases
        let selectedIndex = Binding(
            get: { tabs.firstIndex(of: viewModel.selectedTab) ?? 0 },
            set: { viewModel.onTabSelected(tabs[$0]) }
        )
        return SegmentedControl(
            selectedIndex: selectedIndex,
            options: tabs.map(\.rawValue)
        )
        .padding(.horizontal, .big)
        .padding(.vertical, 8)
    }
}

// MARK: - Tab Content

extension SheikhDetailView {

    @ViewBuilder
    var tabContent: some View {
        switch viewModel.selectedTab {
        case .playlists:
            playlistsTab
        case .videos:
            videosTab
        case .reels:
            reelsTab
        }
    }

    var playlistsTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.playlists) { playlist in
                    PlaylistCardView(playlist: playlist)
                        .onTapGesture { viewModel.onPlaylistTapped(playlist) }
                }
                if viewModel.isLoadingPlaylists {
                    ProgressView().padding()
                } else if viewModel.hasMorePlaylists {
                    Color.clear.frame(height: 1)
                        .onAppear { viewModel.loadMorePlaylists() }
                }
                if !viewModel.isLoadingPlaylists && viewModel.playlists.isEmpty {
                    emptyState(text: "لا توجد قوائم تشغيل")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    var videosTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.videos) { video in
                    VideoCardView(video: video)
                        .onTapGesture { viewModel.onVideoTapped(video) }
                }
                if viewModel.isLoadingVideos {
                    ProgressView().padding()
                } else if viewModel.hasMoreVideos {
                    Color.clear.frame(height: 1)
                        .onAppear { viewModel.loadMoreVideos() }
                }
                if !viewModel.isLoadingVideos && viewModel.videos.isEmpty {
                    emptyState(text: "لا توجد فيديوهات")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    var reelsTab: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.reels) { video in
                    VideoCardView(video: video)
                        .onTapGesture { viewModel.onVideoTapped(video) }
                }
                if viewModel.isLoadingReels {
                    ProgressView().padding()
                } else if viewModel.hasMoreReels {
                    Color.clear.frame(height: 1)
                        .onAppear { viewModel.loadMoreReels() }
                }
                if !viewModel.isLoadingReels && viewModel.reels.isEmpty {
                    emptyState(text: "لا توجد ريلز")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
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
