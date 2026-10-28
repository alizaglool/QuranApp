//
//  ReciterSurahRowView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core

struct ReciterSurahRowView: View {

    let surah: SurahInfo
    let versesText: String
    let originText: String
    let isActive: Bool
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 14) {
            numberBadge
            titles
            Spacer(minLength: 8)
            playbackGlyph
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cardSurface)
        .customCornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive ? ColorStyle.primary.color.opacity(0.45) : ColorStyle.cardBorder.color,
                    lineWidth: isActive ? 1.5 : 1
                )
        )
    }

    // MARK: - Number

    private var numberBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? ColorStyle.primary.color.opacity(0.14) : Color.surfaceContainerHigh)
                .frame(width: 38, height: 38)

            Text("\(surah.id)")
                .customStyle(.kitab(size: 14, bold: true), isActive ? .primary : .onSurfaceVariant)
        }
    }

    // MARK: - Titles

    private var titles: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(surah.arabicTitle)
                .customStyle(.kitab(size: 16, bold: true), .onSurface)
                .lineLimit(1)

            HStack(spacing: 6) {
                Text(surah.englishTitle)
                    .customStyle(.caption2, .subtitle)
                    .lineLimit(1)

                Text("·")
                    .customStyle(.caption2, .subtitle)

                Text(versesText)
                    .customStyle(.caption2, .subtitle)
                    .lineLimit(1)

                Text("·")
                    .customStyle(.caption2, .subtitle)

                Text(originText)
                    .customStyle(.caption2, .subtitle)
                    .lineLimit(1)
            }
        }
    }

    // MARK: - Glyph

    @ViewBuilder
    private var playbackGlyph: some View {
        if isActive, isPlaying {
            Image(systemName: "waveform")
                .font(.system(size: 17, weight: .semibold))
                .customForeground(.primary)
                .symbolEffect(.variableColor.iterative.reversing)
        } else if isActive {
            Image(systemName: "pause.fill")
                .font(.system(size: 15, weight: .semibold))
                .customForeground(.primary)
        } else {
            Image(systemName: "play.fill")
                .font(.system(size: 15, weight: .semibold))
                .customForeground(.subtitle)
        }
    }
}
