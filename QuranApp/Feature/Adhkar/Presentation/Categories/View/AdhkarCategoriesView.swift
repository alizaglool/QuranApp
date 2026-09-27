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
        .onDisappear { viewModel.onDisappear() }
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
            .customCornerRadius(2)
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
