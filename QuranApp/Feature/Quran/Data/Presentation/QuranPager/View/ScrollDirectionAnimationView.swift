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
    @State private var offset: CGFloat = 0.0

    var body: some View {
        GeometryReader { geo in
            scrollingContent(geo: geo)
                .onAppear {
                    let distance = isHorizontal ? -geo.size.width : -geo.size.height
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                        offset = distance
                    }
                }
        }
        .clipped()
    }

    // Two copies of the image laid out in the scroll direction.
    // Container clips to one image width/height at a time.
    // Offset slides from 0 (first copy visible) → -size (second copy visible),
    // then snaps back to 0 and loops — the "half icon → other half" repeat.
    @ViewBuilder
    private func scrollingContent(geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        if isHorizontal {
            HStack(spacing: 0) {
                pageImage(w: w, h: h)
                pageImage(w: w, h: h)
            }
            .offset(x: offset)
        } else {
            VStack(spacing: 0) {
                pageImage(w: w, h: h)
                pageImage(w: w, h: h)
            }
            .offset(y: offset)
        }
    }

    private func pageImage(w: CGFloat, h: CGFloat) -> some View {
        Image(animationType.imageName)
            .resizable()
            .scaledToFill()
            .frame(width: w, height: h)
    }

    private var isHorizontal: Bool {
        switch animationType {
        case .horizontal: return true
        case .vertical: return false
        }
    }
}
