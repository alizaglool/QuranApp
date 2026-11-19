//
//  VerseImageCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import SwiftUI
import Core

struct VerseImageCardContent {

    let verseText: String
    let verseEndGlyph: String?
    let reference: String
    let brandName: String
    let layoutDirection: LayoutDirection
}

struct VerseImageCard: View {

    let content: VerseImageCardContent

    static let imageWidth: CGFloat = 360
    static let renderScale: CGFloat = 3

    private static let outerPadding: CGFloat = 18
    private static let cornerRadius: CGFloat = 26

    private var surfaceWidth: CGFloat {
        Self.imageWidth - Self.outerPadding * 2
    }

    private var primaryTint: Color {
        ColorStyle.primary.color
    }

    private var verseLine: String {
        guard let glyph = content.verseEndGlyph else { return content.verseText }

        return "\(content.verseText) \(glyph)"
    }

    private var verseFontSize: CGFloat {
        switch content.verseText.count {
        case ..<120:  return 30
        case ..<320:  return 25
        case ..<700:  return 21
        default:      return 17
        }
    }

    private var verseLineSpacing: CGFloat {
        verseFontSize * 0.5
    }

    var body: some View {
        VStack(spacing: 22) {
            ornamentDivider

            Text(verseLine)
                .customStyle(.quranPage(size: verseFontSize), .quranText)
                .multilineTextAlignment(.center)
                .lineSpacing(verseLineSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.layoutDirection, .rightToLeft)

            ornamentDivider

            footer
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 30)
        .frame(width: surfaceWidth)
        .background(surface)
        .padding(Self.outerPadding)
        .background(Color.background)
        .environment(\.layoutDirection, content.layoutDirection)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 6) {
            Text(content.reference)
                .customStyle(.kitab(size: 15, bold: true), .primary)
                .multilineTextAlignment(.center)

            Text(content.brandName)
                .customStyle(.kitab(size: 12), .onSurfaceVariant)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Surface

    private var surface: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
            .fill(Color.surfaceContainerLow)
            .overlay(
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .strokeBorder(primaryTint.opacity(0.16), lineWidth: 1)
            )
    }

    // MARK: - Ornament

    private var ornamentDivider: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(colors: [primaryTint.opacity(0),
                                            primaryTint.opacity(0.45),
                                            primaryTint.opacity(0)],
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .frame(height: 1)

            Circle()
                .fill(primaryTint.opacity(0.7))
                .frame(width: 5, height: 5)
        }
        .frame(height: 6)
    }
}
