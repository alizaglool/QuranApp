//
//  SheikhHeaderView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct SheikhHeaderView: View {
    let sheikh: Sheikh

    var body: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: sheikh.thumbnailUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .customFill(.container)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(sheikh.name)
                    .customStyle(.heading3, .onSurface)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label(sheikh.formattedSubscriberCount, systemImage: "person.2.fill")
                        .customStyle(.caption2, .subtitle)
                    Label("\(sheikh.videoCount)", systemImage: "play.fill")
                        .customStyle(.caption2, .subtitle)
                }
            }

            Spacer()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, 16)
    }
}
