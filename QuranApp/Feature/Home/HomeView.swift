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
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            
            NoIndicatorsScrollView {
                VStack(spacing: 24) {
                    welcomeSection
                    prayerTimesSection
                    quickAccessGrid
                    continueReadingCard
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
                            .foregroundColor(ColorStyle.secondary.color)
                        
                        Text(viewModel.hijriDate)
                            .customStyle(.caption2, .secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(ColorStyle.secondary.color)
                        
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
        .cornerRadius(16)
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
            ForEach(viewModel.prayerTimes) { prayer in
                PrayerTimeChip(prayer: prayer)
            }
        }
        .padding(.horizontal, .big)
    }
}

struct PrayerTimeChip: View {
    let prayer: PrayerTimeItem
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            Text(prayer.name)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
            
            Text(prayer.time)
                .font(.system(size: 12, weight: .heavy))
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
        if prayer.isActive {
            return .white
        }
        return ColorStyle.onSurfaceVariant.color
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
            .cornerRadius(16)
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
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(ColorStyle.onPrimaryContainer.color.opacity(0.6))
                            .tracking(1.5)
                        
                        Text("Surah Al-Kahf")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 10) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 96, height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ColorStyle.secondary.color)
                                    .frame(width: 96 * 0.32, height: 4)
                            }
                            
                            Text("32%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
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
    
    @ViewBuilder
    private var resumeButton: some View {
        let colorScheme = UITraitCollection.current.userInterfaceStyle
        if colorScheme == .dark {
            Text(AppLocalizedKeys.resume.value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(ColorStyle.onSurface.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ColorStyle.secondary.color)
                .cornerRadius(10)
        } else {
            Text(AppLocalizedKeys.resume.value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(ColorStyle.primary.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(10)
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
                    .font(.system(size: 10, weight: .bold))
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
        .cornerRadius(20)
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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ColorStyle.secondary.color)
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
                .font(.system(size: 11, weight: .bold))
                .customForeground(.onSurface)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
    }
}
