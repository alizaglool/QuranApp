//
//  QuranPageView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-26.
//

import SwiftUI
import UIKit
import CoreGraphics
import CoreText
import Core

// MARK: - QuranGlyphRenderer

final class QuranGlyphRenderer {

    private static let hafsFontName = "KFGQPCHafsSmart-Regular"
    private static let verseBaseCodePoint = 0xE95A

    // Images are 120×160 (portrait oval). Height drives sizing; width = height * 0.75.
    static func drawVerseNumber(
        _ verseNumber: Int,
        centeredAt point: CGPoint,
        lineHeight: CGFloat,
        isDarkMode: Bool,
        theme: Theme,
        in context: CGContext
    ) {
        guard verseNumber >= 1, verseNumber <= 286 else { return }

        // 1 ─ Custom ornament image (replaces cream circle)
        let markerH = lineHeight * 0.65
        let markerW = markerH * 0.75
        let markerRect = CGRect(
            x: point.x - markerW / 2,
            y: point.y - markerH / 2,
            width: markerW,
            height: markerH
        )
        let imageName = isDarkMode ? "newDarkVerseMarker"
            : (theme == .tinted ? "newTintedVerseMarker" : "newClassicVerseMarker")
        if let img = UIImage(named: imageName) {
            UIGraphicsPushContext(context)
            img.draw(in: markerRect)
            UIGraphicsPopContext()
        }

        // 2 ─ Original glyph (KFGQPCHafsSmart ornament + number in one character)
        let fontSize = lineHeight * 0.65
        guard let font = UIFont(name: hafsFontName, size: fontSize) else { return }
        let codePoint = verseBaseCodePoint + (verseNumber - 1)
        guard let scalar = Unicode.Scalar(codePoint) else { return }
        let text = String(scalar)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: glyphColor(isDarkMode: isDarkMode)
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let drawPoint = CGPoint(x: point.x - size.width / 2,
                                y: point.y - size.height / 2)
        UIGraphicsPushContext(context)
        (text as NSString).draw(at: drawPoint, withAttributes: attributes)
        UIGraphicsPopContext()
    }

    private static func glyphColor(isDarkMode: Bool) -> UIColor {
        isDarkMode ? UIColor.white.withAlphaComponent(0.6) : UIColor(Color.verseMarkerGold)
    }

    /// Returns a standalone UIImage of the verse-number badge.
    /// Use this in flow-layout views (e.g. QuranTextPageView) where a CGContext
    /// position is not available.
    static func verseMarkerImage(
        _ verseNumber: Int,
        lineHeight: CGFloat,
        isDarkMode: Bool,
        theme: Theme
    ) -> UIImage {
        let markerH = lineHeight * 0.65
        let markerW = markerH * 0.75
        let size    = CGSize(width: markerW, height: markerH)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            drawVerseNumber(
                verseNumber,
                centeredAt: CGPoint(x: size.width / 2, y: size.height / 2),
                lineHeight: lineHeight,
                isDarkMode: isDarkMode,
                theme: theme,
                in: ctx.cgContext
            )
        }
    }
}

// MARK: - QuranPageOverlayView

final class QuranPageOverlayView: UIView {
    
    var verseMarkers: [VersePosition] = []
    var isDarkMode: Bool = false
    var theme: Theme = .classic

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let pageWidth = bounds.width
        let lineHeight = bounds.height / 15.0

        for verse in verseMarkers {
            let x = CGFloat(verse.markerCenterX) * pageWidth
            let y = CGFloat(verse.markerLine) * lineHeight + CGFloat(verse.markerCenterY) * lineHeight

            QuranGlyphRenderer.drawVerseNumber(
                verse.number,
                centeredAt: CGPoint(x: x, y: y),
                lineHeight: lineHeight,
                isDarkMode: isDarkMode,
                theme: theme,
                in: ctx
            )
        }
    }
}

// MARK: - QuranPageOverlay (SwiftUI Wrapper)

struct QuranPageOverlay: UIViewRepresentable {
    let verseMarkers: [VersePosition]
    let isDarkMode: Bool
    let theme: Theme

    func makeUIView(context: Context) -> QuranPageOverlayView {
        QuranPageOverlayView()
    }

    func updateUIView(_ view: QuranPageOverlayView, context: Context) {
        view.verseMarkers = verseMarkers
        view.isDarkMode = isDarkMode
        view.theme = theme
        view.setNeedsDisplay()
    }
}

// MARK: - QuranPageView

struct QuranPageView: View {
    let pageNumber: Int
    @ObservedObject var viewModel: QuranViewModel
    @Environment(\.colorScheme) var colorScheme

    /// Observed so the page redraws bookmark badges whenever any bookmark
    /// is added, removed, or recolored from anywhere in the app.
    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var audio = AudioEngine.shared

    private let quranDB = QuranDatabase.shared

    private var isDarkMode: Bool { colorScheme == .dark }
    private var textColor: Color { isDarkMode ? .white : .black }

