//
//  AthkarReaderControls.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarReaderControls: View {

    let ringValue: Int
    let ringProgress: Double
    let isFavorite: Bool
    let isPlaying: Bool
    let hasAudio: Bool
    let shareText: String
    let onFavorite: () -> Void
    let onCopy: () -> Void
    let onCount: () -> Void
    let onAudio: () -> Void

    @State private var pulse: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            circleButton(
                systemName: isFavorite ? "heart.fill" : "heart",
                isActive: isFavorite,
                action: onFavorite
            )

            Spacer(minLength: .xSm)

            circleButton(systemName: "doc.on.doc", action: onCopy)

            Spacer(minLength: .xSm)

            countRing

            Spacer(minLength: .xSm)

            circleButton(
                systemName: isPlaying ? "pause.fill" : "play.fill",
                disabled: !hasAudio,
                isActive: isPlaying,
                action: onAudio
            )

            Spacer(minLength: .xSm)

            shareButton
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.adhkarSurfaceTranslucent)
                .overlay(Capsule().stroke(Color.adhkarHairline, lineWidth: 1))
                .shadow(color: .adhkarShadow, radius: 20, x: 0, y: 7)
        )
        .background(.ultraThinMaterial, in: Capsule())
    }
}

// MARK: - Buttons

private extension AthkarReaderControls {

    func circleButton(
        systemName: String,
        disabled: Bool = false,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .customForeground(disabled ? .outline : isActive ? .secondary : .onSurface)
                .frame(width: 52, height: 52)
                .background(circleBackground(isActive: isActive))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    var shareButton: some View {
        ShareLink(item: shareText) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18, weight: .medium))
                .customForeground(shareText.isEmpty ? .outline : .onSurface)
                .frame(width: 52, height: 52)
                .background(circleBackground(isActive: false))
        }
        .buttonStyle(.plain)
        .disabled(shareText.isEmpty)
    }

    func circleBackground(isActive: Bool) -> some View {
        Circle()
            .fill(isActive ? ColorStyle.secondary.color.opacity(0.14) : Color.adhkarSurface)
            .overlay(
                Circle().stroke(
                    isActive ? ColorStyle.secondary.color.opacity(0.3) : Color.adhkarHairline,
                    lineWidth: 1
                )
            )
    }
}

// MARK: - Count ring

private extension AthkarReaderControls {

    var countRing: some View {
        Button(action: tapRing) {
            ZStack {
                Circle()
                    .stroke(Color.adhkarRingTrack, lineWidth: 3)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        LinearGradient(
                            colors: [ColorStyle.primary.color, ColorStyle.secondary.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: ringProgress)

                Circle()
                    .fill(Color.adhkarSurface)
                    .overlay(Circle().stroke(Color.adhkarHairline, lineWidth: 1))
                    .frame(width: 56, height: 56)

                Text("\(ringValue)")
                    .customStyle(.adhkar(size: 20, bold: true), .onSurface)
                    .monospacedDigit()
            }
            .environment(\.layoutDirection, .leftToRight)
            .scaleEffect(pulse ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
    }

    func tapRing() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) { pulse = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pulse = false }
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { onCount() }
    }
}
