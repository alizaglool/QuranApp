//
//  ShortsCardView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct ShortsCardView: View {
    let video: LessonVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnailSection
            infoSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

// MARK: - Thumbnail

extension ShortsCardView {

    var thumbnailSection: some View {
        ZStack(alignment: .bottomLeading) {
            WebImage(url: URL(string: video.thumbnailUrl)) { image in
                image.resizable()
            } placeholder: {
                Rectangle()
                    .customFill(.container)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(9 / 16, contentMode: .fill)
            .clipped()

            if let duration = video.duration {
                Text(duration)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(6)
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(9 / 16, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Info

extension ShortsCardView {

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(video.title)
                .font(.system(size: 13, weight: .medium))
                .customForeground(.onSurface)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(formattedDate(video.publishedAt))
                .customStyle(.caption2, .subtitle)
                .frame(maxWidth: .infinity, alignment: .leading)
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
