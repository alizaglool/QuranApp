//
//  ShortsPlayerView.swift
//  QuranApp
//

import SwiftUI
import YouTubePlayerKit
import SDWebImageSwiftUI
import Core

struct ShortsPlayerView: View {
    @Binding var videos: [LessonVideo]
    let startIndex: Int
    let sheikh: Sheikh
    let onLoadMore: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(videos: Binding<[LessonVideo]>, startIndex: Int, sheikh: Sheikh, onLoadMore: @escaping () -> Void) {
        self._videos = videos
        self.startIndex = startIndex
        self.sheikh = sheikh
        self.onLoadMore = onLoadMore
        self._currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                            ShortPlayerItem(video: video, sheikh: sheikh, isActive: currentIndex == index)
                                .containerRelativeFrame([.horizontal, .vertical])
                                .id(index)
                                .onAppear {
                                    currentIndex = index
                                    if index >= videos.count - 3 {
                                        onLoadMore()
                                    }
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea()
                .onAppear {
                    if startIndex > 0 {
                        proxy.scrollTo(startIndex, anchor: .top)
                    }
                }
            }

            topBar
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private var topBar: some View {
        VStack {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(Color(white: 0.28).opacity(0.9))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 56)

            Spacer()
        }
    }
}

// MARK: - Short Player Item

private struct ShortPlayerItem: View {
    let video: LessonVideo
    let sheikh: Sheikh
    let isActive: Bool
    @State private var player: YouTubePlayer
    @State private var isLiked = false

    init(video: LessonVideo, sheikh: Sheikh, isActive: Bool) {
        self.video = video
        self.sheikh = sheikh
        self.isActive = isActive
        _player = State(initialValue: YouTubePlayer(
            source: .video(id: video.id),
            configuration: .init(
                autoPlay: false,
                showControls: false,
                showFullscreenButton: false,
                playInline: true,
                showRelatedVideos: false
            )
        ))
    }

    var body: some View {
        ZStack {
            Color.black

            YouTubePlayerView(player)
                .ignoresSafeArea()

            bottomGradient

            VStack {
                Spacer()
                bottomInfo
                    .padding(.horizontal, 16)
                    .padding(.bottom, 80)
            }

            VStack {
                Spacer()
                HStack {
                    actionRail
                        .padding(.leading, 16)
                        .padding(.bottom, 80)
                    Spacer()
                }
            }
        }
        .onAppear {
            if isActive {
                Task { try? await player.play() }
            }
        }
        .onChange(of: isActive) { _, active in
            Task {
                if active {
                    try? await player.play()
                } else {
                    try? await player.pause()
                }
            }
        }
    }

    // MARK: - Bottom Gradient

    private var bottomGradient: some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [.clear, .black.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 400)
        }
    }

    // MARK: - Action Rail

    private var actionRail: some View {
        VStack(spacing: 20) {
            Button { isLiked.toggle() } label: {
                actionItemView(
                    icon: isLiked ? "heart.fill" : "heart",
                    label: video.formattedViewCount ?? "",
                    tint: isLiked ? .red : .white
                )
            }

            actionItemView(icon: "message", label: "", tint: .white)
            actionItemView(icon: "arrowshape.turn.up.right", label: AppLocalizedKeys.share.value, tint: .white)
        }
    }

    private func actionItemView(icon: String, label: String, tint: Color) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(tint)
                .frame(width: 52, height: 52)
                .background(Color.black.opacity(0.45))
                .clipShape(Circle())

            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }

    // MARK: - Bottom Info

    private var bottomInfo: some View {
        VStack(alignment: .trailing, spacing: 10) {
            sheikhRow
            titleRow
            descriptionRow
            audioRow
        }
    }

    private var sheikhRow: some View {
        HStack(spacing: 8) {
            Text(sheikh.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            WebImage(url: URL(string: sheikh.thumbnailUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.5))
            }
            .frame(width: 38, height: 38)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var titleRow: some View {
        Text(video.title)
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.white)
            .multilineTextAlignment(.trailing)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var descriptionRow: some View {
        Text(formattedDate(video.publishedAt))
            .font(.system(size: 13))
            .foregroundColor(.white.opacity(0.65))
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var audioRow: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.95, green: 0.82, blue: 0.2))
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "music.note")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                Text("\(AppLocalizedKeys.originalSound.value) - \(sheikh.name)")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
        }
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
        }
        formatter.formatOptions = .withInternetDateTime
        if let date = formatter.date(from: isoString) {
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
        }
        return isoString
    }
}
