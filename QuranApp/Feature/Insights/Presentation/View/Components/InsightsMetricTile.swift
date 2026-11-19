//
//  InsightsMetricTile.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct InsightsMetricTile: View {

    let item: InsightsMetricItem

    var body: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            HStack(spacing: .xxSm) {
                Image(systemName: item.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .customForeground(item.accent)

                Text(item.title)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Text(item.value)
                .customStyle(.kitab(size: 20, bold: true), .onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if !item.caption.isEmpty {
                Text(item.caption)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.sm)
        .background(item.accent.color.opacity(0.08))
        .customCornerRadius(.cornerLg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title) \(item.value)")
    }
}
