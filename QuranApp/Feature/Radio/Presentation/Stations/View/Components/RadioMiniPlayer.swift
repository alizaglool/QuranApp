//
//  RadioMiniPlayer.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core

// MARK: - RadioMiniPlayer

struct RadioMiniPlayer: View {

    let title: String
    let subtitle: String
    let isPlaying: Bool
    let isLoading: Bool
    let toggleLabel: String
    let stopLabel: String
    let onToggle: () -> Void
    let onStop: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            artwork
            textStack
            Spacer(minLength: 8)
            toggleButton
            stopButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .customFill(.surfaceContainerHigh)
                .shadow(color: ColorStyle.black.color.opacity(0.12), radius: 12, y: 4)
        )
        .padding(.horizontal, .big)
        .padding(.bottom, 10)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Artwork

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(ColorStyle.primary.color.opacity(0.14))
                .frame(width: 40, height: 40)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 16, weight: .medium))
                .customForeground(.primary)
                .symbolEffect(.variableColor.iterative, isActive: isPlaying)
        }
    }

    // MARK: - Text

    private var textStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(subtitle)
                .font(.system(size: 9, weight: .bold))
                .customForeground(.primary)
            Text(title)
                .customStyle(.bodySmall, .onSurface)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Controls

    @ViewBuilder
    private var toggleButton: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.8)
                .frame(width: 34, height: 34)
        } else {
            Button {
                onToggle()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.onPrimary)
                    .frame(width: 34, height: 34)
                    .background(Circle().customFill(.primary))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(toggleLabel)
        }
    }

    private var stopButton: some View {
        Button {
            onStop()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .customForeground(.subtitle)
                .frame(width: 30, height: 30)
                .background(Circle().customFill(.container))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(stopLabel)
    }
}
