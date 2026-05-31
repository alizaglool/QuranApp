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
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var localizationManager: LocalizationManager

    @State private var tapPulse: Bool = false
    @State private var slideEdge: Edge = .trailing
    @State private var isBookmarked: Bool = false

    init(coordinator: AdhkarCoordinating, category: DhikrCategory) {
        _viewModel = StateObject(wrappedValue: AdhkarReadingViewModel(coordinator: coordinator, category: category))
    }

    private var isRightToLeft: Bool {
        localizationManager.currentLanguage == .Arabic
    }

    private func en(_ n: Int) -> String {
        String(format: "%d", n)
    }

    private var displayTitle: String {
        isRightToLeft ? viewModel.category.titleAr : viewModel.category.titleEn
    }

    private var shareText: String {
        guard let dhikr = viewModel.currentDhikr else { return "" }
        var parts: [String] = [dhikr.textAr]
        if let desc = dhikr.description, !desc.isEmpty { parts.append(desc) }
        if let ref  = dhikr.title,        !ref.isEmpty  { parts.append(ref) }
        return parts.joined(separator: "\n\n")
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            ZStack(alignment: .bottom) {
                Color.background.ignoresSafeArea()
                ambientGlowBackground

                VStack(spacing: 0) {
                    readingNavigationBar

                    if viewModel.isComplete {
                        completionView
                    } else {
                        dhikrScrollContent
                    }
                }

                if !viewModel.isComplete {
                    bottomPanel
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Navigation Bar

extension AdhkarReadingView {

    private var readingNavigationBar: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.primary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(AppLocalizedKeys.adhkar.value)
                .customStyle(.kitab(size: 22, bold: true))                .customForeground(.primary)

            Spacer()

            HStack(spacing: 4) {
                if viewModel.hasAudio {
                    navIconButton(
                        systemName: viewModel.isPlaying ? "speaker.slash" : "speaker.wave.2",
                        isActive: viewModel.isPlaying,
                        action: { viewModel.toggleAudio() }
                    )
                }
                navIconButton(systemName: "bookmark", isActive: false, action: {})
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ColorStyle.outlineVariant.color.opacity(0.15))
                .frame(height: 0.5)
        }
    }

    private func navIconButton(
        systemName: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .regular))
                .customForeground(isActive ? .primary : .onSurfaceVariant)
                .frame(width: 40, height: 40)
        }
    }
}

// MARK: - Main Scroll Content

extension AdhkarReadingView {

    private var dhikrScrollContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                categoryProgressHeader
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 28)

                if let dhikr = viewModel.currentDhikr {
                    dhikrContentCard(dhikr: dhikr)
                        .id(viewModel.currentIndex)
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: slideEdge).combined(with: .opacity),
                                removal: .move(edge: slideEdge == .trailing ? .leading : .trailing)
                                    .combined(with: .opacity)
                            )
                        )
                        .padding(.horizontal, 16)
                }

                Color.clear.frame(height: 160)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { handleAdvance() }
        .gesture(swipeNavigationGesture)
    }

    private var categoryProgressHeader: some View {
        HStack(alignment: .bottom, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalizedKeys.adhkar.value.uppercased())
                    .customStyle(.kitab(size: 10, bold: true))                    .kerning(2.4)
                    .customForeground(.outline)

                Text(displayTitle)
                    .customStyle(.kitab(size: 26))                    .customForeground(.onSurface)
                    .lineLimit(2)
            }

            Spacer(minLength: 16)

            VStack(alignment: .trailing, spacing: 6) {
                Text(AppLocalizedKeys.progress.value.uppercased())
                    .customStyle(.kitab(size: 10, bold: true))                    .kerning(2.2)
                    .customForeground(.primary)

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(en(viewModel.currentIndex + 1))
                        .customStyle(.kitab(size: 28))                        .monospacedDigit()
                        .customForeground(.onSurface)
                    Text("/ \(en(viewModel.category.adhkar.count))")
                        .customStyle(.kitab(size: 14))                        .monospacedDigit()
                        .customForeground(.outline)
                }
            }
        }
    }
}

// MARK: - Dhikr Content Card

extension AdhkarReadingView {

