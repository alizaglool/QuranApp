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
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                WebImage(url: URL(string: video.thumbnailUrl)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .customFill(.container)
                        .withShimmerOverlay().redacted(reason: .placeholder)
                }
                .frame(width: 120, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.black.opacity(0.6)))
                    .padding(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .customStyle(.bodySmall, .onSurface)
                    .lineLimit(3)

                Text(formattedDate(video.publishedAt))
                    .customStyle(.caption2, .subtitle)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .customFill(.surface)
        )
        .padding(.horizontal, .big)
    }

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            formatter.formatOptions = .withInternetDateTime
            guard let date2 = formatter.date(from: isoString) else { return isoString }
            return RelativeDateTimeFormatter().localizedString(for: date2, relativeTo: Date())
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }
}
