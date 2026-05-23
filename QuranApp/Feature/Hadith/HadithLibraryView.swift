//
//  HadithLibraryView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import SwiftUI
import Core

struct HadithLibraryView: View {

    @StateObject private var vm = HadithLibraryViewModel()

    var body: some View {
        MainView(viewModel: vm) {
            NavigationStack {
                mainContent
                    .navigationDestination(for: HadithCollection.self) { collection in
                        HadithReadingView(collection: collection)
                    }
            }
        }
    }
}

// MARK: - Main Content

extension HadithLibraryView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionAccent
                    collectionsGrid
                }
                .padding(.bottom, 32)
            }
        }
        .customBackground(.background)
    }

    private var navBar: some View {
        HStack {
            Text(AppLocalizedKeys.hadith.value)
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

    private var collectionsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(vm.collections) { collection in
                NavigationLink(value: collection) {
                    HadithCollectionCard(collection: collection)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .big)
    }
}

// MARK: - Collection Card

struct HadithCollectionCard: View {
    let collection: HadithCollection
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorStyle.secondary.color.opacity(colorScheme == .dark ? 0.15 : 0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: collection.icon)
                    .font(.system(size: 18))
                    .customForeground(.secondary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(collection.nameAr)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text("\(collection.count) أحاديث")
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
