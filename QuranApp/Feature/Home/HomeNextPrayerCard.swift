//
//  HomeNextPrayerCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 14/10/2026.
//

import SwiftUI
import Combine
import Core

struct HomeNextPrayerCard: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: .big) {
            if viewModel.prayerTimesFailed {
                errorRow
            } else {
                prayerTimesLink
                chipsRow
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.big)
        .background(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .fill(Color.surfaceContainerLow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}

// MARK: - Rows

private extension HomeNextPrayerCard {

    var prayerTimesLink: some View {
        headerRow
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.onPrayerTimesTapped()
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
    }

    var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: .xSm) {
            Text(viewModel.prayerScheduleTitle)
                .customStyle(.headline, .onSurface)
                .tracking(viewModel.sectionTitleTracking)
                .lineLimit(1)

            Spacer(minLength: .xSm)

            Image(systemName: "chevron.forward")
                .font(.system(size: 12, weight: .semibold))
                .customForeground(.outline)
        }
    }

    var chipsRow: some View {
        HStack(spacing: 6) {
            if viewModel.prayerTimesLoaded {
                ForEach(viewModel.prayerTimes) { prayer in
                    PrayerTimeChip(prayer: prayer,
                                   accessibilityLabel: viewModel.prayerToggleAccessibilityLabel(for: prayer),
                                   onToggle: { viewModel.togglePrayed(prayer) })
                }
            } else {
                ForEach(0..<5, id: \.self) { _ in
                    PrayerTimeChipSkeleton()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.prayerTimesLoaded)
    }

    var errorRow: some View {
        HStack(spacing: .sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .customForeground(.error)

            Text(viewModel.prayerTimesErrorTitle)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: .xSm)

            Button(action: { viewModel.onRetryPrayerTimes() }) {
                Text(viewModel.retryTitle)
                    .customStyle(.buttonText, .primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
