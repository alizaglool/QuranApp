//
//  StorageUsageHeaderCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import SwiftUI
import Core

struct StorageUsageHeaderCard: View {

    let caption: String
    let totalLabel: String
    let legend: [StorageLegendItem]
    let captionTracking: CGFloat

    private let barHeight: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            VStack(alignment: .leading, spacing: .xxSm) {
                Text(caption)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .tracking(captionTracking)

                Text(totalLabel)
                    .customStyle(.kitab(size: 28, bold: true), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            stackedBar

            legendGrid
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.big)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Bar

private extension StorageUsageHeaderCard {

    var stackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(legend) { item in
                    Capsule()
                        .fill(item.accent.color)
                        .frame(width: max(width(for: item, total: geo.size.width), barHeight))
                }

                Spacer(minLength: 0)
            }
        }
        .frame(height: barHeight)
        .background(
            Capsule()
                .fill(ColorStyle.outlineVariant.color.opacity(0.25))
        )
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.3), value: legend.count)
    }

    func width(for item: StorageLegendItem, total: CGFloat) -> CGFloat {
        let spacing = CGFloat(max(0, legend.count - 1)) * 2
        return (total - spacing) * CGFloat(item.fraction)
    }
}

// MARK: - Legend

private extension StorageUsageHeaderCard {

    var legendGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: .sm),
                            GridItem(.flexible(), spacing: .sm)],
                  alignment: .leading,
                  spacing: .xSm) {
            ForEach(legend) { item in
                legendRow(item)
            }
        }
    }

    func legendRow(_ item: StorageLegendItem) -> some View {
        HStack(alignment: .top, spacing: .xSm) {
            Circle()
                .fill(item.accent.color)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .customStyle(.caption1, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(item.sizeLabel)
                    .customStyle(.caption1, .onSurface)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title) \(item.sizeLabel)")
    }
}
