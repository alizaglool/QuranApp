//
//  HomeAthkarNowStrip.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 22/10/2026
//

import SwiftUI
import Core

struct HomeAthkarNowStrip: View {

    @ObservedObject var viewModel: HomeViewModel

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if viewModel.hasAthkarNow {
            strip
        } else {
            Color.clear.frame(height: 0)
        }
    }
}

// MARK: - Layout

private extension HomeAthkarNowStrip {

    var strip: some View {
        Button(action: { viewModel.onAthkarNowTapped() }) {
            HStack(spacing: .sm) {
                AccentIconTile(icon: "sparkles", accent: .quickAccentAdhkar)

                VStack(alignment: .leading, spacing: .xxSm) {
                    HStack(spacing: .xSm) {
                        Text(viewModel.athkarNowTitle)
                            .customStyle(.headline, .onSurface)
                            .lineLimit(1)

                        nowBadge
                    }

                    Text(viewModel.athkarNowSubtitle)
                        .customStyle(.caption2, .onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .flipsForRightToLeftLayoutDirection(true)
                    .font(.system(size: 11, weight: .bold))
                    .customForeground(.onSurfaceVariant)
            }
            .padding(.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardSurface)
            .customCornerRadius(.cornerXl)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXl)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .big)
    }

    var nowBadge: some View {
        Text(viewModel.nowBadgeTitle)
            .customStyle(.caption2, .quickAccentAdhkar)
            .tracking(0.5)
            .padding(.horizontal, .xSm)
            .padding(.vertical, 2)
            .background(Capsule().fill(ColorStyle.quickAccentAdhkar.color.opacity(accentWashOpacity)))
    }

    var accentWashOpacity: Double {
        colorScheme == .dark ? 0.22 : 0.10
    }
}
