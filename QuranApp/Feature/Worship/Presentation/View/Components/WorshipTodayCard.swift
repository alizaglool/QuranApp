//
//  WorshipTodayCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct WorshipTodayCard: View {

    let title: String
    let completedText: String
    let percentText: String
    let fraction: Double
    let currentStreakTitle: String
    let currentStreakValue: String
    let bestStreakTitle: String
    let bestStreakValue: String
    let daysUnit: String

    private let ringSize: CGFloat = 64
    private let ringWidth: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(title)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(1.5)

            HStack(spacing: .md) {
                progressRing

                VStack(alignment: .leading, spacing: .xxSm) {
                    Text(completedText)
                        .customStyle(.kitab(size: 20, bold: true), .onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(percentText)
                        .customStyle(.caption2, .onSurfaceVariant)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            Rectangle()
                .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                .frame(height: 1)

            HStack(spacing: .md) {
                streakBadge(title: currentStreakTitle, value: currentStreakValue, tint: .primary)

                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                    .frame(width: 1, height: 36)

                streakBadge(title: bestStreakTitle, value: bestStreakValue, tint: .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.big)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }
}

// MARK: - Parts

private extension WorshipTodayCard {

    var progressRing: some View {
        ZStack {
            Circle()
                .stroke(ColorStyle.outlineVariant.color.opacity(0.25), lineWidth: ringWidth)

            if fraction > 0 {
                Circle()
                    .trim(from: 0, to: min(fraction, 1))
                    .stroke(ColorStyle.primary.color,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .semibold))
                .customForeground(fraction > 0 ? .primary : .onSurfaceVariant)
        }
        .frame(width: ringSize, height: ringSize)
        .animation(.easeInOut(duration: 0.3), value: fraction)
    }

    func streakBadge(title: String, value: String, tint: ColorStyle) -> some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            HStack(alignment: .firstTextBaseline, spacing: .xxSm) {
                Text(value)
                    .customStyle(.kitab(size: 22, bold: true), tint)

                Text(daysUnit)
                    .customStyle(.caption2, .onSurfaceVariant)
            }

            Text(title)
                .customStyle(.caption2, .onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }
}
