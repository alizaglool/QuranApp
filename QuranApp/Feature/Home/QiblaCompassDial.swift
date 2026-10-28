//
//  QiblaCompassDial.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import SwiftUI
import Core

struct QiblaCompassDial: View {

    @ObservedObject var viewModel: QiblaCompassViewModel

    private static let dialDiameter: CGFloat = 112
    private static let tickCount = 72
    private static let degreesPerTick: Double = 5
    private static let ticksPerMajorTick = 6
    private static let tickInset: CGFloat = 4
    private static let cardinalInset: CGFloat = 18
    private static let markerInset: CGFloat = 10
    private static let needleLength: CGFloat = 40
    private static let needleWidth: CGFloat = 12
    private static let hubDiameter: CGFloat = 3

    var body: some View {
        ZStack {
            outerRing
            rotatingDialFace
            orbitingKaabaMarker
            needle
        }
        .frame(width: QiblaCompassDial.dialDiameter, height: QiblaCompassDial.dialDiameter)
        .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Dial Face

private extension QiblaCompassDial {

    var outerRing: some View {
        Circle()
            .stroke(ColorStyle.outlineVariant.color, lineWidth: 1)
    }

    var rotatingDialFace: some View {
        ZStack {
            tickMarks
            cardinalLabels
        }
        .frame(width: QiblaCompassDial.dialDiameter, height: QiblaCompassDial.dialDiameter)
        .rotationEffect(.degrees(viewModel.dialRotationDegrees))
        .animation(dialMotion, value: viewModel.dialRotationDegrees)
    }

    var tickMarks: some View {
        ForEach(0..<QiblaCompassDial.tickCount, id: \.self) { index in
            tickMark(isMajor: index % QiblaCompassDial.ticksPerMajorTick == 0)
                .rotationEffect(.degrees(Double(index) * QiblaCompassDial.degreesPerTick))
        }
    }

    func tickMark(isMajor: Bool) -> some View {
        let length: CGFloat = isMajor ? 8 : 4
        let thickness: CGFloat = isMajor ? 1.2 : 0.8
        let color = isMajor
            ? ColorStyle.onSurfaceVariant.color
            : ColorStyle.outline.color.opacity(0.5)

        return RoundedRectangle(cornerRadius: thickness / 2)
            .fill(color)
            .frame(width: thickness, height: length)
            .offset(y: -(QiblaCompassDial.dialDiameter / 2 - QiblaCompassDial.tickInset - length / 2))
    }

    var cardinalLabels: some View {
        ForEach(Array(viewModel.cardinalLabels.enumerated()), id: \.offset) { index, label in
            Text(label)
                .customStyle(.caption2, .onSurfaceVariant)
                .rotationEffect(.degrees(-(Double(index) * 90 + viewModel.dialRotationDegrees)))
                .offset(y: -(QiblaCompassDial.dialDiameter / 2 - QiblaCompassDial.cardinalInset))
                .rotationEffect(.degrees(Double(index) * 90))
        }
    }
}

// MARK: - Qibla Indicators

private extension QiblaCompassDial {

    var orbitingKaabaMarker: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.qiblaAccent)
                .frame(width: 14, height: 14)
                .offset(y: -(QiblaCompassDial.dialDiameter / 2 - QiblaCompassDial.markerInset))
        }
        .frame(width: QiblaCompassDial.dialDiameter, height: QiblaCompassDial.dialDiameter)
        .rotationEffect(.degrees(viewModel.needleRotationDegrees))
        .animation(dialMotion, value: viewModel.needleRotationDegrees)
    }

    var needle: some View {
        ZStack {
            QiblaNeedleShape()
                .fill(needleColor)
                .frame(width: QiblaCompassDial.needleWidth, height: QiblaCompassDial.needleLength)
                .offset(y: -QiblaCompassDial.needleLength / 2)

            Circle()
                .fill(needleColor)
                .frame(width: QiblaCompassDial.hubDiameter, height: QiblaCompassDial.hubDiameter)
        }
        .frame(width: QiblaCompassDial.dialDiameter, height: QiblaCompassDial.dialDiameter)
        .shadow(color: viewModel.isFacingQibla ? needleColor.opacity(0.6) : .clear, radius: 8)
        .rotationEffect(.degrees(viewModel.needleRotationDegrees))
        .animation(dialMotion, value: viewModel.needleRotationDegrees)
    }

    var needleColor: Color {
        viewModel.isFacingQibla ? ColorStyle.primary.color : Color.qiblaAccent
    }

    var dialMotion: Animation {
        .interpolatingSpring(stiffness: 120, damping: 14)
    }
}

// MARK: - Needle Shape

private struct QiblaNeedleShape: Shape {

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
