//
//  TasbihCounterView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-24.
//

import SwiftUI
import Core

// MARK: - ViewModel

@MainActor
final class TasbihCounterViewModel: ObservableObject {

    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var currentCount: Int = 0
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var justCompleted: Bool = false

    let category: DhikrCategory
    weak var coordinator: AdhkarCoordinating?

    init(coordinator: AdhkarCoordinating, category: DhikrCategory) {
        self.category = category
        self.coordinator = coordinator
    }

    var currentDhikr: Dhikr? {
        guard currentIndex < category.adhkar.count else { return nil }
        return category.adhkar[currentIndex]
    }

    var targetCount: Int { currentDhikr?.count ?? 33 }

    var tapProgress: CGFloat {
        guard targetCount > 0 else { return 0 }
        return min(CGFloat(currentCount) / CGFloat(targetCount), 1.0)
    }

    var totalDhikr: Int { category.adhkar.count }

    func tap() {
        guard targetCount > 0 else { return }
        currentCount += 1
        if currentCount >= targetCount {
            justCompleted = true
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                justCompleted = false
                advance()
            }
        }
    }

    func reset() {
        currentCount = 0
    }

    func advance() {
        currentCount = 0
        if currentIndex + 1 < category.adhkar.count {
            currentIndex += 1
        } else {
            isComplete = true
        }
    }

    func restart() {
        currentIndex = 0
        currentCount = 0
        isComplete = false
        justCompleted = false
    }

    func goBack() {
        coordinator?.coordinateBack()
    }
}

// MARK: - View

struct TasbihCounterView: View {

    @StateObject private var viewModel: TasbihCounterViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var tapPulse: Bool = false

    init(coordinator: AdhkarCoordinating, category: DhikrCategory) {
        _viewModel = StateObject(wrappedValue: TasbihCounterViewModel(coordinator: coordinator, category: category))
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            ambientGlow

            VStack(spacing: 0) {
                navBar
                if viewModel.isComplete {
                    completionView
                } else {
                    counterContent
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Nav Bar

extension TasbihCounterView {

    private var navBar: some View {
        HStack {
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(10)
            }
            Spacer()
            Text(viewModel.category.titleAr)
                .customStyle(.heading3, .onSurface)
            Spacer()
            Text("\(viewModel.currentIndex + 1)/\(viewModel.totalDhikr)")
                .customStyle(.caption2, .onSurfaceVariant)
                .frame(width: 36)
                .monospacedDigit()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Counter Content

extension TasbihCounterView {

    private var counterContent: some View {
        VStack(spacing: 0) {
            if let dhikr = viewModel.currentDhikr {
                dhikrTextSection(dhikr)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                Spacer()

                counterRing
                    .padding(.bottom, 44)

                bottomActions
                    .padding(.bottom, 44)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                tapPulse = true
            }
            viewModel.tap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                tapPulse = false
            }
        }
    }

    private func dhikrTextSection(_ dhikr: Dhikr) -> some View {
        VStack(spacing: 10) {
            Text(dhikr.textAr)
                .customStyle(.quranPageFixed(size: 26), .onSurface)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity)

            if let title = dhikr.title, !title.isEmpty {
                Text(title)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private var counterRing: some View {
        ZStack {
            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : ColorStyle.primary.color.opacity(0.08),
                    lineWidth: 10
                )
                .frame(width: 168, height: 168)

            Circle()
                .trim(from: 0, to: viewModel.tapProgress)
                .stroke(
                    LinearGradient(
                        colors: [ColorStyle.primary.color, ColorStyle.secondary.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 168, height: 168)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.15), value: viewModel.tapProgress)

            Circle()
                .fill(
                    viewModel.justCompleted
                        ? ColorStyle.secondary.color.opacity(0.15)
                        : (colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
                )
                .frame(width: 144, height: 144)
                .animation(.easeOut(duration: 0.25), value: viewModel.justCompleted)

            VStack(spacing: 2) {
                Text("\(viewModel.currentCount)")
                    .customStyle(.adhkar(size: 48, bold: true), viewModel.justCompleted ? .secondary : .onSurface)
                    .monospacedDigit()
                    .animation(.easeOut(duration: 0.2), value: viewModel.justCompleted)

                if viewModel.targetCount > 0 {
                    Text("/ \(viewModel.targetCount)")
                        .customStyle(.adhkar(size: 14), .onSurfaceVariant)
                        .monospacedDigit()
                }
            }
        }
        .scaleEffect(tapPulse ? 0.95 : 1.0)
        .scaleEffect(viewModel.justCompleted ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: viewModel.justCompleted)
    }

    private var bottomActions: some View {
        HStack(spacing: 20) {
            Button(action: { viewModel.reset() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.onSurfaceVariant)
                    .frame(width: 50, height: 50)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)

            Button(action: { viewModel.advance() }) {
                HStack(spacing: 6) {
                    Text("التالي")
                        .customStyle(.headline, .onSurface)
                    Image(systemName: "chevron.left")
                        .customStyle(.adhkar(size: 13), .onSurface)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 13)
                .background(Color.surfaceContainerLow)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(ColorStyle.outlineVariant.color.opacity(0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Ambient Glow

extension TasbihCounterView {

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(ColorStyle.primary.color.opacity(0.05))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -80, y: -120)

            Circle()
                .fill(ColorStyle.secondary.color.opacity(0.04))
                .frame(width: 240, height: 240)
                .blur(radius: 50)
                .offset(x: 80, y: 200)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Completion View

extension TasbihCounterView {

    private var completionView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ColorStyle.secondary.color.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundColor(ColorStyle.secondary.color)
            }

            VStack(spacing: 8) {
                Text(AppLocalizedKeys.adhkarCompleted.value)
                    .customStyle(.heading2, .onSurface)
                Text(AppLocalizedKeys.adhkarCompletedMessage.value)
                    .customStyle(.bodyMedium, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: { viewModel.restart() }) {
                    Text(AppLocalizedKeys.repeatAction.value)
                        .customStyle(.headline, .onPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(ColorStyle.primary.color)
                        .cornerRadius(14)
                }
                Button(action: { viewModel.goBack() }) {
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
