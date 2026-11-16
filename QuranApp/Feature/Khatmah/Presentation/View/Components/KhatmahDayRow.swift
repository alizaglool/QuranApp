//
//  KhatmahDayRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahDayRow: View {

    let item: KhatmahDayItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                statusIcon
                content
                Spacer(minLength: 0)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, item.isToday ? 12 : 10)
            .background(rowBackground)
            .contentShape(RoundedRectangle(cornerRadius: .cornerCard, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: item.isCompleted)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.accessibilityLabel)
        .accessibilityAddTraits(item.isCompleted ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Layout

private extension KhatmahDayRow {

    var statusIcon: some View {
        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20))
            .customForeground(item.statusAccent)
    }

    var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            titleLine

            if !item.verseRange.isEmpty {
                Text(item.verseRange)
                    .customStyle(.caption1, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Text(item.pageRange)
                .customStyle(.caption2, .onSurfaceVariant)
                .lineLimit(1)
                .monospacedDigit()
        }
    }

    var titleLine: some View {
        HStack(spacing: .xSm) {
            Text(item.title)
                .customStyle(.kitab(size: 15, bold: item.isToday),
                             item.isCompleted ? .onSurfaceVariant : .onSurface)
                .lineLimit(1)
                .monospacedDigit()

            if item.isToday {
                Text(item.statusTitle)
                    .customStyle(.caption1, .primary)
                    .lineLimit(1)
                    .padding(.horizontal, .xSm)
                    .padding(.vertical, 2)
                    .background(ColorStyle.washPrimary.color)
                    .clipShape(Capsule())
            } else if item.isMissed {
                Text(item.statusTitle)
                    .customStyle(.caption2, .warning)
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    var rowBackground: some View {
        if item.isToday {
            RoundedRectangle(cornerRadius: .cornerCard, style: .continuous)
                .fill(ColorStyle.primary.color.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerCard, style: .continuous)
                        .stroke(ColorStyle.primary.color.opacity(0.28), lineWidth: 1)
                )
        } else {
            Color.clear
        }
    }
}
