//
//  InsightsConsistencyRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct InsightsConsistencyRow: View {

    let item: InsightsConsistencyItem

    private let trackHeight: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            HStack(spacing: .xSm) {
                Text(item.title)
                    .customStyle(.caption1, .onSurface)

                Spacer(minLength: 0)

                Text(item.value)
                    .customStyle(.caption2, item.accent)
            }

            track
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title) \(item.value)")
    }
}

// MARK: - Parts

private extension InsightsConsistencyRow {

    var track: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.outlineVariant.opacity(0.18))

                Capsule()
                    .fill(item.accent.color)
                    .frame(width: max(proxy.size.width * fraction, fraction > 0 ? trackHeight : 0))
            }
        }
        .frame(height: trackHeight)
    }

    var fraction: CGFloat {
        CGFloat(min(max(item.fraction, 0), 1))
    }
}
