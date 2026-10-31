//
//  AthkarReaderCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarReaderCard: View {

    let page: AthkarReaderPage
    let icon: String
    let scale: CGFloat
    let showsTranslation: Bool
    let meaningTitle: String
    let pronunciationTitle: String
    let sourceTitle: String
    var repetitionLabel: String = ""
    var repetitionAccessibilityLabel: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: .big) {
            header

            blocks

            if showsTranslation, page.hasMeaning {
                section(title: meaningTitle) {
                    latinBlock(page.meaning, style: .bodyMedium, color: .onSurface)
                }
            }

            if showsTranslation, page.hasTransliteration {
                section(title: pronunciationTitle) {
                    latinBlock(page.transliteration, style: .bodySmall, color: .onSurfaceVariant, italic: true)
                }
            }

            if page.hasSource {
                section(title: sourceTitle) {
                    arabicBlock(page.source, style: .adhkar(size: size(14)), color: .onSurfaceVariant, lineSpacing: 5)
                }
            }
        }
        .padding(.horizontal, .xxBig)
        .padding(.vertical, .xxBig)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topTrailing) {
            Image(systemName: icon)
                .font(.system(size: 120, weight: .thin))
                .foregroundColor(ColorStyle.adhkarWatermark.color)
                .offset(x: 10, y: 16)
                .allowsHitTesting(false)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.adhkarSurface)
                .shadow(color: .adhkarShadow, radius: 22, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.adhkarHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Header

private extension AthkarReaderCard {

    var header: some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack(spacing: .xSm) {
                Text(page.eyebrow)
                    .customStyle(.caption2, .outline)
                    .tracking(1.2)

                Spacer(minLength: .xSm)

                if !repetitionLabel.isEmpty {
                    repetitionBadge
                } else if page.hasRepeatBadge {
                    repeatBadge
                }
            }

            if page.hasTitle {
                arabicBlock(page.title, style: .adhkar(size: size(19), bold: true), color: .primary, lineSpacing: 6)
            }

            if page.hasSituation {
                Text(page.situation)
                    .customStyle(.caption2, .onSurfaceVariant)
            }
        }
    }

    var repeatBadge: some View {
        Text(page.repeatBadge)
            .customStyle(.caption2, .secondary)
            .padding(.horizontal, .sm)
            .padding(.vertical, .xxSm)
            .background(
                Capsule().fill(ColorStyle.washSecondarySubtle.color)
            )
    }

    var repetitionBadge: some View {
        HStack(spacing: .xxSm) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.caption2)
                .customForeground(.primary)

            Text(repetitionLabel)
                .customStyle(.caption2, .primary)
                .monospacedDigit()
                .environment(\.layoutDirection, .leftToRight)
        }
        .padding(.horizontal, .sm)
        .padding(.vertical, .xxSm)
        .background(
            Capsule().fill(ColorStyle.washPrimary.color)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(repetitionAccessibilityLabel)
        .animation(.easeInOut(duration: 0.2), value: repetitionLabel)
    }
}

// MARK: - Body

private extension AthkarReaderCard {

    var blocks: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(page.blocks) { block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    func blockView(_ block: AthkarReaderBlock) -> some View {
        switch block.kind {
        case .heading:
            arabicBlock(block.text, style: .adhkar(size: size(18)), color: .secondary, lineSpacing: 7)

        case .quran:
            Text(AthkarReaderQuranText.attributed(block.text, size: size(30)))
                .foregroundColor(ColorStyle.onSurface.color)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
                .environment(\.layoutDirection, .rightToLeft)

        case .body:
            arabicBlock(block.text, style: .adhkar(size: size(22)), color: .onSurface, lineSpacing: 10)

        case .note:
            arabicBlock(block.text, style: .adhkar(size: size(15)), color: .secondary, lineSpacing: 5)
        }
    }
}

// MARK: - Building blocks

private extension AthkarReaderCard {

    func size(_ base: CGFloat) -> CGFloat {
        (base * scale).rounded()
    }

    func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .sm) {
            Divider()
                .overlay(ColorStyle.outlineVariant.color.opacity(0.3))

            Text(title)
                .customStyle(.caption2, .outline)
                .tracking(0.8)

            content()
        }
    }

    func arabicBlock(_ text: String, style: AppTextStyle, color: ColorStyle, lineSpacing: CGFloat) -> some View {
        Text(text)
            .customStyle(style, color)
            .multilineTextAlignment(.center)
            .lineSpacing(lineSpacing)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .environment(\.layoutDirection, .rightToLeft)
    }

    func latinBlock(_ text: String, style: AppTextStyle, color: ColorStyle, italic: Bool = false) -> some View {
        Text(text)
            .customStyle(style, color)
            .italic(italic)
            .multilineTextAlignment(.leading)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, .leftToRight)
    }
}

// MARK: - Quran text

enum AthkarReaderQuranText {

    private static let arabicDigits: Set<Character> = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"]

    private static let digitMap: [Character: Character] = [
        "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
        "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
    ]

    static func attributed(_ text: String, size: CGFloat) -> AttributedString {
        let hafs = QuranFont.hafs.font(size: size)
        var result = AttributedString()
        var textBuffer = ""
        var digitBuffer = ""

        func flushText() {
            guard !textBuffer.isEmpty else { return }
            var segment = AttributedString(textBuffer)
            segment.font = hafs
            result.append(segment)
            textBuffer = ""
        }

        func flushDigits() {
            guard !digitBuffer.isEmpty else { return }
            let latin = String(digitBuffer.map { digitMap[$0] ?? $0 })
            var segment: AttributedString

            if let number = Int(latin), let glyph = QuranTextService.verseEndGlyph(for: number) {
                segment = AttributedString(glyph)
            } else {
                segment = AttributedString(digitBuffer)
            }

            segment.font = hafs
            result.append(segment)
            digitBuffer = ""
        }

        for character in text {
            if arabicDigits.contains(character) {
                flushText()
                digitBuffer.append(character)
            } else {
                flushDigits()
                textBuffer.append(character)
            }
        }

        flushText()
        flushDigits()
        return result
    }
}
