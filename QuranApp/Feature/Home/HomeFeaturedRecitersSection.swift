//
//  HomeFeaturedRecitersSection.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core
import SDWebImageSwiftUI

// MARK: - Section

struct HomeFeaturedRecitersSection: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader

            if viewModel.featuredRecitersLoading {
                FeaturedSheikhSkeletonRow()
            } else if viewModel.featuredReciters.isEmpty {
                HomeFeaturedEmptyRow(message: viewModel.featuredRecitersErrorTitle,
                                     retryTitle: viewModel.retryTitle,
                                     onRetry: { viewModel.onRetryFeaturedReciters() })
                    .padding(.horizontal, .big)
            } else {
                recitersRow
            }
        }
    }
}

// MARK: - Layout

private extension HomeFeaturedRecitersSection {

    var sectionHeader: some View {
        HStack {
            Text(viewModel.featuredRecitersTitle)
                .customStyle(.heading3, .onSurface)

            Spacer()

            Button(viewModel.seeAllTitle) {
                viewModel.onSeeAllRecitersTapped()
            }
            .customStyle(.kitab(size: 12, bold: true), .secondary)
            .tracking(viewModel.seeAllTracking)
        }
        .padding(.horizontal, .big)
    }

    var recitersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.featuredReciters, id: \.everyayahSlug) { reciter in
                    Button {
                        viewModel.onFeaturedReciterTapped(reciter)
                    } label: {
                        FeaturedReciterCard(reciter: reciter,
                                            name: viewModel.displayName(for: reciter))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - Card

struct FeaturedReciterCard: View {
    let reciter: FeaturedReciter
    let name: String

    var body: some View {
        VStack(spacing: 10) {
            WebImage(url: URL(string: reciter.url ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.surfaceContainerHigh)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 24))
                            .customForeground(.onSurfaceVariant)
                    )
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(ColorStyle.secondary.color.opacity(0.2), lineWidth: 2)
            )

            Text(name)
                .customStyle(.kitab(size: 11, bold: true), .onSurface)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
    }
}
