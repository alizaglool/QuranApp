//
//  AdhkarCategoriesView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import SwiftUI
import Core

struct AdhkarCategoriesView: View {

    @StateObject private var vm = AdhkarCategoriesViewModel()

    var body: some View {
        MainView(viewModel: vm) {
            NavigationStack {
                mainContent
                    .navigationDestination(for: DhikrCategory.self) { category in
                        AdhkarReadingView(category: category)
                    }
            }
        }
    }
}

// MARK: - Main Content

extension AdhkarCategoriesView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionAccent
                    categoriesGrid
                }
                .padding(.bottom, 32)
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

    private var categoriesGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(vm.categories) { category in
                NavigationLink(value: category) {
                    AdhkarCategoryCard(category: category)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .big)
    }
}

// MARK: - Category Card

struct AdhkarCategoryCard: View {
    let category: DhikrCategory
    @Environment(\.colorScheme) var colorScheme

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
                Text(category.titleAr)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(category.adhkar.count) أذكار")
                    .customStyle(.caption2, .onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .frame(height: 130)
        .background(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorStyle.outlineVariant.color.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
        )
    }
}
