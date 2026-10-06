//
//  ProhibitedTimesView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import SwiftUI
import Core

struct ProhibitedTimesView: View {

    let coordinator: AdhkarCoordinating
    @StateObject private var viewModel = ProhibitedTimesViewModel()

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                NoIndicatorsScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        hadithCard
                        intro
                        windowsList
                        exemptionsSection
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - Nav Bar

extension ProhibitedTimesView {

    private var navBar: some View {
        HStack {
            Button(action: coordinator.coordinateBack) {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .customCornerRadius(10)
            }
            Spacer()
            Text(viewModel.title)
                .customStyle(.heading3, .onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Header

extension ProhibitedTimesView {

    private var hadithCard: some View {
        // Centred: both children stretch to the full width and centre their own
        // text, so a trailing alignment here only looked like it did something.
        VStack(alignment: .center, spacing: .sm) {
            if let hadith = viewModel.content?.hadithAr {
                Text(hadith)
                    .customStyle(.adhkar(size: 19), .onSurface)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity)
            }
            if let source = viewModel.content?.hadithSourceAr {
                Text(source)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(ColorStyle.washSecondarySubtle.color)
        .customCornerRadius(16)
        .padding(.horizontal, .big)
        .padding(.top, .sm)
    }

    private var intro: some View {
        Group {
            if let intro = viewModel.content?.introAr {
                Text(intro)
                    .customStyle(.subheadline, .onSurfaceVariant)
                    .padding(.horizontal, .big)
            }
        }
    }
}

// MARK: - Windows

extension ProhibitedTimesView {

    private var windowsList: some View {
        VStack(spacing: 12) {
            ForEach(Array(viewModel.windows.enumerated()), id: \.element.id) { index, window in
                windowRow(window, number: index + 1)
            }
        }
        .padding(.horizontal, .big)
    }

    private func windowRow(_ window: ProhibitedWindow, number: Int) -> some View {
        let isActive = viewModel.isActive(window)
        let isExpanded = viewModel.isExpanded(window)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { viewModel.toggle(window) }
            } label: {
                HStack(spacing: .sm) {
                    numberMedallion(number, isActive: isActive)

                    VStack(alignment: .leading, spacing: .xxSm) {
                        HStack(spacing: .xSm) {
                            Text(window.titleAr)
                                .customStyle(.headline, .onSurface)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            if isActive { activeBadge }
                        }
                        Text(window.subtitleAr)
                            .customStyle(.caption2, .onSurfaceVariant)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .customForeground(.onSurfaceVariant)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.md)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(window.titleAr)
            .accessibilityValue(viewModel.accessibilityValue(for: window))
            .accessibilityHint(viewModel.accessibilityHint(for: window))

            if isExpanded {
                windowDetail(window)
            }
        }
        .background(Color.cardSurface)
        .customCornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? ColorStyle.error.color : ColorStyle.cardBorder.color,
                        lineWidth: isActive ? 1.5 : 1)
        )
    }

    /// The live window has to be identifiable without seeing the red border, so
    /// the state gets a label of its own rather than colour alone.
    ///
    /// Solid fill rather than the 0.14 tint the rest of the screen uses: `error`
    /// ink on that tint measures 3.89:1 light and 3.26:1 dark, under the 4.5:1
    /// minimum for text this size. `Error` is #DC2626 in both appearances, so
    /// white on it clears the bar at 4.83:1 either way, and the filled capsule
    /// reads 4.83:1 light / 3.53:1 dark against the card — shape contrast enough
    /// that the stroke it used to carry adds nothing.
    private var activeBadge: some View {
        Text(viewModel.activeBadgeTitle)
            .customStyle(.caption2, .onPrimary)
            .padding(.horizontal, .xSm)
            .padding(.vertical, .xxSm)
            .background(Capsule().fill(ColorStyle.error.color))
            .fixedSize()
    }

    private func numberMedallion(_ number: Int, isActive: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isActive ? ColorStyle.error.color.opacity(0.14) : ColorStyle.washSecondary.color)
                .frame(width: 36, height: 36)
            // Interpolating an Int is locale-independent, so the numerals stay
            // Western, matching the reading screen's counter.
            //
            // The digit reads `onSurface` in both states: over these two
            // translucent fills the tinted inks measured 3.2:1 to 3.5:1, under
            // the 4.5:1 text minimum. The circle carries the state instead.
            Text("\(number)")
                .customStyle(.headline, .onSurface)
        }
    }

    private func windowDetail(_ window: ProhibitedWindow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Rectangle()
                .fill(ColorStyle.cardBorder.color)
                .frame(height: 1)

            ForEach(window.bullets, id: \.self) { bullet in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(ColorStyle.secondary.color)
                        .frame(width: 5, height: 5)
                        .padding(.top, 7)
                    Text(bullet)
                        .customStyle(.bodySmall, .onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let hadith = window.hadithAr {
                VStack(alignment: .leading, spacing: 6) {
                    Text(hadith)
                        .customStyle(.adhkar(size: 17), .onSurface)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                    if let source = window.hadithSourceAr {
                        Text(source)
                            .customStyle(.caption2, .onSurfaceVariant)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.md)
                .background(ColorStyle.washSecondarySubtle.color)
                .customCornerRadius(12)
            }
        }
        .padding(.horizontal, .md)
        .padding(.bottom, .md)
    }
}

// MARK: - Exemptions

extension ProhibitedTimesView {

    private var exemptionsSection: some View {
        Group {
            if let content = viewModel.content, !content.exemptions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text(content.exemptionsTitleAr)
                        .customStyle(.heading3, .onSurface)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(content.exemptions, id: \.self) { item in
                            HStack(alignment: .top, spacing: .sm) {
                                // Decorative: the sentence beside it already
                                // says this is an exemption.
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .customForeground(.success)
                                    .accessibilityHidden(true)
                                Text(item)
                                    .customStyle(.bodySmall, .onSurface)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardSurface)
                    .customCornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
                    )
                }
                .padding(.horizontal, .big)
            }
        }
    }
}
