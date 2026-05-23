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
    @Environment(\.colorScheme) var colorScheme

    /// Optional dismiss handler. When provided (e.g. when the screen was
    /// pushed from Home), the top-bar chevron pops back to the previous
    /// screen. When nil (e.g. mounted as the root of the Quran tab) the
    /// chevron is hidden so we don't show a non-functional back button.
    let onBack: (() -> Void)?

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
            if !isShowing {
                viewModel.clearSelection()
            }
        }
    }
    
    private var backgroundColor: Color {
        Color.mushafPage
    }
}

// MARK: - Overlay

extension QuranPagerView {
    
    private var overlayContent: some View {
        VStack(spacing: 0) {
            topBar
            surahInfoBar
            Spacer()
            bottomBar
        }
        .transition(.opacity)
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack(spacing: 16) {
            if let onBack {
                Button(action: { onBack() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .customForeground(.primary)
                }
            }
            
            Button(action: { /* TODO: open today sheet */ }) {
                Text("١٤")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(ColorStyle.primary.color)
                    .cornerRadius(6)
            }
            
            Spacer()
            
            Button(action: { /* TODO: search */ }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.primary)
            }
            
            Button(action: { /* TODO: surah list */ }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 20, weight: .medium))
                    .customForeground(.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(backgroundColor.opacity(0.95))
    }
    
    // MARK: - Surah Info Bar
    
    private var surahInfoBar: some View {
        HStack {
            Text(viewModel.currentSurahName)
                .customStyle(.caption1, .onSurface)
            
            Spacer()
            
            Text("الجزء \(viewModel.currentJuz)")
                .customStyle(.caption1, .onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(backgroundColor.opacity(0.95))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
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
            
            // Center: Progress bar + page number (RTL)
            GeometryReader { geo in
                let progress = viewModel.progressRatio
                let trackWidth = geo.size.width
                let capsuleWidth: CGFloat = 50
                let usableWidth = trackWidth - capsuleWidth
                let capsuleX = capsuleWidth / 2 + (progress * usableWidth)
                
                ZStack {
                    // Track background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                        .frame(height: 4)
                    
                    // Track fill (from left, RTL environment will flip it)
                    HStack {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(ColorStyle.primary.color)
                            .frame(width: trackWidth * progress, height: 4)
                        Spacer(minLength: 0)
                    }
                    
                    // Page number capsule
                    Text("\(viewModel.currentPage)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 40)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(ColorStyle.primary.color)
                        )
                        .position(x: capsuleX, y: geo.size.height / 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Flip X because RTL environment mirrors touch coordinates
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
            .frame(width: 44)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            Rectangle()
                .fill(backgroundColor.opacity(0.95))
                .shadow(color: .black.opacity(0.05), radius: 4, y: -2)
        )
    }
}
