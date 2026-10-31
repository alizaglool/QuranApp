//
//  AthkarReaderView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarReaderView: View {

    @StateObject private var viewModel: AthkarReaderViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var scrollPositionID: Int?

    init(coordinator: AdhkarCoordinating, pack: AthkarPack, items: [AthkarItem]) {
        _viewModel = StateObject(
            wrappedValue: AthkarReaderViewModel(coordinator: coordinator, pack: pack, items: items)
        )
    }

    private var isRightToLeft: Bool {
        localizationManager.currentLanguage == .Arabic
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            ZStack(alignment: .bottom) {
                Color.background.ignoresSafeArea()
                ambientGlowBackground

                VStack(spacing: 0) {
                    navigationBar

                    progressBar

                    progressLine

                    if viewModel.isFinished {
                        completionView
                    } else {
                        readerContent
                    }
                }

                if !viewModel.isFinished {
                    bottomPanel
                }

                if viewModel.hasToast {
                    toastView
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.isShowingSettings) {
            AthkarReaderSettingsSheet(viewModel: viewModel)
                .environmentObject(localizationManager)
                .environment(\.layoutDirection, localizationManager.currentLanguage.direction)
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - Navigation bar

private extension AthkarReaderView {

    var navigationBar: some View {
        HStack(spacing: .xSm) {
            Button(action: viewModel.close) {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 17, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)

            Text(viewModel.screenTitle)
                .customStyle(.adhkar(size: 22, bold: true), .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            Button(action: viewModel.openSettings) {
                Image(systemName: "textformat.size")
                    .font(.system(size: 18, weight: .regular))
                    .customForeground(.onSurfaceVariant)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .xSm)
        .padding(.top, .xSm)
    }

    var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.2))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [ColorStyle.primary.color, ColorStyle.secondary.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * viewModel.overallProgress)
                    .animation(.easeInOut(duration: 0.25), value: viewModel.overallProgress)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, .big)
        .padding(.top, .xxSm)
    }

    var progressLine: some View {
        HStack(spacing: .xSm) {
            Text(viewModel.progressLabel)
                .customStyle(.caption2, .onSurfaceVariant)

            Spacer(minLength: .xSm)

            Text(viewModel.positionLabel)
                .customStyle(.caption2, .outline)
                .monospacedDigit()
        }
        .padding(.horizontal, .big)
        .padding(.top, .xSm)
    }
}

// MARK: - Layout

private extension AthkarReaderView {

    @ViewBuilder
    var readerContent: some View {
        switch viewModel.layout {
        case .horizontal:
            pager

        case .vertical:
            verticalList
        }
    }
}

// MARK: - Pager

private extension AthkarReaderView {

    var pagerSelection: Binding<Int> {
        Binding(
            get: { viewModel.index },
            set: { viewModel.navigate(to: $0) }
        )
    }

    var pager: some View {
        TabView(selection: pagerSelection) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { offset, item in
                pageView(item)
                    .tag(offset)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    func pageView(_ page: AthkarReaderPage) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            AthkarReaderCard(
                page: page,
                icon: AthkarPackIcon.symbol(for: viewModel.pack.key),
                scale: viewModel.textScale,
                showsTranslation: viewModel.showsTranslation,
                meaningTitle: viewModel.meaningTitle,
                pronunciationTitle: viewModel.pronunciationTitle,
                sourceTitle: viewModel.sourceTitle,
                repetitionLabel: viewModel.repetitionLabel(forItemID: page.item.id),
                repetitionAccessibilityLabel: viewModel.repetitionAccessibilityLabel(forItemID: page.item.id)
            )
            .padding(.horizontal, .md)
            .padding(.top, .xBig)
            .padding(.bottom, 170)
        }
        .scrollBounceBehavior(.basedOnSize)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.count() }
    }
}

// MARK: - Vertical list

private extension AthkarReaderView {

