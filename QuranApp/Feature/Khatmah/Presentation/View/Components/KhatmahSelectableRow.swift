//
//  KhatmahSelectableRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahSelectableRow: View {

    let title: String
    let detail: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .customStyle(.subheadline, .onSurface)

                    if !detail.isEmpty {
                        Text(detail)
                            .customStyle(.caption1, .onSurfaceVariant)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .customForeground(isSelected ? .primary : .outline)
            }
            .padding(.vertical, .xSm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