    /// One bookmarked verse on this page, with everything we need to render
    /// its tinted highlight (per-line rects) and end-of-verse bookmark icon.
    private struct BookmarkRender {
        let verseID: Int
        let color: Color
        let highlights: [VerseHighlightRect]
    }

    /// Highlight rects for the currently playing verse on this page.
    private var playingHighlightRects: [VerseHighlightRect] {
        guard audio.isPlaying || audio.isLoadingVerse else { return [] }
        let allHighlights = quranDB.getAllHighlightsForPage(pageNumber)
        let verses = quranDB.getVersesForPage(pageNumber)
        guard let playingVerse = verses.first(where: {
            $0.chapterNumber == audio.currentSurahNumber && $0.number == audio.currentVerseNumber
        }) else { return [] }
        return allHighlights.filter { $0.verseID == playingVerse.verseID }
    }

    /// All bookmarks on this page joined with their verse positions and
    /// per-line highlight rectangles from the positioning DB.
    private var bookmarkRenders: [BookmarkRender] {
        // Reading bookmarksRevision creates a dependency on @Published changes
        // — the page redraws when bookmarks are added/removed/recolored.
        _ = storage.bookmarksRevision
        let bookmarks = storage.getBookmarks(forPage: pageNumber)
        guard !bookmarks.isEmpty else { return [] }

        let allVerses = quranDB.getVersesForPage(pageNumber)
        let allHighlights = quranDB.getAllHighlightsForPage(pageNumber)

        return bookmarks.compactMap { bm -> BookmarkRender? in
            guard let ayah = bm.ayahNumber else { return nil }
            guard let verse = allVerses.first(where: {
                $0.chapterNumber == bm.surahNumber && $0.number == ayah
            }) else { return nil }

            let lines = allHighlights.filter { $0.verseID == verse.verseID }
            return BookmarkRender(
                verseID: verse.verseID,
                color: color(for: bm.color),
                highlights: lines
            )
        }
    }

    private func color(for storageKey: String?) -> Color {
        switch storageKey {
        case BookmarkColor.yellow.rawValue: return .yellow
        case BookmarkColor.green.rawValue:  return .green
        case BookmarkColor.blue.rawValue:   return .blue
        default:                            return .red
        }
    }

    // MARK: - Page Info helpers

    private var pageSurahName: String {
        let surahNumber = quranDB.getSurahsForPage(pageNumber).first?.id
            ?? quranDB.getVersesForPage(pageNumber).first?.chapterNumber
        guard let number = surahNumber else { return "" }
        return ReciterLibrary.surahArabicNames[number] ?? ""
    }

    private var firstVerseNumber: Int {
        quranDB.getVersesForPage(pageNumber)
            .min(by: { $0.markerLine < $1.markerLine })?.number ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            QuranPageHeaderBar(surahName: pageSurahName, firstVerse: firstVerseNumber, textColor: textColor)
                .padding(.top, 8)
                .padding(.bottom, 4)

            GeometryReader { geo in
                let lineHeight = geo.size.height / 15.0
                let pageWidth = geo.size.width
                let pageHeight = geo.size.height

                ZStack {
                    surahHeaders(pageWidth: pageWidth, lineHeight: lineHeight)

                    bookmarkHighlights(pageWidth: pageWidth, lineHeight: lineHeight)

                    playingVerseHighlight(pageWidth: pageWidth, lineHeight: lineHeight)

                    lineImages(pageWidth: pageWidth, lineHeight: lineHeight)

                    if viewModel.selectedPage == pageNumber {
                        ForEach(viewModel.highlightRects, id: \.line) { rect in
                            highlightRect(
                                rect: rect,
                                pageWidth: pageWidth,
                                lineHeight: lineHeight
                            )
                        }
                    }

                    verseMarkers(pageWidth: pageWidth, pageHeight: pageHeight)
                }
                .contentShape(Rectangle())
                .overlay {
                    LongPressLocationView(
                        minimumPressDuration: 0.4,
                        onLongPress: { location in
                            let line = Int(location.y / lineHeight)
                            let normalizedX = location.x / pageWidth

                            viewModel.selectVerse(
                                atLine: line,
                                normalizedX: normalizedX,
                                pageNumber: pageNumber
                            )
                        },
                        onTap: {
                            let hasVisibleHighlight = !viewModel.highlightRects.isEmpty
                                                   && viewModel.selectedPage == pageNumber
                            if hasVisibleHighlight {
                                viewModel.clearSelection()
                            } else {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    viewModel.toggleOverlay()
                                }
                            }
                        }
                    )
                }
            }

            QuranPageFooterBar(
                pageNumber: pageNumber,
                isDarkMode: isDarkMode,
                theme: storage.getSettings()?.selectedTheme ?? .classic
            )
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    // MARK: - Surah Headers

