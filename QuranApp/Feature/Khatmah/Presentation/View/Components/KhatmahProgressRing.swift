//
//  KhatmahProgressRing.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahProgressRing: View {

    let fraction: Double
    let label: String

    var diameter: CGFloat = 64
    var lineWidth: CGFloat = 6
    var labelSize: CGFloat = 15

    private var clampedFraction: Double { min(max(fraction, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorStyle.outlineVariant.color.opacity(0.25), lineWidth: lineWidth)

            if clampedFraction > 0 {
                Circle()
                    .trim(from: 0, to: clampedFraction)
                    .stroke(ColorStyle.primary.color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            Text(label)
                .customStyle(.kitab(size: labelSize, bold: true), .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()
                .padding(.horizontal, lineWidth)
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeInOut(duration: 0.3), value: clampedFraction)
    }
}
