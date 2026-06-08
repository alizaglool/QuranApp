//
//  ShortsPlayerView.swift
//  QuranApp
//

import SwiftUI
import YouTubePlayerKit
import Core

struct ShortsPlayerView: View {
    @Binding var videos: [LessonVideo]
    let startIndex: Int
    let onLoadMore: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int

    init(videos: Binding<[LessonVideo]>, startIndex: Int, onLoadMore: @escaping () -> Void) {
        self._videos = videos
        self.startIndex = startIndex
        self.onLoadMore = onLoadMore
        self._currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                            ShortPlayerItem(video: video, isActive: currentIndex == index)
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

            closeButton
        }
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        .padding(.top, 56)
        .padding(.leading, 16)
    }
}

// MARK: - Short Player Item

private struct ShortPlayerItem: View {
    let video: LessonVideo
    let isActive: Bool
    @State private var player: YouTubePlayer

    init(video: LessonVideo, isActive: Bool) {
        self.video = video
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

    private var bottomGradient: some View {
        VStack {
            Spacer()
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .overlay(alignment: .bottomLeading) {
                Text(video.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 48)
            }
        }
    }
}
