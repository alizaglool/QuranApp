//
//  VerseSnippetView.swift
//  QuranApp
//

import SwiftUI
import UIKit

// MARK: - VerseSnippetView

struct VerseSnippetView: View {
    let surahNumber: Int
    let verseNumber: Int
    @Environment(\.colorScheme) private var colorScheme

    private static let lineToPageWidthRatio: CGFloat = 1.4 / 15

    private struct SnippetData {
        let page: Int
        let lines: [VerseHighlightRect]
        let marker: VersePosition?
    }

    private var data: SnippetData? {
        let db = QuranDatabase.shared
        guard let info = db.getVerseInfo(surahNumber: surahNumber, verseNumber: verseNumber) else { return nil }
        let highlights = db.getHighlights(forVerse: info.verseID).sorted { $0.line < $1.line }
        guard !highlights.isEmpty else { return nil }
        let marker = db.getVersesForPage(info.page).first { $0.verseID == info.verseID }
        return SnippetData(page: info.page, lines: highlights, marker: marker)
    }

    var body: some View {
        if let d = data, let first = d.lines.first, let last = d.lines.last {
            snippetContent(d, firstLine: first.line, lineCount: last.line - first.line + 1)
        } else {
            Color.clear.frame(height: 60)
        }
    }

    private func snippetContent(_ d: SnippetData, firstLine: Int, lineCount: Int) -> some View {
        let aspect: CGFloat = 15.0 / (1.4 * CGFloat(lineCount))
        let isDark = colorScheme == .dark
        let textColor: Color = isDark ? .white : .black

        return Color.clear
            .aspectRatio(aspect, contentMode: .fit)
            .overlay(
                GeometryReader { geo in
                    let lineH = geo.size.width * Self.lineToPageWidthRatio
                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(d.lines, id: \.line) { rect in
                                maskedLineImage(
                                    page: d.page,
                                    file: rect.line + 1,
                                    leftVal: rect.leftVal,
                                    rightVal: rect.rightVal,
                                    width: geo.size.width,
                                    height: lineH,
                                    color: textColor
                                )
                            }
                        }
                        if let pos = d.marker {
                            VerseMarkerSnippetOverlay(
                                verseNumber: pos.number,
                                markerLine: pos.markerLine,
                                markerCenterX: pos.markerCenterX,
                                markerCenterY: pos.markerCenterY,
                                firstLine: firstLine,
                                lineCount: lineCount,
                                isDarkMode: isDark
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(width: geo.size.width, height: CGFloat(lineCount) * lineH)
                }
            )
    }

    @ViewBuilder
    private func maskedLineImage(page: Int, file: Int, leftVal: Float, rightVal: Float, width: CGFloat, height: CGFloat, color: Color) -> some View {
        if let img = loadLine(page: page, file: file) {
            Image(uiImage: img)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundColor(color)
                .frame(width: width, height: height)
                .mask(
                    // Force LTR so positions match physical image coordinates (leftVal=0 → left edge)
                    HStack(spacing: 0) {
                        Color.clear.frame(width: CGFloat(leftVal) * width)
                        Color.black.frame(width: max(1, CGFloat(rightVal - leftVal) * width))
                        Spacer(minLength: 0)
                    }
                    .frame(width: width, height: height)
                    .environment(\.layoutDirection, .leftToRight)
                )
        } else {
            Color.clear.frame(width: width, height: height)
        }
    }

    private func loadLine(page: Int, file: Int) -> UIImage? {
        if let resourcePath = Bundle.main.resourcePath {
            let path = "\(resourcePath)/\(page)/\(file).png"
            if let img = UIImage(contentsOfFile: path) { return img }
        }
        return Bundle.main.path(forResource: "\(file)", ofType: "png", inDirectory: "\(page)")
            .flatMap { UIImage(contentsOfFile: $0) }
    }
}

// MARK: - VerseMarkerSnippetOverlay

struct VerseMarkerSnippetOverlay: UIViewRepresentable {
    let verseNumber: Int
    let markerLine: Int
    let markerCenterX: Float
    let markerCenterY: Float
    let firstLine: Int
    let lineCount: Int
    let isDarkMode: Bool

    func makeUIView(context: Context) -> VerseMarkerSnippetUIView {
        VerseMarkerSnippetUIView()
    }

    func updateUIView(_ view: VerseMarkerSnippetUIView, context: Context) {
        view.verseNumber = verseNumber
        view.markerLine = markerLine
        view.markerCenterX = markerCenterX
        view.markerCenterY = markerCenterY
        view.firstLine = firstLine
        view.lineCount = lineCount
        view.isDarkMode = isDarkMode
        view.setNeedsDisplay()
    }
}

// MARK: - VerseMarkerSnippetUIView

final class VerseMarkerSnippetUIView: UIView {
    var verseNumber: Int = 0
    var markerLine: Int = 0
    var markerCenterX: Float = 0
    var markerCenterY: Float = 0
    var firstLine: Int = 0
    var lineCount: Int = 1
    var isDarkMode: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard lineCount > 0, let ctx = UIGraphicsGetCurrentContext() else { return }
        let lineH = bounds.height / CGFloat(lineCount)
        let x = CGFloat(markerCenterX) * bounds.width
        let y = CGFloat(markerLine - firstLine) * lineH + CGFloat(markerCenterY) * lineH
        QuranGlyphRenderer.drawVerseNumber(
            verseNumber,
            centeredAt: CGPoint(x: x, y: y),
            fontSize: lineH * 0.65,
            isDarkMode: isDarkMode,
            in: ctx
        )
    }
}