    @ViewBuilder
    private func surahHeaders(pageWidth: CGFloat, lineHeight: CGFloat) -> some View {
        let headers = quranDB.getChapterHeaders(forPage: pageNumber)
        let isTinted = storage.getSettings()?.selectedTheme == .tinted
        let headerImage = isTinted ? "newClassicChapterHeader" : "tintedChapterHeader"

        ForEach(headers, id: \.chapterNumber) { header in
            let x = CGFloat(header.centerX) * pageWidth
            let y = CGFloat(header.line) * lineHeight + (CGFloat(header.centerY) * lineHeight)

            Image(headerImage)
                .resizable()
                .scaledToFit()
                .frame(width: pageWidth * 0.92, height: lineHeight * 1.2)
                .position(x: x, y: y)
        }
    }

    // MARK: - Lines

    private func lineImages(pageWidth: CGFloat, lineHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(1...15, id: \.self) { lineIndex in
                lineImage(lineIndex, width: pageWidth, height: lineHeight)
            }
        }
    }

    @ViewBuilder
    private func lineImage(_ lineIndex: Int, width: CGFloat, height: CGFloat) -> some View {
        if let uiImage = loadLineImage(page: pageNumber, line: lineIndex) {
            Image(uiImage: uiImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundColor(textColor)
                .frame(width: width, height: height)
        } else {
            Color.clear
                .frame(width: width, height: height)
        }
    }

    // MARK: - Verse Markers

    private func verseMarkers(pageWidth: CGFloat, pageHeight: CGFloat) -> some View {
        QuranPageOverlay(
            verseMarkers: quranDB.getVersesForPage(pageNumber),
            isDarkMode: isDarkMode,
            theme: storage.getSettings()?.selectedTheme ?? .classic
        )
        .frame(width: pageWidth, height: pageHeight)
    }

    // MARK: - Bookmark Highlights

    @ViewBuilder
    private func bookmarkHighlights(pageWidth: CGFloat, lineHeight: CGFloat) -> some View {
        ForEach(bookmarkRenders, id: \.verseID) { item in
            ForEach(item.highlights, id: \.line) { rect in
                let flippedLeft  = 1.0 - CGFloat(rect.rightVal)
                let flippedRight = 1.0 - CGFloat(rect.leftVal)
                let x = flippedLeft * pageWidth
                let width = (flippedRight - flippedLeft) * pageWidth
                let y = CGFloat(rect.line) * lineHeight

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(item.color.opacity(0.22))
                    .frame(width: width, height: lineHeight)
                    .position(x: x + width / 2, y: y + lineHeight / 2)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Playing Verse Highlight

    @ViewBuilder
    private func playingVerseHighlight(pageWidth: CGFloat, lineHeight: CGFloat) -> some View {
        ForEach(playingHighlightRects, id: \.line) { rect in
            let flippedLeft  = 1.0 - CGFloat(rect.rightVal)
            let flippedRight = 1.0 - CGFloat(rect.leftVal)
            let x = flippedLeft * pageWidth
            let width = (flippedRight - flippedLeft) * pageWidth
            let y = CGFloat(rect.line) * lineHeight
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(ColorStyle.primary.color.opacity(0.25))
                .frame(width: width, height: lineHeight)
                .position(x: x + width / 2, y: y + lineHeight / 2)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Highlight

    @ViewBuilder
    private func highlightRect(rect: VerseHighlightRect, pageWidth: CGFloat, lineHeight: CGFloat) -> some View {
        let flippedLeft = 1.0 - CGFloat(rect.rightVal)
        let flippedRight = 1.0 - CGFloat(rect.leftVal)

        let x = flippedLeft * pageWidth
        let width = (flippedRight - flippedLeft) * pageWidth
        let y = CGFloat(rect.line) * lineHeight

        Rectangle()
            .fill(ColorStyle.primary.color.opacity(0.15))
            .frame(width: width, height: lineHeight)
            .position(x: x + width / 2, y: y + lineHeight / 2)
    }

    // MARK: - Image Loading

    private func loadLineImage(page: Int, line: Int) -> UIImage? {
        if let resourcePath = Bundle.main.resourcePath {
            let path = "\(resourcePath)/\(page)/\(line).png"
            if let image = UIImage(contentsOfFile: path) {
                return image
            }
        }
        if let path = Bundle.main.path(forResource: "\(line)", ofType: "png", inDirectory: "\(page)") {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
}

// MARK: - Ornamental Page Number Badge

struct OrnamentalPageBadge: View {
    let text: String
    let isDarkMode: Bool
    let theme: Theme

    private var markerImageName: String {
        theme == .tinted ? "newTintedPageMarker" : "newClassicPageMarker"
    }

    private var labelColor: Color {
        isDarkMode
            ? Color.white.opacity(0.70)
            : Color(red: 0.18, green: 0.13, blue: 0.08)
    }

    var body: some View {
        ZStack {
            Image(markerImageName)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 26)

            Text(text)
                .customStyle(.kitab(size: 12))
                .foregroundColor(labelColor)
        }
        .frame(width: 44, height: 26)
        .padding(.horizontal, 12)
    }
}
