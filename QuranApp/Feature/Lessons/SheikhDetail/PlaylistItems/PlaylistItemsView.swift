//
//  PlaylistItemsView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI
import YouTubePlayerKit

struct PlaylistItemsView: View {
    @StateObject var viewModel: PlaylistItemsViewModel
    @Environment(\.dismiss) private var dismiss

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
            heroSection
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    infoSection
                    seriesSection
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension PlaylistItemsView {

    var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
            }
            Spacer()
            Text(viewModel.sheikhName)
                .customStyle(.subheadline, .onSurface)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Hero / Player

extension PlaylistItemsView {

    var heroSection: some View {
        Group {
            if let player = viewModel.player {
                YouTubePlayerView(player)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16/9, contentMode: .fit)
            } else {
                heroThumbnail
            }
        }
    }

    var heroThumbnail: some View {
        ZStack {
            WebImage(url: URL(string: viewModel.playlist.thumbnailUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .customFill(.container)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.6)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            )

            if !viewModel.videos.isEmpty {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(radius: 8)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.onVideoTapped(viewModel.videos[0]) }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}

// MARK: - Info Section

extension PlaylistItemsView {

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleBlock
            actionsRow
                .padding(.horizontal, .big)
                .padding(.vertical, 20)
            Rectangle()
                .customFill(.neutral)
                .frame(height: 1)
        }
    }

    var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.playlist.title)
                .font(.system(size: 24, weight: .bold))
                .customForeground(.onSurface)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(viewModel.sheikhName.uppercased())
                .font(.system(size: 11, weight: .bold))
                .customForeground(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, .big)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    var actionsRow: some View {
        HStack(spacing: 0) {
            ShareLink(item: playlistShareURL, subject: Text(viewModel.playlist.title)) {
                actionButton(icon: "square.and.arrow.up", label: AppLocalizedKeys.share.value)
            }
            actionButton(icon: "bookmark", label: AppLocalizedKeys.playlistSave.value)
        }
    }

    private var playlistShareURL: URL {
        // safe: YouTube playlist IDs are alphanumeric
        URL(string: "https://www.youtube.com/playlist?list=\(viewModel.playlist.id)")!
    }

    func actionButton(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .customForeground(.onSurface)
            Text(label)
                .font(.system(size: 11))
                .customForeground(.subtitle)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Series Section

extension PlaylistItemsView {

    var seriesSection: some View {
        LazyVStack(spacing: 12) {
            seriesHeader
            if viewModel.isLoading && viewModel.videos.isEmpty {
                ForEach(0..<4, id: \.self) { _ in videoRowShimmer }
            } else {
                ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                    videoRow(video, index: index)
                }
                paginationTrigger
                if !viewModel.isLoading && viewModel.videos.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .customForeground(.subtitle)
                        Text(AppLocalizedKeys.emptyVideos.value)
                            .customStyle(.bodySmall, .subtitle)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
        }
        .padding(.bottom, 40)
    }

    var seriesHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AppLocalizedKeys.lessonsInSeries.value)
                .font(.system(size: 20, weight: .bold))
                .customForeground(.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                HStack(spacing: 3) {
                    Text("\(viewModel.playlist.itemCount)")
                        .customStyle(.bodySmall, .subtitle)
                    Text(AppLocalizedKeys.lessonsCount.value)
                        .customStyle(.bodySmall, .subtitle)
                }
                .environment(\.layoutDirection, .leftToRight)
                Spacer()
                Button { } label: {
                    Text(AppLocalizedKeys.seeAll.value)
                        .font(.system(size: 14, weight: .semibold))
                        .customForeground(.secondary)
                }
            }
        }
        .padding(.horizontal, .big)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    func videoRow(_ video: LessonVideo, index: Int) -> some View {
        let isPlaying = viewModel.nowPlayingVideoId == video.id
        HStack(spacing: 12) {
            ZStack {
                WebImage(url: URL(string: video.thumbnailUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().customFill(.container)
                }
                .frame(width: 100, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if isPlaying {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.hadithGold, lineWidth: 2)
                        .frame(width: 100, height: 70)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 100, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                if isPlaying {
                    Text(AppLocalizedKeys.nowPlaying.value)
                        .font(.system(size: 10, weight: .bold))
                        .customForeground(.secondary)
                }
                Text(video.title)
                    .font(.system(size: 14, weight: .semibold))
                    .customForeground(.onSurface)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let duration = video.duration {
                    Text(duration)
                        .font(.system(size: 12))
                        .customForeground(.subtitle)
                        .environment(\.layoutDirection, .leftToRight)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).customFill(.surface))
        .padding(.horizontal, .big)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.onVideoTapped(video) }
    }

    @ViewBuilder
    var paginationTrigger: some View {
        if viewModel.isLoading {
            ProgressView().padding()
        } else if viewModel.hasMore {
            Color.clear.frame(height: 1)
                .onAppear { viewModel.loadMore() }
        }
    }
}

// MARK: - Shimmer

extension PlaylistItemsView {

    var videoRowShimmer: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .customFill(.container)
                .frame(width: 100, height: 70)
                .withShimmerOverlay().redacted(reason: .placeholder)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(maxWidth: .infinity).frame(height: 14)
                    .withShimmerOverlay().redacted(reason: .placeholder)
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(maxWidth: .infinity).frame(height: 14)
                    .withShimmerOverlay().redacted(reason: .placeholder)
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(width: 60).frame(height: 12)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).customFill(.surface))
        .padding(.horizontal, .big)
    }
}
