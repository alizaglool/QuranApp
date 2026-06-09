//
//  VideoCardView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct VideoCardView: View {
    let video: LessonVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            thumbnailSection
            infoSection
        }
        .padding(.horizontal, .big)
        .padding(.bottom, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - Thumbnail

extension VideoCardView {

    var thumbnailSection: some View {
        ZStack {
            WebImage(url: URL(string: video.thumbnailUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Rectangle()
                    .customFill(.container)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(4 / 3, contentMode: .fill)
            .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.35), Color.black.opacity(0.05), Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                HStack {
                    if let duration = video.duration {
                        durationBadge(duration)
                    }
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    playButton
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func durationBadge(_ duration: String) -> some View {
        Text(duration)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .environment(\.layoutDirection, .leftToRight)
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

extension VideoCardView {

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(video.title)
                .font(.system(size: 20, weight: .bold))
                .customForeground(.onSurface)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            subtitleRow
        }
        .padding(.horizontal, 2)
    }

    var subtitleRow: some View {
        HStack(spacing: 4) {
            Text(formattedDate(video.publishedAt))
                .customStyle(.caption2, .subtitle)

            if let views = video.formattedViewCount {
                Text("•")
                    .customStyle(.caption2, .subtitle)
                Text(views)
                    .customStyle(.caption2, .subtitle)
            }

            Spacer()
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
