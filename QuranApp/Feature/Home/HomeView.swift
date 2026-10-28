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
    @Environment(\.colorScheme) private var colorScheme

    let prayer: PrayerTimeItem
    let accessibilityLabel: String
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: .xxSm) {
                Image(systemName: prayer.isPrayed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.bottom, 2)

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
                Group {
                    if !prayer.isActive {
                        RoundedRectangle(cornerRadius: .cornerMd)
                            .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    private var chipBackground: Color {
        if prayer.isActive {
            return ColorStyle.brandActive.color
        }
        if prayer.isPrayed {
            return ColorStyle.washPrimary.color
        }
        return Color.surfaceContainer
    }

    private var chipForeground: Color {
        if prayer.isActive {
            return colorScheme == .dark ? ColorStyle.primaryContainer.color : .white
        }
        if prayer.isPrayed {
            return ColorStyle.primary.color
        }
        return ColorStyle.onSurfaceVariant.color
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

    private let tileSide: CGFloat = 58

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(item.accent.color.opacity(colorScheme == .dark ? 0.22 : 0.10))

                    Image(systemName: item.icon)
                        .font(.system(size: 26))
                        .customForeground(item.accent)
                }
                .frame(width: tileSide, height: tileSide)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(item.accent.color.opacity(colorScheme == .dark ? 0.28 : 0.16), lineWidth: 1)
                )

                Text(item.title)
                    .customStyle(.caption1, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: tileSide)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(.isButton)
    }
}
