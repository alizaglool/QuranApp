//
//  HomeHeroHeader.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 14/10/2026.
//

import SwiftUI
import Core

struct HomeHeroHeader: View {

    let title: String
    let dateLine: String
    let locationLabel: String
    let locationAccessibilityLabel: String
    let searchLabel: String
    let topInset: CGFloat
    let onSearchTapped: () -> Void

    private let heroHeight: CGFloat = 260
    private let fadeHeight: CGFloat = 80
    private let watermarkSize: CGFloat = 180

    var body: some View {
        backdrop
            .frame(height: heroHeight)
            .overlay(alignment: .topTrailing) { searchButton }
            .overlay(alignment: .bottomLeading) { captionBlock }
    }
}

// MARK: - Backdrop

private extension HomeHeroHeader {

    var backdrop: some View {
        LinearGradient(
            colors: [ColorStyle.primaryDark.color, ColorStyle.background.color],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottomTrailing) { watermark }
        .overlay(alignment: .bottom) { pageFade }
        .clipped()
    }

    var watermark: some View {
        Image(systemName: "building.columns")
            .font(.system(size: watermarkSize, weight: .ultraLight))
            .customForeground(.onSurface)
            .opacity(0.06)
            .offset(x: watermarkSize * 0.22, y: watermarkSize * 0.18)
            .accessibilityHidden(true)
    }

    var pageFade: some View {
        LinearGradient(
            colors: [.clear, ColorStyle.background.color],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: fadeHeight)
        .allowsHitTesting(false)
    }
}

// MARK: - Foreground

private extension HomeHeroHeader {

    var captionBlock: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            HStack(alignment: .firstTextBaseline, spacing: .sm) {
                Text(title)
                    .customStyle(.largeTitle, .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: .sm)

                locationPill
            }

            Text(dateLine)
                .customStyle(.caption1, .onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, .big)
        .padding(.bottom, .big)
    }

    var locationPill: some View {
        HStack(spacing: .xxSm) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 10))
                .customForeground(.onSurfaceVariant)

            Text(locationLabel)
                .customStyle(.caption2, .onSurfaceVariant)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.surfaceContainer))
        .overlay(Capsule().stroke(ColorStyle.cardBorder.color, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(locationAccessibilityLabel)
    }

    var searchButton: some View {
        Button(action: onSearchTapped) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .customForeground(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(searchLabel)
        .accessibilityAddTraits(.isButton)
        .padding(.trailing, .sm)
        .padding(.top, max(topInset, .sm))
    }
}
