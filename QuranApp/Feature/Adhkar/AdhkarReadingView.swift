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

    init(category: DhikrCategory) {
        _viewModel = StateObject(wrappedValue: AdhkarReadingViewModel(category: category))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            ZStack {
                Color.background.ignoresSafeArea()
                ambientGlow
                VStack(spacing: 0) {
                    navBar
                    if viewModel.isComplete {
                        completionView
                    } else {
                        dhikrContent
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Nav Bar

extension AdhkarReadingView {

    private var navBar: some View {
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

            Text(localizationManager.currentLanguage == .Arabic ? viewModel.category.titleAr : viewModel.category.titleEn)
                .customStyle(.heading3, .onSurface)

            Spacer()

            Text("\(viewModel.currentIndex + 1) / \(viewModel.category.adhkar.count)")
                .customStyle(.caption2, .onSurfaceVariant)
                .monospacedDigit()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Dhikr Content

extension AdhkarReadingView {

    private var dhikrContent: some View {
        VStack(spacing: 0) {
            // Progress bar across top
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.surfaceContainerLow.frame(height: 2)
                    ColorStyle.secondary.color
                        .frame(width: geo.size.width * viewModel.overallProgress, height: 2)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.overallProgress)
                }
            }
            .frame(height: 2)

            Spacer()

            if let dhikr = viewModel.currentDhikr {
                dhikrCard(dhikr: dhikr)
            }

            Spacer()

            counterButton
                .padding(.bottom, 40)
        }
    }

    private func dhikrCard(dhikr: Dhikr) -> some View {
        VStack(spacing: 28) {
            // Gold accent
            Rectangle()
                .fill(ColorStyle.secondary.color)
                .frame(width: 40, height: 3)
                .cornerRadius(2)

            // Optional title (section header)
            if let title = dhikr.title, !title.isEmpty {
                Text(title)
                    .customStyle(.caption1, .secondary)
                    .multilineTextAlignment(.center)
                    .tracking(0.5)
            }

            // Arabic text
            Text(dhikr.textAr)
                .font(.custom("HafsSmart_08_fixed", size: 22))
                .foregroundColor(ColorStyle.onSurface.color)
                .multilineTextAlignment(.center)
                .lineSpacing(14)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, .big)
        }
    }

    private var counterButton: some View {
        VStack(spacing: 12) {
            Button(action: { viewModel.onTap() }) {
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
            }
            .buttonStyle(CounterButtonStyle())

            if let dhikr = viewModel.currentDhikr {
                let remaining = dhikr.count - viewModel.currentTapCount
                Text("REMAINING: \(remaining)")
                    .font(.system(size: 12, weight: .medium))
                    .customForeground(.onSurfaceVariant)
                    .opacity(remaining > 0 ? 1 : 0)
            }
        }
    }
}

// MARK: - Ambient Glow

extension AdhkarReadingView {

    private var ambientGlow: some View {
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

// MARK: - Completion

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

// MARK: - Counter Button Style

struct CounterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
