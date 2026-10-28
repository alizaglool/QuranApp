//
//  StorageFilterChips.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import SwiftUI
import Core

struct StorageFilterChips: View {

    let items: [StorageFilterChipItem]
    let onSelect: (StorageCategory?) -> Void

    var body: some View {
        NoIndicatorsScrollView(.horizontal) {
            HStack(spacing: .xSm) {
                ForEach(items) { item in
                    chip(item)
                }
            }
            .padding(.horizontal, .big)
            .padding(.vertical, 2)
        }
    }
}

// MARK: - Chip

private extension StorageFilterChips {

    func chip(_ item: StorageFilterChipItem) -> some View {
        Button {
            onSelect(item.category)
        } label: {
            Text(item.title)
                .customStyle(.caption1, item.isSelected ? .primaryContainer : .onSurfaceVariant)
                .lineLimit(1)
                .padding(.horizontal, .sm)
                .padding(.vertical, .xSm)
                .background(background(item))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(ColorStyle.cardBorder.color,
                                lineWidth: item.isSelected ? 0 : 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: item.isSelected)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(item.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    func background(_ item: StorageFilterChipItem) -> Color {
        item.isSelected ? ColorStyle.primary.color : Color.cardSurface
    }
}
