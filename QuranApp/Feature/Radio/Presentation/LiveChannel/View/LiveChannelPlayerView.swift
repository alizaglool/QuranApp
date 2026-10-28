//
//  LiveChannelPlayerView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import AVKit
import Core
import SDWebImageSwiftUI

// MARK: - LiveChannelPlayerView

struct LiveChannelPlayerView: View {

    let station: RadioStation
    let title: String
    let coordinator: any RadioCoordinating

    @StateObject private var controller = LiveChannelController()

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                stage
                Spacer(minLength: 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            controller.start(url: station.streamURL)
        }
        .onDisappear {
            controller.stop()
        }
    }
}

// MARK: - Chrome

private extension LiveChannelPlayerView {

    var topBar: some View {
        HStack(spacing: 12) {
            Button {
                controller.stop()
                coordinator.coordinateBack()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background {
                        Circle()
                            .fill(Color.white.opacity(0.14))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalizedKeys.close.value)

            VStack(alignment: .leading, spacing: 3) {
                liveBadge
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, 14)
    }

    var liveBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
            Text(AppLocalizedKeys.radioLive.value)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .customFill(.error)
        }
    }
}

// MARK: - Stage

private extension LiveChannelPlayerView {

    var stage: some View {
        ZStack {
            if !controller.isReady {
                artworkBackdrop
            }

            VideoPlayer(player: controller.player)
                .opacity(controller.isReady ? 1 : 0)
        }
        .aspectRatio(16 / 9, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .overlay { stageOverlay }
    }

    var artworkBackdrop: some View {
        Rectangle()
            .fill(artworkPlaceholderGradient)
            .overlay { artworkThumbnailLayer }
            .overlay { artworkScrim }
            .clipped()
    }

    @ViewBuilder
    var artworkThumbnailLayer: some View {
        if let thumbnail = station.thumbnail, !thumbnail.isEmpty {
            if thumbnail.hasPrefix("http"), let thumbnailURL = URL(string: thumbnail) {
                WebImage(url: thumbnailURL)
                    .resizable()
                    .scaledToFill()
            } else if UIImage(named: thumbnail) != nil {
                Image(thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                artworkPlaceholderGlyph
            }
        } else {
            artworkPlaceholderGlyph
        }
    }

    var artworkPlaceholderGlyph: some View {
        Image(systemName: "building.columns.fill")
            .font(.system(size: 54, weight: .light))
            .customForeground(.onPrimary)
            .opacity(0.22)
    }

    var artworkScrim: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.05), Color.black.opacity(0.38)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var artworkPlaceholderGradient: LinearGradient {
        LinearGradient(
            colors: [
                ColorStyle.primary.color.opacity(0.85),
                ColorStyle.primary.color.opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    var stageOverlay: some View {
        if controller.failed {
            failureState
        } else if !controller.isReady {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.2)
        }
    }

    var failureState: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.75))
            Text(AppLocalizedKeys.radioStreamFailed.value)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                controller.retry(url: station.streamURL)
            } label: {
                Text(AppLocalizedKeys.retryAction.value)
                    .customStyle(.subheadline, .onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .customFill(.primary)
                    }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}

// MARK: - LiveChannelController

@MainActor
private final class LiveChannelController: ObservableObject {

    @Published private(set) var isReady: Bool = false
    @Published private(set) var failed: Bool = false

    let player = AVPlayer()

    private var statusObservation: NSKeyValueObservation?

    func start(url: URL?) {
        guard player.currentItem == nil else { return }
        load(url)
    }

    func retry(url: URL?) {
        statusObservation?.invalidate()
        statusObservation = nil
        player.replaceCurrentItem(with: nil)
        load(url)
    }

    func stop() {
        statusObservation?.invalidate()
        statusObservation = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        isReady = false
        failed = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func load(_ url: URL?) {
        guard let url else {
            failed = true
            return
        }

        isReady = false
        failed = false
        activateSession()

        let item = AVPlayerItem(url: url)
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            let status = observed.status
            Task { @MainActor in
                self?.handle(status)
            }
        }

        player.automaticallyWaitsToMinimizeStalling = true
        player.replaceCurrentItem(with: item)
        player.play()
    }

    private func handle(_ status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            isReady = true
            failed = false
        case .failed:
            isReady = false
            failed = true
        default:
            break
        }
    }

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }
}
