//
//  HomeTodayCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 14/10/2026.
//

import SwiftUI
import Core

struct HomeTodayCard: View {

    @ObservedObject var viewModel: HomeViewModel

    private let ringSize: CGFloat = 48
    private let ringWidth: CGFloat = 5

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(viewModel.todayTitle)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(1.5)

            metricsRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.sm)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}

// MARK: - Metrics

private extension HomeTodayCard {

    var metricsRow: some View {
        HStack(spacing: .md) {
            if viewModel.prayerTimesLoaded {
                metric(fraction: viewModel.prayedFraction,
                       icon: "checkmark",
                       value: viewModel.prayedCountText,
                       label: viewModel.todayPrayersLabel,
                       tint: .primary)

                divider
            }

            metric(fraction: viewModel.lastReadProgress,
                   icon: "book.fill",
                   value: viewModel.quranProgressText,
                   label: viewModel.todayQuranLabel,
                   tint: .secondary)
        }
    }

    var divider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color.opacity(0.3))
            .frame(width: 1, height: ringSize)
    }

    func metric(fraction: Double,
                icon: String,
                value: String,
                label: String,
                tint: ColorStyle) -> some View {
        HStack(spacing: .sm) {
            ring(fraction: fraction, icon: icon, tint: tint)

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(value)
                    .customStyle(.kitab(size: 16, bold: true), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(label)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")
    }

    func ring(fraction: Double, icon: String, tint: ColorStyle) -> some View {
        ZStack {
            Circle()
                .stroke(ColorStyle.outlineVariant.color.opacity(0.25), lineWidth: ringWidth)

            if fraction > 0 {
                Circle()
                    .trim(from: 0, to: min(fraction, 1))
                    .stroke(tint.color, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .customForeground(tint)
        }
        .frame(width: ringSize, height: ringSize)
        .animation(.easeInOut(duration: 0.3), value: fraction)
    }
}
