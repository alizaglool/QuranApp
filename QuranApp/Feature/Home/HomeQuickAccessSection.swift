//
//  HomeQuickAccessSection.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - Section

extension HomeView {

    var quickAccessGrid: some View {
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

// MARK: - Card

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
