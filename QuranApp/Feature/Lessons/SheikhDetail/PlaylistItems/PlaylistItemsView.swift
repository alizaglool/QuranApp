//
//  PlaylistItemsView.swift
//  QuranApp
//

import SwiftUI
import Core

struct PlaylistItemsView: View {
    @StateObject var viewModel: PlaylistItemsViewModel

    init(playlist: LessonPlaylist, sheikhName: String, coordinator: any LessonsCoordinating) {
        _viewModel = StateObject(
            wrappedValue: PlaylistItemsViewModel(
                playlist: playlist,
                sheikhName: sheikhName,
                coordinator: coordinator
            )
        )
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Main Content

extension PlaylistItemsView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            videoList
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension PlaylistItemsView {

    var navBar: some View {
        HStack {
            BackButton(foregroundColor: .onSurface)
            Spacer()
            Text(viewModel.playlist.title)
                .customStyle(.subheadline, .onSurface)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Video List

extension PlaylistItemsView {

    var videoList: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.videos) { video in
                    VideoCardView(video: video)
                        .onTapGesture { viewModel.onVideoTapped(video) }
                }

                if viewModel.isLoading {
                    ProgressView().padding()
                } else if viewModel.hasMore {
                    Color.clear.frame(height: 1)
                        .onAppear { viewModel.loadMore() }
                }

                if !viewModel.isLoading && viewModel.videos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .customForeground(.subtitle)
                        Text("لا توجد فيديوهات")
                            .customStyle(.bodySmall, .subtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }
}
