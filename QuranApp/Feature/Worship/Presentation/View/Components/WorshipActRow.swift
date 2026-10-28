//
//  WorshipActRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct WorshipActRow: View {

    let item: WorshipActItem
    let accent: ColorStyle
    let lockedText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                iconBadge

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .customStyle(.kitab(size: 15, bold: false), item.isLocked ? .onSurfaceVariant : .onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if item.isLocked {
                        Text(lockedText)
                            .customStyle(.caption2, .onSurfaceVariant)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 0)

                completionMarker
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .background(Color.cardSurface)
            .customCornerRadius(.cornerLg)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerLg)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(item.isLocked)
        .opacity(item.isLocked ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.2), value: item.isDone)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(item.isDone ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Parts

private extension WorshipActRow {

    var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerSm)
                .fill(accent.color.opacity(0.12))

            Image(systemName: item.icon)
                .font(.system(size: 15, weight: .medium))
                .customForeground(accent)
        }
        .frame(width: 34, height: 34)
    }

    var completionMarker: some View {
        ZStack {
            Circle()
                .stroke(item.isDone ? accent.color : ColorStyle.outlineVariant.color,
                        lineWidth: item.isDone ? 0 : 1.5)

            if item.isDone {
                Circle()
                    .fill(accent.color)

                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.cardSurface)
            }
        }
        .frame(width: 24, height: 24)
    }
}
