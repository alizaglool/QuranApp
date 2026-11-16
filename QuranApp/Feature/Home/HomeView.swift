//
//  HomeView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import SwiftUI
import Core

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel

    init(coordinator: HomeCoordinating) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Main Content

extension HomeView {

    var mainContent: some View {
        GeometryReader { geo in
            NoIndicatorsScrollView {
                VStack(spacing: 16) {
                    HomePrayerDomeHeader(viewModel: viewModel, topInset: windowTopInset)
                    HomeAthkarNowStrip(viewModel: viewModel)
                    HomeNextPrayerCard(viewModel: viewModel)
                    HomeContinueReadingCard(viewModel: viewModel)
                    HomeToolsCard(viewModel: viewModel)
                    HomeLiveStreamSection(viewModel: viewModel)
                    HomeTodayCard(viewModel: viewModel)
                    HomeHadithOfTheDayCard(viewModel: viewModel)
                    HomeFeaturedRecitersSection(viewModel: viewModel)
                    HomeFeaturedLessonsSection(viewModel: viewModel)
                }
                .frame(width: geo.size.width)
                .padding(.bottom, 32)
            }
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Safe Area

extension HomeView {

    var windowTopInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.top ?? 0
    }
}

struct AccentIconTile: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let accent: ColorStyle

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerXSm)
                .fill(accent.color.opacity(colorScheme == .dark ? 0.22 : 0.10))
                .frame(width: 36, height: 36)

            Image(systemName: icon)
                .font(.system(size: 18))
                .customForeground(accent)
        }
    }
}

struct PrayerTimeChip: View {

    let prayer: PrayerTimeItem
    let accessibilityLabel: String
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: .xxSm) {
                medallion

                Text(prayer.name)
                    .customStyle(.kitab(size: 10, bold: true))
                    .tracking(0.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(prayer.time)
                    .customStyle(.kitab(size: 13, bold: true))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, .xxSm)
            .foregroundColor(chipForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(
                RoundedRectangle(cornerRadius: .cornerMd)
                    .fill(chipBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerMd)
                    .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Medallion

    private var medallion: some View {
        Image(systemName: prayer.symbol)
            .font(.system(size: 13, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .customForeground(prayer.isPrayed ? .primary : .onSurfaceVariant)
            .frame(width: 26, height: 26)
            .background(Circle().fill(medallionBackground))
            .overlay(alignment: .bottomTrailing) {
                if prayer.isPrayed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(ColorStyle.primary.color, chipBackground)
                }
            }
            .padding(.bottom, 1)
    }

    private var medallionBackground: Color {
        ColorStyle.primary.color.opacity(prayer.isPrayed ? 0.20 : 0.09)
    }

    private var chipBackground: Color {
        prayer.isPrayed ? ColorStyle.washPrimary.color : Color.surfaceContainer
    }

    private var chipForeground: Color {
        prayer.isPrayed ? ColorStyle.primary.color : ColorStyle.onSurfaceVariant.color
    }
}

struct PrayerTimeChipSkeleton: View {
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: .cornerMd)
            .fill(Color.surfaceContainer)
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .opacity(pulse ? 0.4 : 0.7)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

// MARK: - Quick Access Tile

struct QuickAccessCard: View {
    let item: QuickAccessItem
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private let tileSide: CGFloat = 54

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(item.accent.color.opacity(colorScheme == .dark ? 0.22 : 0.10))

                    Image(systemName: item.icon)
                        .font(.system(size: 24))
                        .customForeground(item.accent)
                }
                .frame(width: tileSide, height: tileSide)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(item.accent.color.opacity(colorScheme == .dark ? 0.28 : 0.16), lineWidth: 1)
                )

                Text(item.title)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(.isButton)
    }
}
