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
        HStack(spacing: 12) {
            WebImage(url: URL(string: playlist.thumbnailUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .customFill(.container)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .frame(width: 90, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.title)
                    .customStyle(.bodySmall, .onSurface)
                    .lineLimit(2)

                Text("\(playlist.itemCount) فيديو")
                    .customStyle(.caption2, .subtitle)
            }

            Spacer()

            Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .medium))
                .customForeground(.subtitle)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .customFill(.surface)
        )
        .padding(.horizontal, .big)
    }
}
