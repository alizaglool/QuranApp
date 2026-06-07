//
//  SheikhCardView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct SheikhCardView: View {
    let sheikh: Sheikh

    var body: some View {
        VStack(spacing: 8) {
            WebImage(url: URL(string: sheikh.thumbnailUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .customFill(.container)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.gray.opacity(0.15), lineWidth: 1))

            Text(sheikh.name)
                .customStyle(.bodySmall, .onSurface)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            Text(sheikh.formattedSubscriberCount)
                .customStyle(.caption2, .subtitle)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .customFill(.surface)
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }
}
