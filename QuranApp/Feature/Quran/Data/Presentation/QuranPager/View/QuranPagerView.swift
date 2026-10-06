//
//  QuranPagerView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-26.
//

import SwiftUI
import Core
import UIKit

struct QuranPagerView: View {
    @StateObject private var viewModel: QuranViewModel
    @ObservedObject private var storage = StorageManager.shared

    let onBack: (() -> Void)?
    @State private var isTodaySheetPresenting = false
    @State private var isSurahListPresenting = false
    @State private var isPageSettingsPresenting = false
    @State private var isSearchActive = false
    @FocusState private var isSearchFieldFocused: Bool
    @State private var overlayHideTask: Task<Void, Never>? = nil
    @State private var isMiniPlayerSheetOpen = false

    @State private var playingVerse: PlayingVerse?

    private static let overlayAutoHideDelay: TimeInterval = 4

    private var hijriDay: Int {
        Calendar(identifier: .islamicUmmAlQura).component(.day, from: Date())
    }

    private var scrollDirection: ScrollDirection {
        storage.getSettings()?.scrollDirection ?? .horizontal
    }

    private var mushafDisplayType: MushafType {
        storage.getSettings()?.mushafDisplayType ?? .mushaf
    }

    // The mushaf line art is 1440x232px; 15 lines make a 1440x3480 page, so a
    // page's true aspect is 1 : 2.4167. Measured across pages 2/50/300/537/604,
    // glyph ink fills at most 66.8% of each PNG's height, so a page tolerates
    // being squeezed to 74% of its true height before lines start to touch.
    // Anything shorter scrolls instead of compressing.
    private static let mushafPageAspect: CGFloat = 3480.0 / 1440.0
    private static let minPageHeightRatio: CGFloat = 0.74

    private func pageHeight(for size: CGSize) -> CGFloat {
        max(size.height, size.width * Self.mushafPageAspect * Self.minPageHeightRatio)
    }

    init(startPage: Int? = nil, onBack: (() -> Void)? = nil) {
        let vm = QuranViewModel(startPage: startPage)
        _viewModel = StateObject(wrappedValue: vm)
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            if scrollDirection == .vertical {
                verticalPager
            } else {
                horizontalPager
            }

            if viewModel.showOverlay {
                overlayContent
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: !viewModel.showOverlay)
        .ignoresSafeArea(edges: .horizontal)
        .customSheet(isPresented: $viewModel.showVerseActionSheet, fraction: 1.0, detents: [.large]) {
            VerseActionSheet(
                verseID: viewModel.selectedVerseID ?? 0,
                page: viewModel.selectedPage ?? viewModel.currentPage,
                surahNumber: viewModel.selectedVerseSurahNumber,
                surahName: viewModel.selectedVerseSurahName,
                verseNumber: viewModel.selectedVerseNumber
            )
            .presentationDragIndicator(.visible)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeOut(duration: 0.18)) {
                        viewModel.clearTemporaryHighlight()
                    }
                }
            }
        }
        .onChange(of: viewModel.showVerseActionSheet) { _, isShowing in
            if !isShowing { viewModel.clearSelection() }
        }
        .customSheet(isPresented: $isTodaySheetPresenting, fraction: 1.0, detents: [.large]) {
            TodayView()
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isSurahListPresenting) {
            SurahListSheet(
                currentSurahNumber: viewModel.currentSurahNumber,
                currentPage: viewModel.currentPage,
                onSelectSurah: { surahID in
                    withAnimation { viewModel.goToSurah(surahID) }
                },
                onSelectPage: { page in
                    withAnimation { viewModel.goToPage(page) }
                }
            )
        }
        .customSheet(isPresented: $isPageSettingsPresenting, detents: [.medium, .large]) {
            QuranPageSettingsSheet()
                .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.showOverlay) { _, showing in
            AudioEngine.shared.quranOverlayActive = showing
            if showing {
                scheduleOverlayHide()
            } else {
                cancelOverlayHide()
            }
        }
        .onChange(of: isMiniPlayerSheetOpen) { _, isOpen in
            if isOpen {
                cancelOverlayHide()
            } else {
                scheduleOverlayHide()
            }
        }
        .onReceive(AudioEngine.shared.$isPlaying.dropFirst()) { playing in
            if playing, viewModel.showOverlay, !isMiniPlayerSheetOpen {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.showOverlay = false
                }
            }
        }
        // `@Published` emits from `willSet`, so `AudioEngine.shared.currentVerseNumber`
        // still holds the PREVIOUS verse inside this closure. Use the emitted value.
        // `currentSurahNumber` is safe to read: every write site assigns the surah
        // before the verse, so it has already settled by the time this fires.
        .onReceive(AudioEngine.shared.$currentVerseNumber.dropFirst()) { verse in
            viewModel.goToVerse(
                surah: AudioEngine.shared.currentSurahNumber,
                verse: verse
            )
        }
        .onReceive(AudioEngine.shared.$isPlaying) { _ in refreshPlayingVerse() }
        .onReceive(AudioEngine.shared.$isLoadingVerse) { _ in refreshPlayingVerse() }
        .onReceive(AudioEngine.shared.$currentSurahNumber) { _ in refreshPlayingVerse() }
        .onReceive(AudioEngine.shared.$currentVerseNumber) { verse in refreshPlayingVerse(verse: verse) }
        .onAppear {
            AudioEngine.shared.isQuranScreenActive = true
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            AudioEngine.shared.quranOverlayActive = false
            AudioEngine.shared.isQuranScreenActive = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var backgroundColor: Color {
        switch mushafDisplayType {
        case .tafsir: return Color.background
        case .text, .mushaf: return Color.mushafPage
        }
    }

    private func scheduleOverlayHide() {
        // Inline search lives INSIDE the auto-hiding overlay, so the timer would
        // delete the search field out from under the user mid-typing.
        guard !isSearchActive else { return }
        guard !isMiniPlayerSheetOpen else { return }
        overlayHideTask?.cancel()
        overlayHideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(Self.overlayAutoHideDelay))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.showOverlay = false
            }
        }
    }

    private func cancelOverlayHide() {
        overlayHideTask?.cancel()
        overlayHideTask = nil
    }

    /// Recomputes the playing verse; assigns only on a real change so the
    /// pager body is not invalidated by repeated identical values.
    ///
    /// `verse` carries the value `$currentVerseNumber` just emitted: `@Published`
    /// emits from `willSet`, so the stored property is still one verse behind inside
    /// that subscription and must not be read there.
    ///
    /// The other three subscriptions pass nothing and read the engine directly. That
    /// is safe because every write site assigns `currentSurahNumber` before
    /// `currentVerseNumber` (beginPlayback, promoteScheduledHandoffIfReady,
    /// loadSavedProgress), so the pair is never observed
    /// half-updated from the surah side.
    private func refreshPlayingVerse(verse: Int? = nil) {
        let engine = AudioEngine.shared
        let resolved: PlayingVerse? = (engine.isPlaying || engine.isLoadingVerse)
            ? PlayingVerse(surahNumber: engine.currentSurahNumber,
                           verseNumber: verse ?? engine.currentVerseNumber)
            : nil
        if playingVerse != resolved { playingVerse = resolved }
    }
}

