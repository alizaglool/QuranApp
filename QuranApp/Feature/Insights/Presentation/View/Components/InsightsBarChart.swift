//
//  InsightsBarChart.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct InsightsBarChart: View {

    let bars: [InsightsBarItem]
    let accent: ColorStyle

    private let chartHeight: CGFloat = 78
    private let minimumBarHeight: CGFloat = 3

    var body: some View {
        HStack(alignment: .bottom, spacing: barSpacing) {
            ForEach(bars) { bar in
                barShape(bar)
            }
        }
        .frame(height: chartHeight)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
}

// MARK: - Parts

private extension InsightsBarChart {

    var barSpacing: CGFloat {
        switch bars.count {
        case ...10:  return 6
        case ...35:  return 2
        default:     return 1
        }
    }

    func barShape(_ bar: InsightsBarItem) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 2)
                .fill(accent.color.opacity(bar.fraction > 0 ? fillOpacity(bar) : 0.12))
                .frame(height: height(for: bar))
        }
        .frame(maxWidth: .infinity)
    }

    func fillOpacity(_ bar: InsightsBarItem) -> Double {
        bar.isLastDay ? 1 : 0.55
    }

    func height(for bar: InsightsBarItem) -> CGFloat {
        let clamped = min(max(bar.fraction, 0), 1)
        guard clamped > 0 else { return minimumBarHeight }
        return max(chartHeight * CGFloat(clamped), minimumBarHeight)
    }
}
