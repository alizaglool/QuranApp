//
//  StorageEntryRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import SwiftUI
import Core

struct StorageEntryRow: View {

    let item: StorageRowItem
    let deleteLabel: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: .sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .customStyle(.kitab(size: 15, bold: false), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .customStyle(.caption2, .onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: .xSm)

            Text(item.sizeLabel)
                .customStyle(.caption1, .onSurfaceVariant)
                .monospacedDigit()
                .lineLimit(1)

            deleteButton
        }
        .padding(.vertical, .xSm)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title) \(item.sizeLabel)")
    }
}

// MARK: - Delete

private extension StorageEntryRow {

    var deleteButton: some View {
        Button(action: onDelete) {
            ZStack {
                RoundedRectangle(cornerRadius: .cornerSm)
                    .fill(ColorStyle.error.color.opacity(0.10))

                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .customForeground(.error)
            }
            .frame(width: 32, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(deleteLabel)
    }
}
