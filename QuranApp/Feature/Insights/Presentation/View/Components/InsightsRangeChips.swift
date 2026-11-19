//
//  InsightsRangeChips.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct InsightsRangeChips: View {

    let ranges: [InsightsRange]
    let selectedRange: InsightsRange
    let title: (InsightsRange) -> String
    let onSelect: (InsightsRange) -> Void

    var body: some View {
        HStack(spacing: .xSm) {
            ForEach(ranges) { range in
                chip(range)
            }
        }
    }
}

// MARK: - Chip

private extension InsightsRangeChips {

    func chip(_ range: InsightsRange) -> some View {
        let isSelected = range == selectedRange
        return Button { onSelect(range) } label: {
            Text(title(range))
                .customStyle(.caption1, isSelected ? .onPrimaryContainer : .onSurfaceVariant)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .xSm)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? ColorStyle.primaryContainer.color
                              : ColorStyle.surfaceContainerLow.color)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.outlineVariant.opacity(isSelected ? 0 : 0.18),
                                      lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
