//
//  ScrollDirectionAnimationView.swift
//  QuranApp
//

import SwiftUI

enum ScrollAnimationType {
    case vertical(isSkeuomorphic: Bool)
    case horizontal(isSkeuomorphic: Bool)

    var imageName: String {
        switch self {
        case .vertical(let isSkeuomorphic):
            return isSkeuomorphic ? "scrollDirectionVerticalSkeuomorphic" : "scrollDirectionVerticalFullscreen"
        case .horizontal(let isSkeuomorphic):
            return isSkeuomorphic ? "scrollDirectionHorizontalSkeuomorphic" : "scrollDirectionHorizontalFullscreen"
        }
    }
}

struct ScrollDirectionAnimationView: View {
    let animationType: ScrollAnimationType

    // Start at 0 so the image is visible immediately.
    // The animation slides it out to -20 (fading to 0 opacity),
    // then instantly resets to 0 (full opacity) and loops.
    @State private var offset: CGFloat = 0.0

    var body: some View {
        Image(animationType.imageName)
            .resizable()
            .scaledToFit()
            .offset(
                x: isHorizontal ? offset : 0,
                y: isHorizontal ? 0 : offset
            )
            .opacity(1.0 - abs(offset) / 20.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: false)
                ) {
                    offset = -20.0
                }
            }
    }

    private var isHorizontal: Bool {
        switch animationType {
        case .horizontal: return true
        case .vertical: return false
        }
    }
}
