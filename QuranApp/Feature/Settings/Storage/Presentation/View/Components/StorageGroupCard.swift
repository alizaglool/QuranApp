//
//  StorageGroupCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import SwiftUI
import Core

struct StorageGroupCard: View {

    let group: StorageGroupItem
    let deleteAllTitle: String
    let deleteLabel: String
    let showMoreTitle: String
    let showLessTitle: String
    let onDeleteAll: () -> Void
    let onDeleteRow: (StorageRowItem) -> Void
    let onToggleExpanded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            if group.hasHeader {
                header

                if !group.rows.isEmpty {
                    divider
                }
            }

            ForEach(Array(group.visibleRows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    divider
                }

                StorageEntryRow(item: row,
                                deleteLabel: deleteLabel,
                                onDelete: { onDeleteRow(row) })
            }

            if group.hasMoreRows {
                expander
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.25), value: group.isExpanded)
    }
}

// MARK: - Header

private extension StorageGroupCard {

    var header: some View {
        HStack(spacing: .sm) {
            Circle()
                .fill(group.accent.color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(group.title)
                    .customStyle(.kitab(size: 16, bold: true), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if !group.subtitle.isEmpty {
                    Text(group.subtitle)
                        .customStyle(.caption2, .onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: .xSm)

            Text(group.sizeLabel)
                .customStyle(.caption1, .onSurface)
                .monospacedDigit()
                .lineLimit(1)

            if group.deleteAllTarget != nil {
                deleteAllButton
            }
        }
        .padding(.vertical, .xxSm)
    }

    var deleteAllButton: some View {
        Button(action: onDeleteAll) {
            Text(deleteAllTitle)
                .customStyle(.caption2, .error)
                .lineLimit(1)
                .padding(.horizontal, .xSm)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(ColorStyle.error.color.opacity(0.10))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Parts

private extension StorageGroupCard {

    var divider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color.opacity(0.3))
            .frame(height: 1)
    }

    var expander: some View {
        Button(action: onToggleExpanded) {
            HStack(spacing: .xxSm) {
                Text(group.isExpanded ? showLessTitle : showMoreTitle)
                    .customStyle(.caption1, .primary)

                Image(systemName: group.isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .customForeground(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .xSm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
