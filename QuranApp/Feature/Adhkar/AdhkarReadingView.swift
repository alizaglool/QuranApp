//
//  AdhkarReadingView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import SwiftUI
import Core

struct AdhkarReadingView: View {

    @StateObject private var viewModel: AdhkarReadingViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var tapPulse: Bool = false
    @State private var slideEdge: Edge = .trailing

    init(category: DhikrCategory) {
        _viewModel = StateObject(wrappedValue: AdhkarReadingViewModel(category: category))
    }

    private var isRightToLeft: Bool {
        localizationManager.currentLanguage == .Arabic
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            ZStack {
                Color.background.ignoresSafeArea()
                ambientGlowBackground
                VStack(spacing: 0) {
                    readingNavigationBar
                    if viewModel.isComplete {
                        completionView
                    } else {
                        dhikrReadingContent
                            .contentShape(Rectangle())
                            .gesture(swipeNavigationGesture)
                            .onTapGesture {
                                handleScreenTap()
                            }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func handleScreenTap() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            tapPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            tapPulse = false
        }
        if viewModel.willAdvanceOnNextTap {
            slideEdge = .trailing
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            viewModel.onTap()
        }
    }

    private var swipeNavigationGesture: some Gesture {
        DragGesture(minimumDistance: 50, coordinateSpace: .local)
            .onEnded { dragValue in
                let threshold: CGFloat = 60
                let swipedRight = dragValue.translation.width > threshold
                let swipedLeft = dragValue.translation.width < -threshold

                // In RTL (Arabic): swiping right goes forward, swiping left goes back
                // In LTR (English): swiping left goes forward, swiping right goes back
                let isForwardSwipe = isRightToLeft ? swipedRight : swipedLeft
                let isBackwardSwipe = isRightToLeft ? swipedLeft : swipedRight

                if isForwardSwipe && viewModel.canGoNext {
                    slideEdge = .trailing
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        viewModel.navigateToNext()
                    }
                } else if isBackwardSwipe && viewModel.canGoPrevious {
                    slideEdge = .leading
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        viewModel.navigateToPrevious()
                    }
                }
            }
    }
}

// MARK: - Reading Navigation Bar

extension AdhkarReadingView {

    private var readingNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(10)
            }

            Spacer()

            Text(isRightToLeft ? viewModel.category.titleAr : viewModel.category.titleEn)
                .customStyle(.heading3, .onSurface)

            Spacer()

            if viewModel.hasAudio {
                Button(action: { viewModel.toggleAudio() }) {
                    Image(systemName: viewModel.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 14, weight: .medium))
                        .customForeground(viewModel.isPlaying ? .secondary : .onSurface)
                        .frame(width: 36, height: 36)
                        .background(
                            viewModel.isPlaying
                                ? ColorStyle.secondary.color.opacity(0.12)
                                : Color.surfaceContainerLow
                        )
                        .cornerRadius(10)
                }
            } else {
                Text("\(viewModel.currentIndex + 1) / \(viewModel.category.adhkar.count)")
                    .customStyle(.caption2, .onSurfaceVariant)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Dhikr Reading Content

extension AdhkarReadingView {

    private var dhikrReadingContent: some View {
        VStack(spacing: 0) {
            progressBar

            Spacer()

            if let dhikr = viewModel.currentDhikr {
                dhikrCard(dhikr: dhikr)
                    .id(viewModel.currentIndex)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: slideEdge).combined(with: .opacity),
                            removal: .move(edge: slideEdge == .trailing ? .leading : .trailing).combined(with: .opacity)
                        )
                    )
            }

            Spacer()

            tapCounterView
                .padding(.bottom, 40)
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Color.surfaceContainerLow.frame(height: 2)
                ColorStyle.secondary.color
                    .frame(width: geometry.size.width * viewModel.overallProgress, height: 2)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.overallProgress)
            }
        }
        .frame(height: 2)
    }

    private func dhikrCard(dhikr: Dhikr) -> some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ColorStyle.secondary.color)
                .frame(width: 40, height: 3)
                .cornerRadius(2)
                .padding(.bottom, 20)

            if let sectionTitle = dhikr.title, !sectionTitle.isEmpty {
                Text(sectionTitle)
                    .customStyle(.caption1, .secondary)
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, .big)
                    .padding(.bottom, 16)
            }

            Text(dhikr.textAr)
                .font(.custom("HafsSmart_08_fixed", size: 26))
                .foregroundColor(ColorStyle.onSurface.color)
                .multilineTextAlignment(.center)
                .lineSpacing(14)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, .big)

            if let explanationText = dhikr.description, !explanationText.isEmpty {
                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.4))
                    .frame(height: 1)
                    .padding(.horizontal, .big)
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                Text(explanationText)
                    .font(.custom("HafsSmart_08_fixed", size: 15))
                    .foregroundColor(ColorStyle.onSurfaceVariant.color)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, .big)
            }
        }
    }

    private var tapCounterView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ColorStyle.primary.color.opacity(0.08))
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: viewModel.tapProgress)
                    .stroke(
                        ColorStyle.secondary.color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.15), value: viewModel.tapProgress)

                VStack(spacing: 2) {
                    Text(AppLocalizedKeys.tapToCount.value.uppercased())
                        .font(.system(size: 10, weight: .medium))
                        .customForeground(.onSurfaceVariant)
                    Text("\(viewModel.currentTapCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .customForeground(.primary)
                }
            }
            .scaleEffect(tapPulse ? 0.93 : 1.0)

            if let currentDhikr = viewModel.currentDhikr {
                let remainingCount = currentDhikr.count - viewModel.currentTapCount
                Text("REMAINING: \(remainingCount)")
                    .font(.system(size: 12, weight: .medium))
                    .customForeground(.onSurfaceVariant)
                    .opacity(remainingCount > 0 ? 1 : 0)
            }
        }
    }
}

// MARK: - Ambient Glow Background

extension AdhkarReadingView {

    private var ambientGlowBackground: some View {
        ZStack {
            Circle()
                .fill(ColorStyle.primary.color.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -60, y: -120)

            Circle()
                .fill(ColorStyle.secondary.color.opacity(0.04))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: 80, y: 200)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Completion View

extension AdhkarReadingView {

    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(ColorStyle.secondary.color)

            VStack(spacing: 8) {
                Text(AppLocalizedKeys.adhkarCompleted.value)
                    .customStyle(.heading2, .onSurface)

                Text(AppLocalizedKeys.adhkarCompletedMessage.value)
                    .customStyle(.bodyMedium, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: { viewModel.reset() }) {
                    Text(AppLocalizedKeys.repeatAction.value)
                        .customStyle(.headline, .onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ColorStyle.primary.color)
                        .cornerRadius(14)
                }

                Button(action: { dismiss() }) {
                    Text(AppLocalizedKeys.back.value)
                        .customStyle(.headline, .onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.surfaceContainerLow)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, .big)
            .padding(.bottom, 40)
        }
    }
}
