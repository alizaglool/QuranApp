//
//  RecitationsPlayerSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import AVKit
import Core
import SDWebImageSwiftUI

// MARK: - RecitationsPlayerSheet

struct RecitationsPlayerSheet: View {

    @EnvironmentObject private var audio: AudioEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            closeRow
            Spacer(minLength: .md)
            artwork
            Spacer(minLength: .big)
            titles
            Spacer(minLength: .big)
            scrubber
            Spacer(minLength: .big)
            controlsRow
            Spacer(minLength: .big)
            footerRow
            Spacer(minLength: .md)
        }
        .padding(.horizontal, .xBig)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .appDirection()
    }
}

// MARK: - Header

private extension RecitationsPlayerSheet {

    var closeRow: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .customForeground(.subtitle)
                    .frame(width: 34, height: 34)
                    .background(Circle().customFill(.container))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalizedKeys.close.value)

            Spacer()
        }
        .padding(.top, .sm)
    }

    var artwork: some View {
        WebImage(url: URL(string: audio.currentReciter.imageURL ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .fill(Color.surfaceContainerLow)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 54, weight: .light))
                        .customForeground(.primary)
                )
        }
        .frame(width: 220, height: 220)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(ColorStyle.primary.color.opacity(0.28), lineWidth: 3)
        )
        .shadow(color: ColorStyle.black.color.opacity(0.18), radius: 22, y: 10)
    }

    var titles: some View {
        VStack(spacing: .xSm) {
            Text(audio.currentSurahArabicName)
                .customStyle(.kitab(size: 24, bold: true), .onSurface)
                .lineLimit(1)

            Text(audio.currentReciter.arabicName)
                .customStyle(.kitab(size: 15), .primary)
                .lineLimit(1)

            Text(String(format: AppLocalizedKeys.currentVerse.value, audio.currentVerseNumber.arabicNumerals))
                .customStyle(.caption1, .subtitle)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - Scrubber

private extension RecitationsPlayerSheet {

    var scrubber: some View {
        VStack(spacing: .xSm) {
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let filled = max(0, trackWidth * CGFloat(audio.verseProgress))

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(ColorStyle.onSurfaceVariant.color.opacity(0.18))
                        .frame(height: 4)

                    Capsule()
                        .customFill(.primary)
                        .frame(width: filled, height: 4)

                    Circle()
                        .customFill(.primary)
                        .frame(width: 13, height: 13)
                        .offset(x: max(0, filled - 6.5))
                }
                .frame(height: 20)
                .contentShape(Rectangle().inset(by: -10))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard trackWidth > 0 else { return }
                            audio.seek(to: min(max(0, value.location.x / trackWidth), 1))
                        }
                )
            }
            .frame(height: 20)

            HStack {
                Text(formatTime(audio.verseElapsed))
                    .customStyle(.caption2, .subtitle)
                Spacer()
                Text(formatTime(max(0, audio.verseDuration - audio.verseElapsed)))
                    .customStyle(.caption2, .subtitle)
            }
            .environment(\.layoutDirection, .leftToRight)
        }
    }

    func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "0:00" }
        let seconds = Int(time)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Controls

private extension RecitationsPlayerSheet {

    var controlsRow: some View {
        HStack(spacing: .xxxBig) {
            Button(action: audio.previousVerse) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .customForeground(.onSurface)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalizedKeys.previousVerse.value)

            playButton

            Button(action: audio.nextVerse) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .customForeground(.onSurface)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalizedKeys.nextVerse.value)
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    @ViewBuilder
    var playButton: some View {
        if audio.isLoadingVerse {
            ProgressView()
                .tint(ColorStyle.primary.color)
                .frame(width: 68, height: 68)
        } else {
            Button {
                audio.isPlaying ? audio.pause() : audio.resume()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .customForeground(.onPrimary)
                    .frame(width: 68, height: 68)
                    .background(Circle().customFill(.primary))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(audio.isPlaying ? AppLocalizedKeys.pausePlayer.value : AppLocalizedKeys.play.value)
        }
    }

    var footerRow: some View {
        HStack(spacing: .md) {
            Button(action: audio.cycleSpeed) {
                Text(audio.currentSpeedLabel)
                    .customStyle(.caption1, .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().customFill(.container))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalizedKeys.playbackSpeed.value)

            Spacer()

            RecitationsAirPlayButton()
                .frame(width: 34, height: 34)
                .customForeground(.onSurface)

            Button(action: audio.stop) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .customForeground(.subtitle)
                    .frame(width: 34, height: 34)
                    .background(Circle().customFill(.container))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalizedKeys.close.value)
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - AirPlay

private struct RecitationsAirPlayButton: UIViewRepresentable {

    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.activeTintColor = UIColor(ColorStyle.primary.color)
        view.tintColor = UIColor(ColorStyle.onSurface.color)
        view.prioritizesVideoDevices = false
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
