//
//  RecitationsPlayerBar.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core
import SDWebImageSwiftUI

// MARK: - RecitationsPlayerBar

struct RecitationsPlayerBar: View {

    @EnvironmentObject private var audio: AudioEngine
    @State private var isSheetPresenting = false

    var body: some View {
        VStack(spacing: 0) {
            contentRow
            progressLine
        }
        .background(
            RoundedRectangle(cornerRadius: .cornerCard, style: .continuous)
                .customFill(.surfaceContainerHigh)
                .shadow(color: ColorStyle.black.color.opacity(0.14), radius: 14, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard, style: .continuous)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .padding(.horizontal, .big)
        .padding(.bottom, 10)
        .appDirection()
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .customSheet(isPresented: $isSheetPresenting, fraction: 1.0, detents: [.large]) {
            RecitationsPlayerSheet()
                .environmentObject(audio)
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Content

private extension RecitationsPlayerBar {

    var contentRow: some View {
        HStack(spacing: .sm) {
            artwork
            titles
            Spacer(minLength: .xSm)
            playButton
            nextButton
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .contentShape(Rectangle())
        .onTapGesture { isSheetPresenting = true }
    }

    var artwork: some View {
        WebImage(url: URL(string: audio.currentReciter.imageURL ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .fill(Color.surfaceContainerLow)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 15, weight: .medium))
                        .customForeground(.primary)
                )
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(ColorStyle.primary.color.opacity(audio.isPlaying ? 0.55 : 0.18), lineWidth: 2)
        )
    }

    var titles: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(audio.currentSurahArabicName)
                .customStyle(.kitab(size: 15, bold: true), .onSurface)
                .lineLimit(1)
            Text(audio.currentReciter.arabicName)
                .customStyle(.caption1, .subtitle)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var playButton: some View {
        if audio.isLoadingVerse {
            ProgressView()
                .tint(ColorStyle.primary.color)
                .frame(width: 40, height: 40)
        } else {
            Button {
                audio.isPlaying ? audio.pause() : audio.resume()
            } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .customForeground(.onPrimary)
                    .frame(width: 40, height: 40)
                    .background(Circle().customFill(.primary))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(audio.isPlaying ? AppLocalizedKeys.pausePlayer.value : AppLocalizedKeys.play.value)
        }
    }

    var nextButton: some View {
        Button(action: audio.nextVerse) {
            Image(systemName: "forward.fill")
                .font(.system(size: 14, weight: .semibold))
                .customForeground(.subtitle)
                .frame(width: 34, height: 34)
                .background(Circle().customFill(.container))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppLocalizedKeys.nextVerse.value)
    }

    var progressLine: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorStyle.onSurfaceVariant.color.opacity(0.16))
                Capsule()
                    .customFill(.primary)
                    .frame(width: max(0, geo.size.width * CGFloat(audio.verseProgress)))
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
