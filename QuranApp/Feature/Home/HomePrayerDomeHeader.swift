//
//  HomePrayerDomeHeader.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import SwiftUI
import Combine
import Core

struct HomePrayerDomeHeader: View {

    @ObservedObject var viewModel: HomeViewModel

    let topInset: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var compassViewModel = QiblaCompassViewModel()

    @State private var now = Date()
    @State private var ticker = Timer.publish(every: 1, on: .main, in: .common)
    @State private var tickerConnection: Cancellable?

    static let progressRingDiameter: CGFloat = 160
    private static let bottomCornerRadius: CGFloat = 56
    private static let ringLineWidth: CGFloat = 6
    private static let headingMarkerDiameter: CGFloat = 12
    private static let kaabaBadgeDiameter: CGFloat = 44

    var body: some View {
        VStack(spacing: .sm) {
            topBar
            dateLine
            progressRing

            VStack(spacing: .sm) {
                dhikrLine
                qiblaReadoutLine
            }
        }
        .padding(.top, max(topInset, .big))
        .padding(.bottom, .big)
        .frame(maxWidth: .infinity)
        .background(domeBackground)
        .clipShape(
            UnevenRoundedRectangle(bottomLeadingRadius: HomePrayerDomeHeader.bottomCornerRadius,
                                   bottomTrailingRadius: HomePrayerDomeHeader.bottomCornerRadius,
                                   style: .continuous)
        )
    }
}

// MARK: - Dome Background

private extension HomePrayerDomeHeader {

    var heroScene: HomeHeroScene {
        viewModel.heroScene(at: now)
    }

    var domeBackground: some View {
        ZStack {
            Image(heroScene.assetName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .id(heroScene)
                .transition(.opacity)

            LinearGradient(colors: heroScene.scrimStops(isDarkAppearance: colorScheme == .dark)
                .map { Color.black.opacity($0) },
                           startPoint: .top,
                           endPoint: .bottom)
        }
        .animation(.easeInOut(duration: 0.5), value: heroScene)
    }
}

// MARK: - Top Bar

private extension HomePrayerDomeHeader {

    var topBar: some View {
        HStack(spacing: .sm) {
            locationPill
            Spacer(minLength: .sm)
            searchButton
        }
        .padding(.horizontal, .big)
    }

    var locationPill: some View {
        HStack(spacing: .xxSm) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 11))

            Text(viewModel.locationLabel)
                .customStyle(.caption2)
                .lineLimit(1)
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.horizontal, .sm)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.12)))
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.locationAccessibilityLabel)
    }

    var searchButton: some View {
        Button(action: { viewModel.onSearchTapped() }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.white.opacity(0.12)))
                .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.searchAccessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    var dateLine: some View {
        Text(viewModel.dateLine)
            .customStyle(.caption2)
            .foregroundColor(.white.opacity(0.95))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, .big)
    }
}

// MARK: - Progress Ring

private extension HomePrayerDomeHeader {

    var progressRing: some View {
        ZStack {
            ringGeometry
            countdownStack
        }
        .frame(width: HomePrayerDomeHeader.progressRingDiameter,
               height: HomePrayerDomeHeader.progressRingDiameter)
        .padding(.top, HomePrayerDomeHeader.kaabaBadgeDiameter / 2)
        .contentShape(Circle())
        .onTapGesture { viewModel.onPrayerTimesTapped() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    var ringGeometry: some View {
        ZStack {
            ringTrack
            qiblaOffsetArc
            qiblaHeadingMarker
            kaabaBadge
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    var ringTrack: some View {
        Circle()
            .stroke(Color.white.opacity(0.14), lineWidth: HomePrayerDomeHeader.ringLineWidth)
    }

    var qiblaOffsetArc: some View {
        Circle()
            .trim(from: 0, to: abs(qiblaOffsetDegrees) / 360)
            .stroke(Color.white.opacity(0.85),
                    style: StrokeStyle(lineWidth: HomePrayerDomeHeader.ringLineWidth, lineCap: .round))
            .rotationEffect(.degrees(-90 + min(qiblaOffsetDegrees, 0)))
            .animation(.interpolatingSpring(stiffness: 120, damping: 14), value: qiblaOffsetDegrees)
    }

    var qiblaHeadingMarker: some View {
        Circle()
            .fill(Color.qiblaAccent)
            .frame(width: HomePrayerDomeHeader.headingMarkerDiameter,
                   height: HomePrayerDomeHeader.headingMarkerDiameter)
            .offset(y: -HomePrayerDomeHeader.progressRingDiameter / 2)
            .frame(width: HomePrayerDomeHeader.progressRingDiameter,
                   height: HomePrayerDomeHeader.progressRingDiameter)
            .rotationEffect(.degrees(qiblaOffsetDegrees))
            .animation(.interpolatingSpring(stiffness: 120, damping: 14), value: qiblaOffsetDegrees)
    }

    var kaabaBadge: some View {
        ZStack {
            Circle()
                .fill(Color.white)

            Image(systemName: "cube.fill")
                .font(.system(size: 19, weight: .medium))
                .foregroundColor(Color.homeDomeStart)
        }
        .frame(width: HomePrayerDomeHeader.kaabaBadgeDiameter,
               height: HomePrayerDomeHeader.kaabaBadgeDiameter)
        .overlay(
            Circle()
                .stroke(Color.qiblaAccent, lineWidth: 3)
                .opacity(compassViewModel.isFacingQibla ? 1 : 0)
        )
        .animation(.easeOut(duration: 0.2), value: compassViewModel.isFacingQibla)
        .offset(y: -HomePrayerDomeHeader.progressRingDiameter / 2)
    }

    var countdownStack: some View {
        VStack(spacing: .xSm) {
            Text(viewModel.countdownText(at: now))
                .customStyle(.kitab(size: 26, bold: true))
                .foregroundColor(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(viewModel.nextPrayerHeroLine)
                .customStyle(.kitab(size: 15, bold: true))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, .xBig)
        .onReceive(ticker) { date in
            now = date
            viewModel.onCountdownTick()
        }
        .onAppear {
            now = Date()
            viewModel.onCountdownTick()
            tickerConnection = ticker.connect()
        }
        .onDisappear {
            tickerConnection?.cancel()
            tickerConnection = nil
        }
    }

    var qiblaOffsetDegrees: Double {
        compassViewModel.qiblaOffsetDegrees
    }

    var dhikrLine: some View {
        Text(viewModel.heroDhikrLine)
            .customStyle(.caption1)
            .foregroundColor(.white.opacity(0.95))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, .xxBig)
    }
}

// MARK: - Qibla Readout

private extension HomePrayerDomeHeader {

    var qiblaReadoutLine: some View {
        HStack(spacing: .xSm) {
            Text(compassViewModel.bearingText)
                .monospacedDigit()

            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 3, height: 3)

            Text(compassViewModel.statusText)
        }
        .customStyle(.caption1)
        .foregroundColor(.white.opacity(0.95))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, .xxBig)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(compassViewModel.accessibilityLabel)
        .onAppear { compassViewModel.onAppear() }
        .onDisappear { compassViewModel.onDisappear() }
    }
}
