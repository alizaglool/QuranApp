//
//  PrayerTimeRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import SwiftUI
import Core

struct PrayerTimeRow: View {

    let item: PrayerTimeRowItem
    let nextPrayerCaption: String
    let countdownText: String?
    let toggleAccessibilityLabel: String
    let onToggle: () -> Void

    var body: some View {
        Button(action: handleTap) {
            rowContent
        }
        .buttonStyle(.plain)
        .disabled(!item.isTrackable)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(accessibilityTraits)
    }
}

// MARK: - Layout

private extension PrayerTimeRow {

    var rowContent: some View {
        HStack(spacing: .sm) {
            titleBlock
            Spacer(minLength: .xSm)
            prayerSymbol
            clockLabel
            completionIndicator
        }
        .padding(.horizontal, .md)
        .padding(.vertical, item.isNextPrayer ? 12 : 10)
        .background(rowBackground)
        .contentShape(Rectangle())
    }

    var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.title)
                .customStyle(.kitab(size: 17, bold: item.isNextPrayer), titleColor)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .fixedSize(horizontal: false, vertical: true)

            if item.isNextPrayer {
                Text(captionText)
                    .customStyle(.caption2, .primary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    var prayerSymbol: some View {
        Image(systemName: item.iconName)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(accentColor)
            .frame(width: 24, height: 24)
    }

    var clockLabel: some View {
        Text(item.clock)
            .customStyle(.kitab(size: 16, bold: true), clockColor)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(minWidth: 74, alignment: .trailing)
    }

    @ViewBuilder
    var completionIndicator: some View {
        if item.isTrackable {
            Image(systemName: item.isPrayed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: item.isPrayed ? .semibold : .regular))
                .customForeground(item.isPrayed ? .primary : .outline)
                .frame(width: 24, height: 24)
        } else {
            Color.clear
                .frame(width: 24, height: 24)
        }
    }

    @ViewBuilder
    var rowBackground: some View {
        if item.isNextPrayer {
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

// MARK: - Styling

private extension PrayerTimeRow {

    var captionText: String {
        countdownText ?? nextPrayerCaption
    }

    var accentColor: Color {
        item.isNextPrayer ? ColorStyle.primary.color : ColorStyle.onSurfaceVariant.color
    }

    var titleColor: ColorStyle {
        guard item.isTrackable else { return .onSurfaceVariant }
        return item.isNextPrayer ? .primary : .onSurface
    }

    var clockColor: ColorStyle {
        guard item.isTrackable else { return .onSurfaceVariant }
        return item.isNextPrayer ? .primary : .onSurface
    }
}

// MARK: - Interaction

private extension PrayerTimeRow {

    func handleTap() {
        guard item.isTrackable else { return }
        onToggle()
    }

    var accessibilityDescription: String {
        guard item.isTrackable else { return "\(item.title), \(item.clock)" }
        return "\(item.title), \(item.clock), \(toggleAccessibilityLabel)"
    }

    var accessibilityTraits: AccessibilityTraits {
        guard item.isTrackable else { return [] }
        return item.isPrayed ? [.isButton, .isSelected] : .isButton
    }
}
