//
//  PlaylistCardView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct PlaylistCardView: View {
    let playlist: LessonPlaylist

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            thumbnailSection
            infoSection
        }
        .padding(.horizontal, .big)
        .padding(.bottom, 12)
    }
}

// MARK: - Thumbnail

extension PlaylistCardView {

    var thumbnailSection: some View {
        ZStack {
            WebImage(url: URL(string: playlist.thumbnailUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .customFill(.container)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4 / 3, contentMode: .fill)
            .clipped()

            // Subtle dark gradient so badges are readable
            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.black.opacity(0.05), Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack {
                    countBadge   // top-left
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    playButton   // bottom-right
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var countBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "square.stack.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
            Text("\(playlist.itemCount)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
            Text(AppLocalizedKeys.lessonsCount.value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }

    var playButton: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(.black)
            .padding(17)
            .background(Circle().fill(Color.hadithGold))
    }
}

// MARK: - Info

extension PlaylistCardView {

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(playlist.title)
                .font(.system(size: 20, weight: .bold))
                .customForeground(.onSurface)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !playlist.description.isEmpty {
                Text(playlist.description)
                    .font(.system(size: 14))
                    .customForeground(.subtitle)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 2)
    }
}
