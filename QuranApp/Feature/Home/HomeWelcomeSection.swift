//
//  HomeWelcomeSection.swift
//  QuranApp
//

import SwiftUI
import Core

extension HomeView {

    var welcomeSection: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(AppLocalizedKeys.assalamuAlaikum.value), \(viewModel.userName)")
                    .customStyle(.caption1, .onSurfaceVariant)
                    .tracking(1)

                Text(AppLocalizedKeys.welcomeToSanctuary.value)
                    .customStyle(.headline, .onSurface)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                            .customForeground(.secondary)

                        Text(viewModel.hijriDate)
                            .customStyle(.caption2, .secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .customForeground(.secondary)

                        Text(viewModel.gregorianDate)
                            .customStyle(.caption2, .secondary)
                    }
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "building.columns")
                .font(.system(size: 80))
                .foregroundColor(ColorStyle.primary.color.opacity(0.08))
                .offset(x: 20, y: 20)
        }
        .padding(20)
        .background(Color.surfaceContainerLow)
        .customCornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, .big)
        .padding(.top, .sm)
    }
}
