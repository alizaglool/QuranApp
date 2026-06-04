//
//  HomePrayerTimesSection.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - Section

extension HomeView {

    var prayerTimesSection: some View {
        HStack(spacing: 6) {
            if viewModel.prayerTimesLoaded {
                ForEach(viewModel.prayerTimes) { prayer in
                    PrayerTimeChip(prayer: prayer)
                }
            } else {
                ForEach(0..<5, id: \.self) { _ in
                    PrayerTimeChipSkeleton()
                }
            }
        }
        .padding(.horizontal, .big)
        .animation(.easeInOut(duration: 0.3), value: viewModel.prayerTimesLoaded)
    }
}

// MARK: - Chip

struct PrayerTimeChip: View {
    let prayer: PrayerTimeItem
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Text(prayer.name)
                .customStyle(.kitab(size: 10, bold: true))
                .tracking(0.5)

            Text(prayer.time)
                .customStyle(.kitab(size: 12, bold: true))
        }
        .foregroundColor(activeForeground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(activeBackground)
        )
        .overlay(
            Group {
                if !prayer.isActive {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
                }
            }
        )
    }

    private var activeBackground: Color {
        if prayer.isActive {
            return colorScheme == .dark ? ColorStyle.secondary.color : ColorStyle.primary.color
        }
        return Color.surfaceContainer
    }

    private var activeForeground: Color {
        prayer.isActive ? .white : ColorStyle.onSurfaceVariant.color
    }
}

// MARK: - Skeleton

struct PrayerTimeChipSkeleton: View {
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.surfaceContainer)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .opacity(pulse ? 0.4 : 0.7)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