    var verticalList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: .md) {
                ForEach(viewModel.pages) { page in
                    listCard(page)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, .md)
            .padding(.top, .big)
            .padding(.bottom, 170)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollPosition(id: $scrollPositionID, anchor: .top)
        .onAppear { scrollPositionID = viewModel.focusedItemID }
        .onChange(of: scrollPositionID) { _, newValue in
            guard let newValue else { return }
            viewModel.focus(onItemID: newValue)
        }
        .onChange(of: viewModel.scrollTarget) { _, newValue in
            guard let newValue, scrollPositionID != newValue else { return }
            withAnimation(.easeInOut(duration: 0.3)) { scrollPositionID = newValue }
        }
    }

    func listCard(_ page: AthkarReaderPage) -> some View {
        AthkarReaderCard(
            page: page,
            icon: AthkarPackIcon.symbol(for: viewModel.pack.key),
            scale: viewModel.textScale,
            showsTranslation: viewModel.showsTranslation,
            meaningTitle: viewModel.meaningTitle,
            pronunciationTitle: viewModel.pronunciationTitle,
            sourceTitle: viewModel.sourceTitle,
            repetitionLabel: viewModel.repetitionLabel(forItemID: page.item.id),
            repetitionAccessibilityLabel: viewModel.repetitionAccessibilityLabel(forItemID: page.item.id)
        )
        .overlay(playingHighlight(isActive: viewModel.playingItemID == page.item.id))
        .contentShape(Rectangle())
        .onTapGesture { viewModel.count(itemID: page.item.id) }
    }

    func playingHighlight(isActive: Bool) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(ColorStyle.primary.color.opacity(isActive ? 0.55 : 0), lineWidth: 1.5)
            .animation(.easeInOut(duration: 0.25), value: isActive)
            .allowsHitTesting(false)
    }
}

// MARK: - Bottom panel

private extension AthkarReaderView {

    var bottomPanel: some View {
        VStack(spacing: .xSm) {
            Text(viewModel.hintLabel)
                .customStyle(.caption2, .outline)
                .frame(maxWidth: .infinity, alignment: isRightToLeft ? .trailing : .leading)
                .padding(.horizontal, .xSm)

            AthkarReaderControls(
                ringValue: viewModel.ringValue,
                ringProgress: viewModel.ringProgress,
                isFavorite: viewModel.isFavorite,
                isPlaying: viewModel.isPlaying,
                hasAudio: viewModel.hasAudio,
                shareText: viewModel.shareText,
                onFavorite: viewModel.toggleFavorite,
                onCopy: viewModel.copyCurrent,
                onCount: viewModel.count,
                onAudio: viewModel.toggleAudio
            )
        }
        .padding(.horizontal, .big)
        .padding(.top, .xxBig)
        .background(bottomPanelScrim)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    var bottomPanelScrim: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.background.opacity(0), Color.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: .xxBig)

            Color.background
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .allowsHitTesting(false)
    }

    var toastView: some View {
        Text(viewModel.toast)
            .customStyle(.caption1, .onPrimary)
            .padding(.horizontal, .md)
            .padding(.vertical, .xSm)
            .background(Capsule().fill(ColorStyle.primary.color.opacity(0.92)))
            .padding(.bottom, 150)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: viewModel.toast)
    }
}

// MARK: - Completion

private extension AthkarReaderView {

    var completionView: some View {
        VStack(spacing: .big) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ColorStyle.secondary.color.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 18)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64, weight: .regular))
                    .customForeground(.secondary)
            }

            Text(viewModel.completedTitle)
                .customStyle(.heading2, .onSurface)
                .multilineTextAlignment(.center)

            Text(viewModel.completedMessage)
                .customStyle(.bodyMedium, .onSurfaceVariant)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: viewModel.restart) {
                Text(viewModel.readAgainTitle)
                    .customStyle(.buttonText, .onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .md)
                    .background(
                        RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                            .fill(ColorStyle.primary.color)
                    )
            }
            .buttonStyle(.plain)

            Button(action: viewModel.close) {
                Text(viewModel.backTitle)
                    .customStyle(.buttonText, .onSurface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .md)
                    .background(
                        RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                            .fill(Color.surfaceContainerLow)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .big)
        .padding(.bottom, 40)
    }

    var ambientGlowBackground: some View {
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
