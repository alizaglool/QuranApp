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
    @Environment(\.colorScheme) var colorScheme

    let onBack: (() -> Void)?
    @State private var showTodaySheet = false

    private var hijriDay: Int {
        Calendar(identifier: .islamicUmmAlQura).component(.day, from: Date())
    }

    init(startPage: Int? = nil, onBack: (() -> Void)? = nil) {
        let vm = QuranViewModel(startPage: startPage)
        _viewModel = StateObject(wrappedValue: vm)
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            TabView(selection: $viewModel.currentPage) {
                ForEach(1...viewModel.totalPages, id: \.self) { page in
                    QuranPageView(pageNumber: page, viewModel: viewModel)
                        .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .horizontal)
            .onChange(of: viewModel.currentPage) { _, newPage in
                viewModel.updatePageInfo(page: newPage)
            }

            if viewModel.showOverlay {
                overlayContent
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: !viewModel.showOverlay)
        .ignoresSafeArea(edges: .horizontal)
        .sheet(isPresented: $viewModel.showVerseActionSheet) {
            VerseActionSheet(
                verseID: viewModel.selectedVerseID ?? 0,
                page: viewModel.selectedPage ?? viewModel.currentPage,
                surahNumber: viewModel.selectedVerseSurahNumber,
                surahName: viewModel.selectedVerseSurahName,
                verseNumber: viewModel.selectedVerseNumber
            )
            .presentationDetents([.large])
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
        .sheet(isPresented: $showTodaySheet) {
            TodayView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: viewModel.showOverlay) { _, showing in
            audio.quranOverlayActive = showing
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

    private var backgroundColor: Color { Color.mushafPage }
}

// MARK: - Overlay

extension QuranPagerView {

    private var overlayContent: some View {
        VStack(spacing: 0) {
            topBar
            Spacer()
            MiniPlayerView(onPlayTapped: {
                audio.play(
                    surahNumber: viewModel.currentSurahNumber,
                    verseNumber: viewModel.currentFirstVerseNumber
                )
            })
            .environmentObject(audio)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            bottomBar
        }
        .transition(.opacity)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
            // LEFT: calendar badge (always)
            Button(action: { showTodaySheet = true }) {
                ZStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 22, weight: .ultraLight))
                        .foregroundColor(Color.playerControls)
                        .frame(width: 32, height: 32)
                    
                    Text(hijriDay.arabicNumerals)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.playerControls)
                        .offset(y: 3)
                }
            }

            Spacer()

            // RIGHT: search
            Button(action: { /* TODO: search */ }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color.playerControls)
            }

            // RIGHT: surah list
            Button(action: { /* TODO: surah list */ }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color.playerControls)
            }

            // FAR RIGHT: back or settings
            if let onBack {
                Button(action: { onBack() }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.playerControls)
                }
            } else {
                Button(action: { /* TODO: settings */ }) {
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
            // Right: Swap to last visited page
            Button(action: {
                withAnimation {
                    viewModel.swapLastVisitedPage()
                }
            }) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 16))
                        .customForeground(.primary)
                    
                    Text("\(viewModel.lastVisitedPage)")
                        .font(.system(size: 11, weight: .bold))
                        .customForeground(.primary)
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
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 40)
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
            
            // Left: Surah list
            Button(action: { /* TODO: open surah list sheet */ }) {
                Image(systemName: "text.book.closed")
                    .font(.system(size: 20))
                    .customForeground(.primary)
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
