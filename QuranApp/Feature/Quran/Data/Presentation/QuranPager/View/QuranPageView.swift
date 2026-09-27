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

    // MARK: - Geometry

    static let verseMarkerHeightRatio: CGFloat = 0.58
    private static let ornamentAspectRatio: CGFloat = 0.75
    private static let numberSizeRatio: CGFloat = 0.95
    private static let numberCenter = CGPoint(x: 0.496, y: 0.516)

    // MARK: - Glyphs

    private static let numbersFontName = QuranFont.numbers.rawValue
    private static let numberBaseCodePoint = 0xE900

    private static let maxVerseNumber = 286

    private static let ornamentCache = NSCache<NSString, UIImage>()

    // MARK: - Drawing

    static func drawVerseNumber(
        _ verseNumber: Int,
        centeredAt point: CGPoint,
        lineHeight: CGFloat,
        isDarkMode: Bool,
        theme: Theme,
        in context: CGContext
    ) {
        let size = ornamentSize(lineHeight: lineHeight)
        let rect = CGRect(x: point.x - size.width / 2,
                          y: point.y - size.height / 2,
                          width: size.width,
                          height: size.height)

        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }
        drawBadge(verseNumber, in: rect, isDarkMode: isDarkMode, theme: theme)
    }

    static func verseMarkerImage(
        _ verseNumber: Int,
        lineHeight: CGFloat,
        isDarkMode: Bool,
        theme: Theme
    ) -> UIImage {
        guard verseNumber >= 1, verseNumber <= maxVerseNumber else { return UIImage() }

        let size = ornamentSize(lineHeight: lineHeight)
        guard size.width > 0, size.height > 0 else { return UIImage() }

        let badge = UIGraphicsImageRenderer(size: size).image { _ in
            drawBadge(verseNumber,
                      in: CGRect(origin: .zero, size: size),
                      isDarkMode: isDarkMode,
                      theme: theme)
        }
        // Both call sites embed this in a tinted `Text` chain; keep the
        // artwork's own colours instead of letting SwiftUI template it.
        return badge.withRenderingMode(.alwaysOriginal)
    }

    // MARK: - Shared Rendering

    private static func drawBadge(
        _ verseNumber: Int,
        in rect: CGRect,
        isDarkMode: Bool,
        theme: Theme
    ) {
        ornament(isDarkMode: isDarkMode, theme: theme)?.draw(in: rect)

        guard let text = numberText(for: verseNumber),
              let attributes = numberAttributes(ornamentHeight: rect.height,
                                                isDarkMode: isDarkMode)
        else { return }

        let advance = text.size(withAttributes: attributes)
        let centre = CGPoint(x: rect.minX + rect.width * numberCenter.x,
                             y: rect.minY + rect.height * numberCenter.y)
        text.draw(at: CGPoint(x: centre.x - advance.width / 2,
                              y: centre.y - advance.height / 2),
                  withAttributes: attributes)
    }

    private static func ornamentSize(lineHeight: CGFloat) -> CGSize {
        let height = lineHeight * verseMarkerHeightRatio
        return CGSize(width: height * ornamentAspectRatio, height: height)
    }

    // MARK: - Ornament

    private static func ornament(isDarkMode: Bool, theme: Theme) -> UIImage? {
        let name: String
        switch theme {
        case .classic: name = "newClassicVerseMarker"
        case .tinted:  name = "newTintedVerseMarker"
        }

        let key = "\(name)-\(isDarkMode)" as NSString
        if let cached = ornamentCache.object(forKey: key) { return cached }

        let traits = UITraitCollection(userInterfaceStyle: isDarkMode ? .dark : .light)
        guard let resolved = UIImage(named: name)?.imageAsset?.image(with: traits) else {
            return nil
        }
        ornamentCache.setObject(resolved, forKey: key)
        return resolved
    }

    // MARK: - Number

    /// The number-only private-use character (U+E900 + n - 1).
    private static func numberText(for verseNumber: Int) -> NSString? {
        guard verseNumber >= 1, verseNumber <= maxVerseNumber else { return nil }
        guard let scalar = Unicode.Scalar(numberBaseCodePoint + (verseNumber - 1)) else { return nil }
        return String(scalar) as NSString
    }

    private static func numberAttributes(
        ornamentHeight: CGFloat,
        isDarkMode: Bool
    ) -> [NSAttributedString.Key: Any]? {
        guard let font = UIFont(name: numbersFontName,
                               size: ornamentHeight * numberSizeRatio) else {
            return nil
        }
        return [
            .font: font,
            .foregroundColor: isDarkMode ? UIColor.white : UIColor.black
        ]
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
        contentMode = .redraw
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

/// The verse currently being recited, resolved by the pager.
///
/// Passed into `QuranPageView` as a plain value so AudioEngine's continuous
/// ticks (`verseProgress`, `verseElapsed`) never invalidate a page body.
struct PlayingVerse: Equatable {
    let surahNumber: Int
    let verseNumber: Int
}

struct QuranPageView: View {
    let pageNumber: Int
    @ObservedObject var viewModel: QuranViewModel

    /// Nil when nothing is playing or loading on this page.
    let playingVerse: PlayingVerse?

    @Environment(\.colorScheme) var colorScheme

    /// Observed so the page redraws bookmark badges whenever any bookmark
    /// is added, removed, or recolored from anywhere in the app.
    @ObservedObject private var storage = StorageManager.shared

    private let quranDB = QuranDatabase.shared
    private let imageCache = QuranPageImageCache.shared

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
        guard let playingVerse else { return [] }
        let verses = quranDB.getVersesForPage(pageNumber)
        guard let match = verses.first(where: {
            $0.chapterNumber == playingVerse.surahNumber && $0.number == playingVerse.verseNumber
        }) else { return [] }
        return quranDB.getAllHighlightsForPage(pageNumber).filter { $0.verseID == match.verseID }
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
                .onAppear {
                    imageCache.prefetchNeighbors(of: pageNumber, targetWidth: pageWidth)
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
                theme: storage.getSettings()?.selectedTheme ?? .tinted
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
        if let uiImage = imageCache.lineImage(page: pageNumber, line: lineIndex, targetWidth: width) {
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
            theme: storage.getSettings()?.selectedTheme ?? .tinted
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
