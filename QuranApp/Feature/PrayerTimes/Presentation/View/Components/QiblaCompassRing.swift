//
//  QiblaCompassRing.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 21/10/2026.
//

import SwiftUI
import Core

struct QiblaCompassRing: View {

    @ObservedObject var viewModel: QiblaCompassViewModel

    private static let ringDiameter: CGFloat = 248
    private static let ringLineWidth: CGFloat = 10
    private static let headingDotDiameter: CGFloat = 14
    private static let kaabaBadgeDiameter: CGFloat = 46
    private static let connectorInset: CGFloat = 50
    private static let railWidth: CGFloat = 18
    private static let arcAnimation = Animation.interpolatingSpring(stiffness: 120, damping: 14)

    var body: some View {
        VStack(spacing: .md) {
            ringStack

            if viewModel.readinessMessage == nil {
                guidanceLabel
            } else {
                readinessNotice
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.accessibilityLabel)
    }
}

// MARK: - Ring

private extension QiblaCompassRing {

    var ringStack: some View {
        ZStack {
            rotatingGeometry
            centerArrow
        }
        .frame(width: QiblaCompassRing.ringDiameter,
               height: QiblaCompassRing.ringDiameter)
        .padding(.top, QiblaCompassRing.kaabaBadgeDiameter / 2)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .leading) { distanceBadge }
        .overlay(alignment: .trailing) { elevationBadge }
    }

    var rotatingGeometry: some View {
        ZStack {
            ringTrack
            offsetArc
            headingConnector
            headingDot
            kaabaBadge
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    var ringTrack: some View {
        Circle()
            .stroke(ColorStyle.outlineVariant.color.opacity(0.28),
                    lineWidth: QiblaCompassRing.ringLineWidth)
    }

    var offsetArc: some View {
        Circle()
            .trim(from: 0, to: abs(viewModel.qiblaOffsetDegrees) / 360)
            .stroke(Color.qiblaAccent,
                    style: StrokeStyle(lineWidth: QiblaCompassRing.ringLineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90 + min(viewModel.qiblaOffsetDegrees, 0)))
            .animation(QiblaCompassRing.arcAnimation, value: viewModel.qiblaOffsetDegrees)
    }

    var headingConnector: some View {
        Path { path in
            let radius = QiblaCompassRing.ringDiameter / 2
            path.move(to: CGPoint(x: radius, y: QiblaCompassRing.headingDotDiameter + 2))
            path.addLine(to: CGPoint(x: radius, y: radius - QiblaCompassRing.connectorInset))
        }
        .stroke(Color.qiblaAccent.opacity(0.55),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 5]))
        .frame(width: QiblaCompassRing.ringDiameter,
               height: QiblaCompassRing.ringDiameter)
        .rotationEffect(.degrees(viewModel.qiblaOffsetDegrees))
        .animation(QiblaCompassRing.arcAnimation, value: viewModel.qiblaOffsetDegrees)
    }

    var headingDot: some View {
        Circle()
            .fill(Color.qiblaAccent)
            .frame(width: QiblaCompassRing.headingDotDiameter,
                   height: QiblaCompassRing.headingDotDiameter)
            .offset(y: -QiblaCompassRing.ringDiameter / 2)
            .frame(width: QiblaCompassRing.ringDiameter,
                   height: QiblaCompassRing.ringDiameter)
            .rotationEffect(.degrees(viewModel.qiblaOffsetDegrees))
            .animation(QiblaCompassRing.arcAnimation, value: viewModel.qiblaOffsetDegrees)
    }

    var kaabaBadge: some View {
        ZStack {
            Circle()
                .fill(ColorStyle.primary.color)

            Image(systemName: "cube.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(width: QiblaCompassRing.kaabaBadgeDiameter,
               height: QiblaCompassRing.kaabaBadgeDiameter)
        .overlay(
            Circle()
                .stroke(Color.qiblaAccent, lineWidth: 3)
                .opacity(viewModel.isFacingQibla ? 1 : 0)
        )
        .animation(.easeOut(duration: 0.2), value: viewModel.isFacingQibla)
        .offset(y: -QiblaCompassRing.ringDiameter / 2)
    }
}

// MARK: - Center Arrow

private extension QiblaCompassRing {

    var centerArrow: some View {
        Image(systemName: "location.north.fill")
            .font(.system(size: 78, weight: .regular))
            .foregroundColor(ColorStyle.primary.color.opacity(viewModel.isCompassAvailable ? 1 : 0.3))
            .shadow(color: ColorStyle.primary.color.opacity(0.18), radius: 10, y: 4)
    }
}

// MARK: - Side Badges

private extension QiblaCompassRing {

    var distanceBadge: some View {
        sideBadge(text: viewModel.distanceToKaabaText)
    }

    @ViewBuilder
    var elevationBadge: some View {
        if let elevationText = viewModel.elevationText {
            sideBadge(text: elevationText)
        }
    }

    func sideBadge(text: String) -> some View {
        Text(text)
            .customStyle(.caption2, .onSurfaceVariant)
            .lineLimit(1)
            .fixedSize()
            .rotationEffect(.degrees(-90))
            .frame(width: QiblaCompassRing.railWidth)
            .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Guidance

private extension QiblaCompassRing {

    var guidanceLabel: some View {
        Text(viewModel.turnGuidanceText)
            .customStyle(.kitab(size: 16, bold: true))
            .foregroundColor(guidanceColor)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .animation(.easeOut(duration: 0.2), value: viewModel.turnGuidanceText)
    }

    var guidanceColor: Color {
        viewModel.isFacingQibla ? ColorStyle.primary.color : Color.qiblaAccent
    }
}

// MARK: - Readiness Notice

private extension QiblaCompassRing {

    var readinessNotice: some View {
        VStack(spacing: .xSm) {
            readinessMessageLabel
            recoveryActionButton
        }
        .frame(maxWidth: .infinity)
        .padding(.big)
        .background(ColorStyle.surfaceContainerLow.color)
        .customCornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    var readinessMessageLabel: some View {
        if let message = viewModel.readinessMessage {
            HStack(spacing: .xSm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18))
                    .customForeground(.warning)

                Text(message)
                    .customStyle(.bodySmall, .onSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    var recoveryActionButton: some View {
        if let actionTitle = viewModel.recoveryActionTitle {
            Button(action: viewModel.onRecoveryActionTapped) {
                Text(actionTitle)
                    .customStyle(.buttonText, .primary)
                    .padding(.vertical, .xSm)
                    .padding(.horizontal, .md)
                    .background(ColorStyle.primary.color.opacity(0.08))
                    .customCornerRadius(.cornerMd)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
