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
    @Environment(\.colorScheme) var colorScheme

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

    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(spacing: 24) {
                    welcomeSection
                    prayerTimesSection
                    quickAccessGrid
                    if viewModel.lastReadPage != nil {
                        continueReadingCard
                    }
                    hadithOfTheDayCard
                    featuredLessonsSection
                }
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension HomeView {

    private var navBar: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.primary)
            }

            Text("Wird")
                .customStyle(.heading3, .primary)

            Spacer()

            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.primary)
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Welcome Section

extension HomeView {

    private var welcomeSection: some View {
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

// MARK: - Prayer Times

extension HomeView {

    private var prayerTimesSection: some View {
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

// MARK: - Quick Access Grid

extension HomeView {

    private var quickAccessGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(viewModel.quickAccessItems) { item in
                QuickAccessCard(item: item) {
                    viewModel.onQuickAccessTapped(item)
                }
            }
        }
        .padding(.horizontal, .big)
    }
}

struct QuickAccessCard: View {
    let item: QuickAccessItem
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ColorStyle.primary.color.opacity(colorScheme == .dark ? 0.1 : 0.05))
                        .frame(width: 36, height: 36)

                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .customForeground(.primary)
                }

                Spacer()

                Text(item.title)
                    .customStyle(.headline, .onSurface)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(height: 110)
            .background(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
            .customCornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorStyle.outlineVariant.color.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Continue Reading Card

extension HomeView {

    private var continueReadingCard: some View {
        Button(action: { viewModel.onResumeTapped() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primaryContainer)

                RoundedRectangle(cornerRadius: 20)
                    .stroke(ColorStyle.primary.color.opacity(0.2), lineWidth: 1)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .offset(x: 60, y: -40)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppLocalizedKeys.continueReading.value)
                            .customStyle(.kitab(size: 10, bold: true))
                            .foregroundColor(ColorStyle.onPrimaryContainer.color.opacity(0.6))
                            .tracking(1.5)

                        Text(viewModel.lastReadSurahName)
                            .customStyle(.kitab(size: 18, bold: true))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 10) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 96, height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ColorStyle.secondary.color)
                                    .frame(width: max(4, CGFloat(96 * viewModel.lastReadProgress)), height: 4)
                            }

                            if let page = viewModel.lastReadPage {
                                Text("\(AppLocalizedKeys.page.value) \(page)")
                                    .customStyle(.kitab(size: 10, bold: true))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }

                    Spacer()

                    resumeButton
                }
                .padding(24)
            }
            .frame(height: 140)
        }
        .padding(.horizontal, .big)
    }

    private var resumeButton: some View {
        Group {
            if colorScheme == .dark {
                Text(AppLocalizedKeys.resume.value)
                    .customStyle(.kitab(size: 12, bold: true), .onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ColorStyle.secondary.color)
                    .customCornerRadius(10)
            } else {
                Text(AppLocalizedKeys.resume.value)
                    .customStyle(.kitab(size: 12, bold: true), .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .customCornerRadius(10)
            }
        }
    }
}

// MARK: - Hadith of the Day

extension HomeView {

    private var hadithOfTheDayCard: some View {
        VStack(spacing: 24) {
            Image(systemName: "quote.opening")
                .font(.system(size: 28))
                .foregroundColor(ColorStyle.secondary.color)

            Text(viewModel.hadithArabic)
                .customStyle(.heading3, .primary)
                .multilineTextAlignment(.center)
                .lineSpacing(10)

            Text(viewModel.hadithTranslation)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            HStack {
                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                    .frame(height: 0.5)

                Text(viewModel.hadithReference)
                    .customStyle(.kitab(size: 10, bold: true))
                    .foregroundColor(ColorStyle.onSurfaceVariant.color.opacity(0.6))
                    .tracking(1.5)
                    .lineLimit(1)
                    .fixedSize()

                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                    .frame(height: 0.5)
            }
        }
        .padding(32)
        .background(Color.surfaceContainerLowest)
        .customCornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}

// MARK: - Featured Lessons

extension HomeView {

    private var featuredLessonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(AppLocalizedKeys.featuredLessons.value)
                    .customStyle(.heading3, .onSurface)

                Spacer()

                Button(AppLocalizedKeys.seeAll.value) {}
                    .customStyle(.kitab(size: 12, bold: true), .secondary)
                    .tracking(1)
            }
            .padding(.horizontal, .big)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredLessons) { lesson in
                        FeaturedLessonCard(lesson: lesson)
                    }
                }
                .padding(.horizontal, .big)
            }
        }
    }
}

struct FeaturedLessonCard: View {
    let lesson: FeaturedLesson

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.surfaceContainerHigh)
                .frame(width: 72, height: 72)
                .overlay(
                    Circle()
                        .stroke(ColorStyle.secondary.color.opacity(0.2), lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .customForeground(.onSurfaceVariant)
                )

            Text(lesson.name)
                .customStyle(.kitab(size: 11, bold: true), .onSurface)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
    }
}
