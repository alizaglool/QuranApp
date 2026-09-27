//
//  LessonPlayerView.swift
//  QuranApp
//

import SwiftUI
import YouTubePlayerKit
import Core
import SDWebImageSwiftUI

struct LessonPlayerView: View {
    @StateObject var viewModel: LessonPlayerViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        source: LessonPlayerViewModel.PlayerSource,
        title: String,
        sheikhName: String,
        playerType: LessonPlayerViewModel.PlayerType = .regular,
        relatedVideos: [LessonVideo] = []
    ) {
        _viewModel = StateObject(
            wrappedValue: LessonPlayerViewModel(
                source: source,
                title: title,
                sheikhName: sheikhName,
                playerType: playerType,
                relatedVideos: relatedVideos
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

extension LessonPlayerView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            playerSection
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    infoSection
                    if !viewModel.relatedVideos.isEmpty {
                        relatedSection
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension LessonPlayerView {

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

// MARK: - Player

extension LessonPlayerView {

    var playerSection: some View {
        YouTubePlayerView(viewModel.player)
            .frame(maxWidth: .infinity)
            .aspectRatio(16/9, contentMode: .fit)
    }
}

// MARK: - Info

extension LessonPlayerView {

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
            Text(viewModel.currentTitle)
                .font(.system(size: 22, weight: .bold))
                .customForeground(.onSurface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
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
            ShareLink(item: shareURL, subject: Text(viewModel.currentTitle)) {
                actionButton(icon: "square.and.arrow.up", label: AppLocalizedKeys.share.value)
            }
            actionButton(icon: "bookmark", label: AppLocalizedKeys.playlistSave.value)
        }
    }

    private var shareURL: URL {
        if let id = viewModel.nowPlayingId {
            // safe: YouTube video IDs are alphanumeric
            return URL(string: "https://www.youtube.com/watch?v=\(id)")!
        }
        switch viewModel.source {
        case .video(let id):
            return URL(string: "https://www.youtube.com/watch?v=\(id)")!
        case .playlist(let id):
            return URL(string: "https://www.youtube.com/playlist?list=\(id)")!
        }
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

// MARK: - Related Lessons

extension LessonPlayerView {

    var relatedSection: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            Text(AppLocalizedKeys.relatedLessons.value)
                .font(.system(size: 20, weight: .bold))
                .customForeground(.onSurface)
                .padding(.horizontal, .big)
                .padding(.top, 24)
                .padding(.bottom, 16)

            ForEach(viewModel.relatedVideos) { video in
                relatedVideoRow(video)
                    .padding(.bottom, 12)
            }
        }
    }

    func relatedVideoRow(_ video: LessonVideo) -> some View {
        let isPlaying = viewModel.nowPlayingId == video.id
        return HStack(spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                WebImage(url: URL(string: video.thumbnailUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().customFill(.container)
                }
                .frame(width: 110, height: 75)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let duration = video.duration {
                    Text(duration)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.black.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(6)
                        .environment(\.layoutDirection, .leftToRight)
                }

                if isPlaying {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.hadithGold, lineWidth: 2)
                        .frame(width: 110, height: 75)
                }
            }
            .frame(width: 110, height: 75)

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.onSurface)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(viewModel.sheikhName)
                    .font(.system(size: 13))
                    .customForeground(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.onRelatedVideoTapped(video) }
    }
}
