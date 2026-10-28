//
//  LiveChannelCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core
import SDWebImageSwiftUI

// MARK: - LiveChannelCard

struct LiveChannelCard: View {

    let title: String
    let thumbnail: String?
    let badge: String
    let isEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                artwork
                Text(title)
                    .customStyle(.subheadline, .onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(badge)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Artwork

private extension LiveChannelCard {

    var artwork: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18)
                .fill(placeholderGradient)
                .overlay { thumbnailLayer }
                .overlay { scrim }
                .overlay { playGlyph }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .aspectRatio(16 / 9, contentMode: .fit)

            liveBadge
                .padding(12)
        }
    }

    @ViewBuilder
    var thumbnailLayer: some View {
        if let thumbnail, !thumbnail.isEmpty {
            if thumbnail.hasPrefix("http"), let url = URL(string: thumbnail) {
                WebImage(url: url)
                    .resizable()
                    .scaledToFill()
            } else if UIImage(named: thumbnail) != nil {
                Image(thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderGlyph
            }
        } else {
            placeholderGlyph
        }
    }

    var placeholderGlyph: some View {
        Image(systemName: "building.columns.fill")
            .font(.system(size: 54, weight: .light))
            .customForeground(.onPrimary)
            .opacity(0.22)
    }

    var scrim: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.05), Color.black.opacity(0.38)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var playGlyph: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 20, weight: .semibold))
            .customForeground(.onPrimary)
            .frame(width: 56, height: 56)
            .background {
                Circle()
                    .fill(Color.black.opacity(0.32))
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    }
            }
    }

    var liveBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
            Text(badge)
                .font(.system(size: 10, weight: .bold))
                .customForeground(.onPrimary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .customFill(.error)
        }
    }

    var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: [
                ColorStyle.primary.color.opacity(0.85),
                ColorStyle.primary.color.opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
