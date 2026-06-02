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
        if case .horizontal = animationType { return true }
        return false
    }

    private let stroke = Color(red: 0.63, green: 0.48, blue: 0.33)

    var body: some View {
        GeometryReader { geo in
            let pad = geo.size.width * 0.13
            let innerW = geo.size.width - 2 * pad
            let innerH = geo.size.height - 2 * pad

            ZStack {
                RoundedRectangle(cornerRadius: geo.size.width * 0.16)
                    .stroke(stroke, lineWidth: 1.5)

                // Force LTR so the HStack/VStack positions are not flipped by
                // the RTL environment inherited from the parent settings sheet.
                GeometryReader { _ in
                    Group {
                        if isHorizontal {
                            HStack(spacing: 0) {
                                linesBlock(w: innerW, h: innerH)
                                linesBlock(w: innerW, h: innerH)
                            }
                            .offset(x: offset)
                        } else {
                            VStack(spacing: 0) {
                                linesBlock(w: innerW, h: innerH)
                                linesBlock(w: innerW, h: innerH)
                            }
                            .offset(y: offset)
                        }
                    }
                    .environment(\.layoutDirection, .leftToRight)
                }
                .padding(pad)
                .clipShape(RoundedRectangle(cornerRadius: geo.size.width * 0.10))
            }
            .onAppear {
                let dist = isHorizontal ? -innerW : -innerH
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    offset = dist
                }
            }
        }
    }

    private func linesBlock(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: h * 0.18) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1)
                    .fill(stroke)
                    .frame(width: w * 0.82, height: max(1.5, h * 0.09))
            }
        }
        .frame(width: w, height: h)
    }
}
