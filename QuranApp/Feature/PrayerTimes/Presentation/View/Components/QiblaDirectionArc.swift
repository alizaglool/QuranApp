//
//  QiblaDirectionArc.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 01/11/2026.
//

import SwiftUI
import Core

// MARK: - QiblaDirectionArc

struct QiblaDirectionArc: View {

    let offsetDegrees: Double
    let narrowWidth: CGFloat
    let wideWidth: CGFloat
    let isLightTravelEnabled: Bool
    let isAligned: Bool

    @State private var isLightTravelling = false

    private static let travelDuration: Double = 3.4
    private static let minimumSweepForLightTravel: Double = 10
    private static let highlightOpacity: Double = 0.6
    private static let highlightSpan: Double = 0.045
    private static let alignedGlowOpacity: Double = 0.45
    private static let alignedGlowBlur: CGFloat = 4

    var body: some View {
        arcShape
            .fill(Color.qiblaAccent)
            .overlay(alignedGlow)
            .overlay(travellingLight)
    }

    private var arcShape: QiblaDirectionArcShape {
        QiblaDirectionArcShape(sweepDegrees: offsetDegrees,
                               narrowWidth: narrowWidth,
                               wideWidth: wideWidth)
    }

    @ViewBuilder
    private var alignedGlow: some View {
        if isAligned {
            arcShape
                .fill(Color.white.opacity(QiblaDirectionArc.alignedGlowOpacity))
                .blur(radius: QiblaDirectionArc.alignedGlowBlur)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var travellingLight: some View {
        if isLightVisible {
            AngularGradient(gradient: QiblaDirectionArc.highlightGradient, center: .center)
                .rotationEffect(.degrees(isLightTravelling ? travelDestinationDegrees : 0))
                .animation(QiblaDirectionArc.travelAnimation, value: isLightTravelling)
                .mask(arcShape.fill(Color.black))
                .allowsHitTesting(false)
                .onAppear { isLightTravelling = true }
                .onDisappear { isLightTravelling = false }
        }
    }

    private var isLightVisible: Bool {
        isLightTravelEnabled
            && !isAligned
            && abs(offsetDegrees) >= QiblaDirectionArc.minimumSweepForLightTravel
    }

    private var travelDestinationDegrees: Double {
        offsetDegrees < 0 ? -360 : 360
    }

    private static var travelAnimation: Animation {
        .linear(duration: travelDuration).repeatForever(autoreverses: false)
    }

    private static var highlightGradient: Gradient {
        Gradient(stops: [
            .init(color: .white.opacity(0), location: 0),
            .init(color: .white.opacity(0), location: 0.5 - highlightSpan),
            .init(color: .white.opacity(highlightOpacity), location: 0.5),
            .init(color: .white.opacity(0), location: 0.5 + highlightSpan),
            .init(color: .white.opacity(0), location: 1)
        ])
    }
}

// MARK: - QiblaDirectionArcShape

struct QiblaDirectionArcShape: Shape, Animatable {

    var sweepDegrees: Double
    var narrowWidth: CGFloat
    var wideWidth: CGFloat

    private static let minimumSweepDegrees: Double = 0.75
    private static let degreesPerSample: Double = 1.5
    private static let capSegmentCount = 10

    var animatableData: Double {
        get { sweepDegrees }
        set { sweepDegrees = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard abs(sweepDegrees) >= QiblaDirectionArcShape.minimumSweepDegrees else { return path }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let sampleCount = max(2, Int(abs(sweepDegrees) / QiblaDirectionArcShape.degreesPerSample))

        var outline: [CGPoint] = []

        for index in 0...sampleCount {
            let progress = Double(index) / Double(sampleCount)
            outline.append(edgePoint(center: center, radius: radius, progress: progress, isOuterEdge: true))
        }

        outline += capPoints(center: center, radius: radius, progress: 1)

        for index in (0...sampleCount).reversed() {
            let progress = Double(index) / Double(sampleCount)
            outline.append(edgePoint(center: center, radius: radius, progress: progress, isOuterEdge: false))
        }

        outline += capPoints(center: center, radius: radius, progress: 0)

        path.move(to: outline[0])
        outline.dropFirst().forEach { path.addLine(to: $0) }
        path.closeSubpath()

        return path
    }
}

// MARK: - Geometry

private extension QiblaDirectionArcShape {

    func edgePoint(center: CGPoint, radius: CGFloat, progress: Double, isOuterEdge: Bool) -> CGPoint {
        let offset = isOuterEdge ? halfWidth(at: progress) : -halfWidth(at: progress)
        return point(center: center,
                     radius: radius + offset,
                     degreesFromTop: sweepDegrees * progress)
    }

    func capPoints(center: CGPoint, radius: CGFloat, progress: Double) -> [CGPoint] {
        let degreesFromTop = sweepDegrees * progress
        let radians = degreesFromTop * .pi / 180
        let radial = CGPoint(x: CGFloat(sin(radians)), y: CGFloat(-cos(radians)))
        let travel = CGPoint(x: CGFloat(cos(radians)), y: CGFloat(sin(radians)))

        let isFarCap = progress > 0.5
        let travelSign: CGFloat = sweepDegrees < 0 ? -1 : 1
        let outwardSign: CGFloat = isFarCap ? travelSign : -travelSign
        let radialSign: CGFloat = isFarCap ? 1 : -1

        let anchor = point(center: center, radius: radius, degreesFromTop: degreesFromTop)
        let half = halfWidth(at: progress)
        let segments = QiblaDirectionArcShape.capSegmentCount

        return (1..<segments).map { step in
            let angle = Double(step) / Double(segments) * .pi
            let acrossCap = radialSign * CGFloat(cos(angle))
            let alongCap = outwardSign * CGFloat(sin(angle))
            return CGPoint(x: anchor.x + half * (acrossCap * radial.x + alongCap * travel.x),
                           y: anchor.y + half * (acrossCap * radial.y + alongCap * travel.y))
        }
    }

    func point(center: CGPoint, radius: CGFloat, degreesFromTop: Double) -> CGPoint {
        let radians = degreesFromTop * .pi / 180
        return CGPoint(x: center.x + radius * CGFloat(sin(radians)),
                       y: center.y - radius * CGFloat(cos(radians)))
    }

    func halfWidth(at progress: Double) -> CGFloat {
        let eased = progress * progress * (3 - 2 * progress)
        return (narrowWidth + (wideWidth - narrowWidth) * CGFloat(eased)) / 2
    }
}