// MARK: - Pagers

extension QuranPagerView {

    @ViewBuilder
    private func pageContent(for page: Int) -> some View {
        switch mushafDisplayType {
        case .text:
            QuranTextPageView(pageNumber: page, viewModel: viewModel)
        case .tafsir:
            QuranTafsirPageView(pageNumber: page, viewModel: viewModel)
        case .mushaf:
            QuranPageView(pageNumber: page, viewModel: viewModel, playingVerse: playingVerse)
        }
    }

    private var horizontalPager: some View {
        GeometryReader { geo in
            let height = pageHeight(for: geo.size)
            TabView(selection: $viewModel.currentPage) {
                ForEach(1...viewModel.totalPages, id: \.self) { page in
                    scrollingPage(for: page, viewport: geo.size.height, pageHeight: height)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: viewModel.currentPage) { _, newPage in
                viewModel.updatePageInfo(page: newPage)
            }
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    // A page that fits is rendered bare — no ScrollView, no nested gesture
    // recognizer — so portrait behaviour is unchanged. Only a page too tall for
    // the viewport gets one.
    @ViewBuilder
    private func scrollingPage(for page: Int, viewport: CGFloat, pageHeight: CGFloat) -> some View {
        if pageHeight > viewport {
            ScrollView(.vertical, showsIndicators: false) {
                pageContent(for: page)
                    .frame(height: pageHeight)
            }
        } else {
            pageContent(for: page)
        }
    }

    private var verticalPager: some View {
        GeometryReader { geo in
            let height = pageHeight(for: geo.size)
            let viewport = geo.frame(in: .global)
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(1...viewModel.totalPages, id: \.self) { page in
                            pageContent(for: page)
                                .frame(height: height)
                                .id(page)
                                .background(pageVisibilityBackground(page: page, viewport: viewport))
                        }
                    }
                }
                .onPreferenceChange(VisiblePageKey.self) { page in
                    guard let page, viewModel.currentPage != page else { return }
                    viewModel.updatePageInfo(page: page)
                }
                .onChange(of: viewModel.currentPage) { _, newPage in
                    proxy.scrollTo(newPage, anchor: .top)
                }
            }
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    private func pageVisibilityBackground(page: Int, viewport: CGRect) -> some View {
        GeometryReader { geo in
            let midY = geo.frame(in: .global).midY
            Color.clear.preference(
                key: VisiblePageKey.self,
                value: (midY >= viewport.minY && midY <= viewport.maxY) ? page : nil
            )
        }
    }
}

private struct VisiblePageKey: PreferenceKey {
    static var defaultValue: Int? = nil
    static func reduce(value: inout Int?, nextValue: () -> Int?) {
        value = value ?? nextValue()
    }
}

// MARK: - Overlay

extension QuranPagerView {

    private var overlayContent: some View {
        VStack(spacing: 0) {
            if isSearchActive {
                searchPanel
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                topBar
                    .transition(.opacity.combined(with: .move(edge: .top)))
                Spacer()
                MiniPlayerView(
                    onPlayTapped: {
                        if AudioEngine.shared.playSurahMode {
                            AudioEngine.shared.playWholeSurah(surahNumber: viewModel.currentSurahNumber)
                        } else {
                            AudioEngine.shared.playFrom(
                                surahNumber: viewModel.currentSurahNumber,
                                verseNumber: viewModel.currentFirstVerseNumber
                            )
                        }
                    },
                    onSheetOpenChanged: { open in
                        isMiniPlayerSheetOpen = open
                    }
                )
                .environmentObject(AudioEngine.shared)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                bottomBar
            }
        }
        .transition(.opacity)
        .simultaneousGesture(TapGesture().onEnded { scheduleOverlayHide() })
        .appDirection()
    }

    private var searchPanel: some View {
        QuranSearchView(
            isFieldFocused: $isSearchFieldFocused,
            barBackground: backgroundColor,
            onSelect: { surah, verse in
                viewModel.clearSelection()
                viewModel.goToVerse(surah: surah, verse: verse)
                closeSearch()
            },
            onCancel: { closeSearch() }
        )
    }

    private func openSearch() {
        cancelOverlayHide()
        withAnimation(.easeInOut(duration: 0.22)) { isSearchActive = true }
        isSearchFieldFocused = true
    }

    private func closeSearch() {
        isSearchFieldFocused = false
        withAnimation(.easeInOut(duration: 0.22)) { isSearchActive = false }
        scheduleOverlayHide()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
            
            if let onBack {
                Button(action: { onBack() }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.playerControls)
                }
            } else {
                Button(action: { isPageSettingsPresenting = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20))
                        .foregroundColor(Color.playerControls)
                }
            }

            Button(action: { isSurahListPresenting = true }) {
                Image(systemName: "list.bullet")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.playerControls)
                    .frame(width: 24, height: 24)
            }

