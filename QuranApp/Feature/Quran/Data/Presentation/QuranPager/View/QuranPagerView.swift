//
//  QuranPagerView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-26.
//

import SwiftUI
import Core

struct QuranPagerView: View {
    @StateObject private var viewModel: QuranViewModel
    @ObservedObject private var audio = AudioEngine.shared
    @ObservedObject private var storage = StorageManager.shared
    @Environment(\.colorScheme) var colorScheme

    let onBack: (() -> Void)?
    @State private var isTodaySheetPresenting = false
    @State private var isSurahListPresenting = false
    @State private var isPageSettingsPresenting = false
    @State private var isSearchPresenting = false
    @State private var overlayHideTask: Task<Void, Never>? = nil

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
        .fullScreenCover(isPresented: $isSearchPresenting) {
            QuranSearchView(onSelect: { surah, verse in
                viewModel.goToVerse(surah: surah, verse: verse)
                isSearchPresenting = false
            })
        }
        .onChange(of: viewModel.showOverlay) { _, showing in
            audio.quranOverlayActive = showing
            if showing {
                scheduleOverlayHide()
            } else {
                cancelOverlayHide()
            }
        }
        .onChange(of: audio.isPlaying) { _, playing in
            if playing, viewModel.showOverlay {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.showOverlay = false
                }
            }
        }
        .onChange(of: audio.currentVerseNumber) { _, _ in
            viewModel.goToVerse(surah: audio.currentSurahNumber, verse: audio.currentVerseNumber)
        }
        .onAppear {
            audio.isQuranScreenActive = true
        }
        .onDisappear {
            audio.quranOverlayActive = false
            audio.isQuranScreenActive = false
        }
    }

    private var backgroundColor: Color {
        switch mushafDisplayType {
        case .text, .tafsir: return Color.background
        case .mushaf: return Color.mushafPage
        }
    }

    private func scheduleOverlayHide() {
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
            QuranPageView(pageNumber: page, viewModel: viewModel)
        }
    }

    private var horizontalPager: some View {
        TabView(selection: $viewModel.currentPage) {
            ForEach(1...viewModel.totalPages, id: \.self) { page in
                pageContent(for: page)
                    .tag(page)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .horizontal)
        .onChange(of: viewModel.currentPage) { _, newPage in
            viewModel.updatePageInfo(page: newPage)
        }
    }

    private var verticalPager: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(1...viewModel.totalPages, id: \.self) { page in
                        pageContent(for: page)
                            .frame(height: UIScreen.main.bounds.height)
                            .id(page)
                            .background(pageVisibilityBackground(page: page))
                    }
                }
            }
            .ignoresSafeArea(edges: .horizontal)
            .onPreferenceChange(VisiblePageKey.self) { page in
                guard let page, viewModel.currentPage != page else { return }
                viewModel.updatePageInfo(page: page)
            }
            .onChange(of: viewModel.currentPage) { _, newPage in
                proxy.scrollTo(newPage, anchor: .top)
            }
        }
    }

    private func pageVisibilityBackground(page: Int) -> some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .global)
            let screenH = UIScreen.main.bounds.height
            Color.clear.preference(
                key: VisiblePageKey.self,
                value: (frame.midY >= 0 && frame.midY <= screenH) ? page : nil
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
            topBar
            Spacer()
            MiniPlayerView(onPlayTapped: {
                if audio.playSurahMode {
                    audio.playWholeSurah(surahNumber: viewModel.currentSurahNumber)
                } else {
                    audio.playFrom(
                        surahNumber: viewModel.currentSurahNumber,
                        verseNumber: viewModel.currentFirstVerseNumber
                    )
                }
            })
            .environmentObject(audio)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            bottomBar
        }
        .transition(.opacity)
        .simultaneousGesture(TapGesture().onEnded { scheduleOverlayHide() })
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
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

            Spacer()

            Button(action: { isSearchPresenting = true }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.playerControls)
            }

            Button(action: { isSurahListPresenting = true }) {
                Image(systemName: "list.bullet")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.playerControls)
                    .frame(width: 24, height: 24)
            }

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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(backgroundColor.opacity(0.95))
        .environment(\.layoutDirection, .leftToRight)
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
                let usableWidth = trackWidth - capsuleWidth
                let capsuleX = capsuleWidth / 2 + (progress * usableWidth)

                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                        .frame(height: 4)

                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.playerControls)
                            .frame(width: trackWidth * progress, height: 4)
                        Spacer(minLength: 0)
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
                            let flippedX = trackWidth - value.location.x
                            let ratio = flippedX / trackWidth
                            let page = viewModel.pageFromDragRatio(ratio)
                            viewModel.goToPage(page)
                        }
                )
            }
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
        .padding(.vertical, 10)
        .background(backgroundColor.opacity(0.95))
        .overlay(
            Rectangle()
                .fill(Color.playerControls.opacity(0.15))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
