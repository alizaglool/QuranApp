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
    let percentText: String
    let caption: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorStyle.quickAccentKhatmah.color.opacity(0.16), lineWidth: 10)

            Circle()
                .trim(from: 0, to: max(min(fraction, 1), 0.001))
                .stroke(
                    ColorStyle.quickAccentKhatmah.color,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(percentText)
                    .customStyle(.heading2, .onSurface)
                Text(caption)
                    .customStyle(.caption2, .subtitle)
                    .multilineTextAlignment(.center)
            }
            .padding(.xSm)
        }
        .frame(width: 118, height: 118)
        .environment(\.layoutDirection, .leftToRight)
    }
}
