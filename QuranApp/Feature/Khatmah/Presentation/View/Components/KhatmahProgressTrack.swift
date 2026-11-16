//
//  KhatmahProgressTrack.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahProgressTrack: View {

    let fraction: Double
    var height: CGFloat = 10

    private var clampedFraction: Double { min(max(fraction, 0), 1) }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.25))
                Capsule()
                    .fill(ColorStyle.primary.color)
                    .frame(width: filledWidth(in: geometry.size.width))
            }
            .clipShape(Capsule())
        }
        .frame(height: height)
        .animation(.easeInOut(duration: 0.3), value: clampedFraction)
    }

    private func filledWidth(in totalWidth: CGFloat) -> CGFloat {
        guard clampedFraction > 0 else { return 0 }
        return max(totalWidth * clampedFraction, height)
    }
}