    private func dhikrContentCard(dhikr: Dhikr) -> some View {
        let cardFill: Color = colorScheme == .dark
            ? Color.surfaceContainerHigh
            : Color.surfaceContainerLow
        let borderColor: Color = colorScheme == .dark
            ? Color.white.opacity(0.05)
            : ColorStyle.primary.color.opacity(0.10)
        let shadowColor: Color = colorScheme == .dark
            ? Color.black.opacity(0.50)
            : ColorStyle.primary.color.opacity(0.10)

        return VStack(spacing: 0) {

            Text(quranAttributedText(dhikr.textAr))
                .foregroundColor(ColorStyle.onSurface.color)
                .multilineTextAlignment(.center)
                .lineSpacing(20)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 32)

            if let description = dhikr.description, !description.isEmpty {
                Divider()
                    .overlay(ColorStyle.outlineVariant.color.opacity(0.3))
                    .padding(.bottom, 16)

                Text(description)
                    .customStyle(.kitab(size: 15))                    .customForeground(.onSurfaceVariant)
                    .multilineTextAlignment(isRightToLeft ? .trailing : .leading)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
                    .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .topTrailing) {
            Image(systemName: viewModel.category.icon)
                .font(.system(size: 120, weight: .thin))
                .customForeground(.primary)
                .opacity(colorScheme == .dark ? 0.09 : 0.07)
                .offset(x: 10, y: 16)
                .allowsHitTesting(false)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardFill)
                .shadow(
                    color: shadowColor,
                    radius: colorScheme == .dark ? 24 : 20,
                    x: 0,
                    y: colorScheme == .dark ? 10 : 6
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

}

// MARK: - Quran Text Attributed String

extension AdhkarReadingView {

    private func quranAttributedText(_ text: String) -> AttributedString {
        var result = AttributedString()
        let arabicDigits: Set<Character> = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        let digitMap: [Character: Character] = [
            "٠":"0","١":"1","٢":"2","٣":"3","٤":"4",
            "٥":"5","٦":"6","٧":"7","٨":"8","٩":"9"
        ]
        var textBuf = ""
        var digitBuf = ""

        func flushText() {
            guard !textBuf.isEmpty else { return }
            var seg = AttributedString(textBuf)
            seg.font = .custom("HafsSmart_08_fixed", size: 30)
            result.append(seg)
            textBuf = ""
        }

        func flushDigits() {
            guard !digitBuf.isEmpty else { return }
            let latin = String(digitBuf.map { digitMap[$0] ?? $0 })
            if let num = Int(latin), num >= 1, num <= 286,
               let scalar = Unicode.Scalar(0xE900 + num - 1) {
                var seg = AttributedString(String(scalar))
                seg.font = .custom("QuranNumbers", size: 28)
                result.append(seg)
            } else {
                var seg = AttributedString(digitBuf)
                seg.font = .custom("HafsSmart_08_fixed", size: 30)
                result.append(seg)
            }
            digitBuf = ""
        }

        for ch in text {
            if arabicDigits.contains(ch) {
                flushText()
                digitBuf.append(ch)
            } else {
                flushDigits()
                textBuf.append(ch)
            }
        }
        flushText()
        flushDigits()
        return result
    }
}

// MARK: - Bottom Pill Bar

extension AdhkarReadingView {

    private var bottomPanel: some View {
        VStack(spacing: 10) {
            if let dhikr = viewModel.currentDhikr, dhikr.count > 1 {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(en(viewModel.currentTapCount))
                        .customStyle(.kitab(size: 15, bold: true))                        .monospacedDigit()
                        .customForeground(.onSurface)
                    Text("/ \(en(dhikr.count))")
                        .customStyle(.kitab(size: 12))                        .monospacedDigit()
                        .customForeground(.outline)
                }
                .animation(.easeOut(duration: 0.2), value: viewModel.currentTapCount)
            }

            pillBar
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 0)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private var pillBar: some View {
        let needsCount = (viewModel.currentDhikr?.count ?? 1) > 1

        return HStack(spacing: 0) {
            pillCircleButton(
                systemName: isBookmarked ? "star.fill" : "star",
                isActive: isBookmarked
            ) {
                isBookmarked.toggle()
            }

            Spacer()

            if needsCount {
                pillCircleButton(systemName: "arrow.counterclockwise") {
                    viewModel.resetCurrentCount()
                }
                Spacer()
            }

            if needsCount {
                countRingButton
                Spacer()
            }

            pillCircleButton(
                systemName: viewModel.isPlaying ? "pause.fill" : "play.fill",
                disabled: !viewModel.hasAudio
            ) {
                viewModel.toggleAudio()
            }

            Spacer()

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color.surfaceContainerHigh : Color.surfaceContainerLow)
                            .overlay(Circle().stroke(
                                colorScheme == .dark ? Color.white.opacity(0.05) : ColorStyle.primary.color.opacity(0.08),
                                lineWidth: 1
                            ))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(
                    colorScheme == .dark
                        ? Color.surfaceContainerHigh.opacity(0.88)
                        : Color.surfaceContainerLow.opacity(0.95)
                )
                .overlay(Capsule().stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.06)
                        : ColorStyle.primary.color.opacity(0.08),
                    lineWidth: 1
                ))
                .shadow(
                    color: colorScheme == .dark ? .black.opacity(0.4) : ColorStyle.primary.color.opacity(0.12),
                    radius: colorScheme == .dark ? 24 : 16,
                    x: 0,
                    y: colorScheme == .dark ? 10 : 4
                )
        )
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func pillCircleButton(
        systemName: String,
        disabled: Bool = false,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .medium))
                .customForeground(
                    disabled ? .outline :
                    isActive  ? .secondary :
                    .onSurface
                )
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(
                            isActive
                                ? ColorStyle.secondary.color.opacity(0.14)
                                : (colorScheme == .dark ? Color.surfaceContainerHigh : Color.surfaceContainerLow)
                        )
                        .overlay(Circle().stroke(
                            isActive
                                ? ColorStyle.secondary.color.opacity(0.3)
                                : (colorScheme == .dark ? Color.white.opacity(0.05) : ColorStyle.primary.color.opacity(0.08)),
                            lineWidth: 1
                        ))
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var countRingButton: some View {
        Button(action: { handleAdvance() }) {
            ZStack {
                Circle()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.10) : ColorStyle.primary.color.opacity(0.12),
                        lineWidth: 3
                    )
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: viewModel.tapProgress)
                    .stroke(
                        LinearGradient(
                            colors: [ColorStyle.primary.color, ColorStyle.secondary.color],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.2), value: viewModel.tapProgress)

                Circle()
                    .fill(colorScheme == .dark ? Color.surfaceContainerHigh : Color.surfaceContainerLow)
                    .overlay(Circle().stroke(
                        colorScheme == .dark ? Color.white.opacity(0.05) : ColorStyle.primary.color.opacity(0.08),
                        lineWidth: 1
                    ))
                    .frame(width: 56, height: 56)

                Text(en(viewModel.currentTapCount))
                    .customStyle(.kitab(size: 20, bold: true))                    .monospacedDigit()
                    .customForeground(.onSurface)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(tapPulse ? 0.92 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.5), value: tapPulse)
    }
}

// MARK: - Advance Logic

extension AdhkarReadingView {

    private func handleAdvance() {
        withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
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
        DragGesture(minimumDistance: 15, coordinateSpace: .local)
            .onEnded { dragValue in
                let threshold: CGFloat = 30
                let swipedRight = dragValue.translation.width > threshold
                let swipedLeft  = dragValue.translation.width < -threshold

                let isForwardSwipe  = isRightToLeft ? swipedRight : swipedLeft
                let isBackwardSwipe = isRightToLeft ? swipedLeft  : swipedRight

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

// MARK: - Ambient Glow Background

extension AdhkarReadingView {

    private var ambientGlowBackground: some View {
        ZStack {
            Circle()
                .fill(ColorStyle.primary.color.opacity(0.05))
                .frame(width: 380, height: 380)
                .blur(radius: 60)
                .offset(x: -100, y: -160)

            Circle()
                .fill(ColorStyle.secondary.color.opacity(0.04))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 100, y: 260)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Completion View

extension AdhkarReadingView {

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
                Button(action: { viewModel.reset() }) {
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
