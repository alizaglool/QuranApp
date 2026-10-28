//
//  HomeLiveStreamSection.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct HomeLiveStreamSection: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        if viewModel.hasLiveStations {
            VStack(alignment: .leading, spacing: .md) {
                sectionHeader

                channelsRow
            }
        } else {
            Color.clear
                .frame(height: 0)
        }
    }
}

// MARK: - Sections

private extension HomeLiveStreamSection {

    var sectionHeader: some View {
        HStack(spacing: .xSm) {
            LivePulse(diameter: 8, color: ColorStyle.error.color)

            Text(viewModel.liveStreamTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: .no)
        }
        .padding(.horizontal, .big)
    }

    var channelsRow: some View {
        NoIndicatorsScrollView(.horizontal) {
            HStack(alignment: .top, spacing: .md) {
                ForEach(viewModel.liveStations) { station in
                    Button {
                        viewModel.onLiveStationTapped(station)
                    } label: {
                        HomeLiveChannelCard(
                            title: viewModel.name(for: station),
                            thumbnail: station.thumbnail,
                            badge: viewModel.liveBadge
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - Card

private struct HomeLiveChannelCard: View {

    let title: String
    let thumbnail: String?
    let badge: String

    private static let cardWidth: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: .no) {
            artwork

            details
        }
        .frame(width: Self.cardWidth, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous)
                .fill(Color.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Card parts

private extension HomeLiveChannelCard {

    var artwork: some View {
        Rectangle()
            .customFill(.surfaceContainerLow)
            .aspectRatio(16 / 9, contentMode: .fit)
            .overlay { thumbnailLayer }
            .overlay { scrim }
            .overlay(alignment: .topLeading) {
                liveBadge
                    .padding(.sm)
            }
            .overlay { playGlyph }
            .clipped()
    }

    @ViewBuilder
    var thumbnailLayer: some View {
        if let thumbnail, thumbnail.hasPrefix("http"), let url = URL(string: thumbnail) {
            WebImage(url: url)
                .resizable()
                .scaledToFill()
        } else if let thumbnail, UIImage(named: thumbnail) != nil {
            Image(thumbnail)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 34, weight: .light))
                .customForeground(.outline)
        }
    }

    var scrim: some View {
        LinearGradient(
            colors: [ColorStyle.black.color.opacity(0.32), .clear, ColorStyle.black.color.opacity(0.12)],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    var playGlyph: some View {
        Image(systemName: "play.fill")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background {
                Circle()
                    .fill(ColorStyle.black.color.opacity(0.38))
            }
            .allowsHitTesting(false)
    }

    var liveBadge: some View {
        HStack(spacing: 5) {
            LivePulse(diameter: 6, color: ColorStyle.primaryWhite.color)

            Text(badge)
                .font(.system(size: 10, weight: .bold))
                .customForeground(.onPrimary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .customFill(.error)
        }
    }

    var details: some View {
        Text(title)
            .customStyle(.subheadline, .onSurface)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
    }
}

// MARK: - Pulse

private struct LivePulse: View {

    let diameter: CGFloat
    let color: Color

    @State private var isDimmed = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: diameter, height: diameter)
            .opacity(isDimmed ? 0.3 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    isDimmed = true
                }
            }
    }
}
