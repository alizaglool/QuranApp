//
//  AdhkarCategoriesView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import SwiftUI
import Core

struct AdhkarCategoriesView: View {

    @StateObject private var viewModel: AdhkarCategoriesViewModel

    init(coordinator: AdhkarCoordinating) {
        _viewModel = StateObject(wrappedValue: AdhkarCategoriesViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .onAppear { viewModel.onAppear() }
    }
}

// MARK: - Main Content

extension AdhkarCategoriesView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    sectionAccent

                    if viewModel.hasSpecialContent {
                        specialSection
                    }

                    quickAccessRow

                    dailySection

                    moreSection
                }
                .padding(.bottom, 40)
            }
        }
        .customBackground(.background)
    }

    private var navBar: some View {
        HStack {
            Text(AppLocalizedKeys.adhkar.value)
                .customStyle(.heading2, .onSurface)
            Spacer()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    private var sectionAccent: some View {
        Rectangle()
            .fill(ColorStyle.secondary.color)
            .frame(width: 48, height: 3)
            .cornerRadius(2)
            .padding(.horizontal, .big)
            .padding(.top, .sm)
    }
}

// MARK: - Special Section (time-conditional)

extension AdhkarCategoriesView {

    private var specialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.specialCategories) { category in
                Button { viewModel.selectCategory(category) } label: {
                    SpecialCategoryBanner(category: category)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, .big)
            }
        }
    }
}

// MARK: - Quick Access Row (أذكاري + أسماء الله)

extension AdhkarCategoriesView {

    private var quickAccessRow: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            AdhkarQuickCard(
                title: AppLocalizedKeys.allahNamesTitle.value,
                subtitle: AppLocalizedKeys.allahNamesSubtitle.value,
                icon: "star.fill",
                color: ColorStyle.secondary.color
            ) {
                viewModel.selectAllahNames()
            }

            AdhkarQuickCard(
                title: AppLocalizedKeys.myAdhkarTitle.value,
                subtitle: AppLocalizedKeys.myAdhkarSubtitle.value,
                icon: "heart.fill",
                color: ColorStyle.primary.color
            ) {
                viewModel.selectMyAdhkar()
            }
        }
        .padding(.horizontal, .big)
    }
}

// MARK: - Daily Section

extension AdhkarCategoriesView {

    private var dailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: AppLocalizedKeys.dailyAdhkar.value)
                .padding(.horizontal, .big)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.dailyCategories) { category in
                    Button { viewModel.selectCategory(category) } label: {
                        AdhkarCategoryCard(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - More Section

extension AdhkarCategoriesView {

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                ForEach(viewModel.moreCategories) { category in
                    Button { viewModel.selectCategory(category) } label: {
                        AdhkarCategoryCard(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .customStyle(.heading3, .onSurface)
    }
}

struct AdhkarQuickCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.06))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .customStyle(.headline, .onSurface)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .customStyle(.caption2, .onSurfaceVariant)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(minHeight: 130)
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

struct SpecialCategoryBanner: View {
    let category: DhikrCategory
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorStyle.secondary.color.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: category.icon)
                    .font(.system(size: 22))
                    .customForeground(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.titleAr)
                    .customStyle(.headline, .onSurface)
                Text("\(category.adhkar.count) ذكر")
                    .customStyle(.caption2, .onSurfaceVariant)
            }

            Spacer()

            Image(systemName: "chevron.backward")
                .font(.system(size: 14, weight: .medium))
                .customForeground(.onSurfaceVariant)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark
                    ? ColorStyle.secondary.color.opacity(0.08)
                    : ColorStyle.secondary.color.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorStyle.secondary.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Category Card

struct AdhkarCategoryCard: View {
    let category: DhikrCategory
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var localizationManager: LocalizationManager

    private var displayTitle: String {
        localizationManager.currentLanguage == .Arabic ? category.titleAr : category.titleEn
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorStyle.primary.color.opacity(colorScheme == .dark ? 0.15 : 0.06))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .customForeground(.primary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text(String(format: AppLocalizedKeys.adhkarCount.value, category.adhkar.count))
                    .customStyle(.caption2, .onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(minHeight: 130)
        .background(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorStyle.outlineVariant.color.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
        )
    }
}
