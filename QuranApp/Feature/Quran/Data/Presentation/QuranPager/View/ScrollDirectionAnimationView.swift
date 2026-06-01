//
//  ScrollDirectionAnimationView.swift
//  QuranApp
//

import SwiftUI

enum ScrollAnimationType {
    case vertical(isSkeuomorphic: Bool)
    case horizontal(isSkeuomorphic: Bool)
}

struct ScrollDirectionAnimationView: View {
    let animationType: ScrollAnimationType
    @State private var offset: CGFloat = 0.0

    private var isHorizontal: Bool {
        switch animationType { case .horizontal: return true; case .vertical: return false }
    }

    // Gold/brown stroke matching Ayah design system
    private let stroke = Color(red: 0.63, green: 0.48, blue: 0.33)

    // Relative line widths to simulate Arabic text rows
    private let lineRatios: [CGFloat] = [0.85, 0.60, 0.85, 0.50, 0.75]

    var body: some View {
        GeometryReader { geo in
            let pad = geo.size.width * 0.13
            ZStack {
                // Phone / page border
                RoundedRectangle(cornerRadius: geo.size.width * 0.14)
                    .stroke(stroke, lineWidth: 1.5)

                // Lines — clipped strictly inside the border
                GeometryReader { inner in
                    animatedLines(w: inner.size.width, h: inner.size.height)
                }
                .padding(pad)
                .clipShape(RoundedRectangle(cornerRadius: geo.size.width * 0.10))
            }
        }
        .aspectRatio(0.75, contentMode: .fit)
    }

    // MARK: - Animated lines

    @ViewBuilder
    private func animatedLines(w: CGFloat, h: CGFloat) -> some View {
        if isHorizontal {
            HStack(spacing: 0) {
                linesBlock(w: w, h: h)
                linesBlock(w: w, h: h)
            }
            .offset(x: offset)
            .onAppear { startAnimation(by: -w) }
        } else {
            VStack(spacing: 0) {
                linesBlock(w: w, h: h)
                linesBlock(w: w, h: h)
            }
            .offset(y: offset)
            .onAppear { startAnimation(by: -h) }
        }
    }

    // One "screen" worth of text lines
    private func linesBlock(w: CGFloat, h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: h * 0.12) {
            ForEach(lineRatios.indices, id: \.self) { i in
                Capsule()
                    .fill(stroke)
                    .frame(width: w * lineRatios[i], height: max(1.5, h * 0.10))
            }
        }
        .frame(width: w, height: h, alignment: .leading)
        .padding(.horizontal, 2)
    }

    private func startAnimation(by distance: CGFloat) {
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
            offset = distance
        }
    }
}