            Spacer()
            
            Button(action: { openSearch() }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.playerControls)
            }
            .accessibilityLabel(AppLocalizedKeys.searchQuran.value)
            
            Button(action: { isTodaySheetPresenting = true }) {
                ZStack {
                    Image("todayButton")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(Color.playerControls)
                        .frame(width: 28, height: 28)

                    Text(hijriDay.arabicNumerals)
                        .customStyle(.kitab(size: 14, bold: true))
                        .foregroundColor(Color.playerControls)
                        .offset(y: 3)
                }
            }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .safeAreaPadding(.horizontal)
        // Mushaf reading order, not app language: back + menu hug the right edge,
        // search + today hug the left, in ar and en alike.
        .environment(\.layoutDirection, .rightToLeft)
        .background(backgroundColor.opacity(0.95))
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation { viewModel.swapLastVisitedPage() }
            }) {
                HStack(spacing: 2) {
                    Image("arrowUTurnBackward")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(Color.playerControls)

                    Text("\(viewModel.lastVisitedPage)")
                        .customStyle(.kitab(size: 11, bold: true), .primary)
                }
            }
            .frame(width: 54)

            GeometryReader { geo in
                let progress = viewModel.progressRatio
                let trackWidth = geo.size.width
                let capsuleWidth: CGFloat = 50
                let usableWidth = max(trackWidth - capsuleWidth, 1)
                // Mushaf order: page 1 at the right edge, page 604 at the left.
                // Expressed in raw left-origin coordinates and pinned LTR below,
                // so the track reads right-to-left in ar and en alike.
                let capsuleX = trackWidth - (capsuleWidth / 2 + progress * usableWidth)

                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                        .frame(height: 4)

                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.playerControls)
                            .frame(width: trackWidth * progress, height: 4)
                    }

                    Text("\(viewModel.currentPage)")
                        .customStyle(.kitab(size: 15, bold: true))
                        .foregroundColor(.white)
                        .frame(minWidth: 30)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.playerControls))
                        .position(x: capsuleX, y: geo.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let x = min(max(value.location.x, capsuleWidth / 2),
                                        trackWidth - capsuleWidth / 2)
                            let ratio = (trackWidth - capsuleWidth / 2 - x) / usableWidth
                            viewModel.goToPage(viewModel.pageFromDragRatio(ratio))
                        }
                )
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(height: 30)
            .padding(.horizontal, 8)

            Button(action: { isPageSettingsPresenting = true }) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 20))
                    .foregroundColor(Color.playerControls)
            }
            .frame(width: 54)
        }
        .padding(.horizontal, 12)
        .safeAreaPadding(.horizontal)
        .padding(.vertical, 10)
        // Same mushaf order as topBar: last-visited on the right, settings on the
        // left. The scrubber's own GeometryReader re-pins itself .leftToRight below
        // and is unaffected.
        .environment(\.layoutDirection, .rightToLeft)
        .background(backgroundColor.opacity(0.95))
        .overlay(
            Rectangle()
                .fill(Color.playerControls.opacity(0.15))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
