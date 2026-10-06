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
                    readingProgressBar

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

            Text(displayTitle)
                .customStyle(.adhkar(size: 22, bold: true), .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Spacer()

            navIconButton(systemName: "bookmark", isActive: false, action: {})
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.background)
    }

    /// Reading progress for the whole category, sitting flush under the nav bar.
    private var readingProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.2))

                Rectangle()
                    .fill(progressGradient)
                    .frame(width: geo.size.width * viewModel.overallProgress)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.overallProgress)
            }
        }
        .frame(height: 3)
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [ColorStyle.primary.color, ColorStyle.secondary.color],
            startPoint: .leading,
            endPoint: .trailing
        )
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
                dhikrContentCard
                    .id(viewModel.currentIndex)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: slideEdge).combined(with: .opacity),
                            removal: .move(edge: slideEdge == .trailing ? .leading : .trailing)
                                .combined(with: .opacity)
                        )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 28)

                Color.clear.frame(height: 160)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { handleAdvance() }
        .simultaneousGesture(swipeNavigationGesture)
    }
}

// MARK: - Dhikr Segments Content

extension AdhkarReadingView {

    private var dhikrSegmentsContent: some View {
        let segments = viewModel.currentSegments

        return VStack(spacing: 22) {
            ForEach(segments.indices, id: \.self) { index in
                segmentView(segments[index])
            }

            if let repeatLabel = viewModel.repeatLabel, !repeatLabel.isEmpty {
                segmentDivider

                arabicTextBlock(
                    repeatLabel,
                    style: .adhkar(size: 17),
                    color: .onSurface,
                    lineSpacing: 8
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// Athkar's segments, wrapped in Wird's own card chrome.
    private var dhikrContentCard: some View {
        dhikrSegmentsContent
            .padding(.horizontal, 28)
            .padding(.vertical, 36)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .topTrailing) {
                Image(systemName: viewModel.category.icon)
                    .font(.system(size: 120, weight: .thin))
                    .customForeground(.adhkarWatermark)
                    .offset(x: 10, y: 16)
                    .allowsHitTesting(false)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.adhkarSurface)
                    .shadow(color: .adhkarShadow, radius: 22, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.adhkarHairline, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder
    private func segmentView(_ segment: DhikrSegment) -> some View {
        switch segment.kind {
        case .rule:
            segmentDivider

        case .quran:
            if let text = segment.text, !text.isEmpty {
                Text(quranAttributedText(text))
                    .foregroundColor(ColorStyle.onSurface.color)
                    .multilineTextAlignment(.center)
                    .lineSpacing(20)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity)
            }

        case .intro:
            if let text = segment.text, !text.isEmpty {
                arabicTextBlock(text, style: .adhkar(size: 18), color: .secondary, lineSpacing: 10)
            }

        case .text:
            if let text = segment.text, !text.isEmpty {
                arabicTextBlock(text, style: .adhkar(size: 22), color: .onSurface, lineSpacing: 16)
            }

        case .note, .noteAlways:
            if let text = segment.text, !text.isEmpty {
                arabicTextBlock(text, style: .adhkar(size: 15), color: .secondary, lineSpacing: 7)
            }
        }
    }

    private var segmentDivider: some View {
        Divider()
            .overlay(ColorStyle.outlineVariant.color.opacity(0.3))
    }

    /// Centred, right-to-left block that keeps every newline in the source text.
    private func arabicTextBlock(
        _ text: String,
        style: AppTextStyle,
        color: ColorStyle,
        lineSpacing: CGFloat
    ) -> some View {
        Text(text)
            .customStyle(style, color)
            .multilineTextAlignment(.center)
            .lineSpacing(lineSpacing)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.layoutDirection, .rightToLeft)
            .frame(maxWidth: .infinity)
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
        // Resolved through QuranFont so the real PostScript name is used —
        // a raw file name silently falls back to the system font, which has
        // no glyph for the ornamented ayah medallion.
        let hafs = QuranFont.hafs.font(size: 30)
        var textBuf = ""
        var digitBuf = ""

        func flushText() {
            guard !textBuf.isEmpty else { return }
            var seg = AttributedString(textBuf)
            seg.font = hafs
            result.append(seg)
            textBuf = ""
        }

        func flushDigits() {
            guard !digitBuf.isEmpty else { return }
            let latin = String(digitBuf.map { digitMap[$0] ?? $0 })
            // HafsSmart carries the fully ornamented ayah medallion in its
            // private-use area, the same way Athkar gets it from UthmanicHafs.
            // QuranNumbers holds bare digits only and needs an ornament image
            // composited behind it — that is the mushaf renderer's job, not this
            // screen's, so using it here drew an unornamented number.
            if let num = Int(latin), let glyph = QuranTextService.verseEndGlyph(for: num) {
                var seg = AttributedString(glyph)
                seg.font = hafs
                result.append(seg)
            } else {
                var seg = AttributedString(digitBuf)
                seg.font = hafs
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
        VStack(spacing: 8) {
            positionIndicator

            pillBar
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 0)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    /// Where the reader is inside the category — bottom-left in both languages.
    private var positionIndicator: some View {
        Text("\(en(viewModel.currentIndex + 1)) | \(en(viewModel.category.adhkar.count))")
            .customStyle(.adhkar(size: 13), .outline)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
            .padding(.horizontal, 8)
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
                            .fill(Color.adhkarSurface)
                            .overlay(Circle().stroke(Color.adhkarHairline, lineWidth: 1))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.adhkarSurfaceTranslucent)
                .overlay(Capsule().stroke(Color.adhkarHairline, lineWidth: 1))
                .shadow(color: .adhkarShadow, radius: 20, x: 0, y: 7)
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
                        .fill(isActive ? ColorStyle.secondary.color.opacity(0.14) : Color.adhkarSurface)
                        .overlay(Circle().stroke(
                            isActive ? ColorStyle.secondary.color.opacity(0.3) : Color.adhkarHairline,
                            lineWidth: 1
                        ))
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    private var countRingButton: some View {
        // Deliberate deviation from Athkar, which counts down. Before the first
        // tap the ring shows the target; from then on the tally climbs 1...count.
        let total = viewModel.currentDhikr?.count ?? 0
        let shown = viewModel.currentTapCount == 0 ? total : viewModel.currentTapCount

        return Button(action: { handleAdvance() }) {
            ZStack {
                Circle()
                    .stroke(Color.adhkarRingTrack, lineWidth: 3)
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
                    .fill(Color.adhkarSurface)
                    .overlay(Circle().stroke(Color.adhkarHairline, lineWidth: 1))
                    .frame(width: 56, height: 56)

                Text(en(shown))
                    .customStyle(.adhkar(size: 20, bold: true), .onSurface)
                    .monospacedDigit()
                    .animation(.easeOut(duration: 0.2), value: shown)
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
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { dragValue in
                let horizontal = dragValue.translation.width
                let vertical = dragValue.translation.height
                let threshold: CGFloat = 50

                // A mostly vertical drag belongs to the scroll view, not to navigation.
                guard abs(horizontal) >= threshold, abs(horizontal) > abs(vertical) * 1.5 else { return }

                let swipedRight = horizontal > 0
                let isForwardSwipe = isRightToLeft ? swipedRight : !swipedRight

                if isForwardSwipe {
                    guard viewModel.canGoNext else { return }
                    slideEdge = .trailing
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        viewModel.navigateToNext()
                    }
                } else {
                    guard viewModel.canGoPrevious else { return }
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
                        .customCornerRadius(14)
                }
                Button(action: { viewModel.goBack() }) {
                    Text(AppLocalizedKeys.back.value)
                        .customStyle(.headline, .onSurface)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.surfaceContainerLow)
                        .customCornerRadius(14)
                }
            }
            .padding(.horizontal, .big)
            .padding(.bottom, 40)
        }
    }
}
