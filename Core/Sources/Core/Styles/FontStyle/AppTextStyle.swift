//
//  AppTextStyle.swift
//  Core
//

import SwiftUI

/// Single source of truth for every text style in the app.
/// Use `.customStyle(_:)` on any View — no other font modifier needed.
public enum AppTextStyle {

    // ── Predefined UI styles (NotoSerif display / Manrope body) ──────────────
    case largeTitle
    case heading1
    case heading2
    case heading3
    case headline
    case buttonText
    case subheadline
    case bodyMedium
    case bodySmall
    case caption1
    case caption2

    // ── Arabic UI ─────────────────────────────────────────────────────────────
    /// San Francisco — all Arabic interface text (system font, regular or semibold).
    case kitab(size: CGFloat, bold: Bool = false)

    // ── Adhkar & Hadith ───────────────────────────────────────────────────────
    /// TheYearofHandicrafts — used exclusively in Adhkar and Hadith modules.
    case adhkar(size: CGFloat, bold: Bool = false)

    // ── Quran page text ───────────────────────────────────────────────────────
    /// KFGQPCHafsSmart-Regular — main Quran page text (Hafs script).
    case quranPage(size: CGFloat)

    /// HafsSmart_08_fixed — fixed-width Hafs variant used in dhikr / counter views.
    case quranPageFixed(size: CGFloat)

    /// QuranTitles — ornamental surah title banners.
    case quranTitle(size: CGFloat)

    /// QuranNumbers — ornamental verse number badges.
    case quranNumber(size: CGFloat)

    // ── Uthmanic scripts ──────────────────────────────────────────────────────
    /// KFGQPCUthmanTahaNaskh (regular or bold).
    case uthmanicNaskh(size: CGFloat, bold: Bool = false)

    /// KFGQPCHAFSUthmanicScript-Regula.
    case uthmanicHafs(size: CGFloat)

    // MARK: - Internal resolution

    /// Maps predefined UI cases to the existing FontStyle system (keeps line-height behaviour).
    var fontStyle: FontStyle? {
        switch self {
        case .largeTitle:  return .largeTitle
        case .heading1:    return .heading1
        case .heading2:    return .heading2
        case .heading3:    return .heading3
        case .headline:    return .headline
        case .buttonText:  return .buttonText
        case .subheadline: return .subheadline
        case .bodyMedium:  return .bodyMedium
        case .bodySmall:   return .bodySmall
        case .caption1:    return .caption1
        case .caption2:    return .caption2
        default:           return nil
        }
    }

    /// Direct SwiftUI Font for custom-font cases (no extra line-height padding).
    public var directFont: Font {
        switch self {
        case .kitab(let size, let bold):
            return .system(size: size, weight: bold ? .semibold : .regular)
        case .adhkar(let size, let bold):
            return .custom(bold ? "TheYearofHandicrafts-SemiBold" : "TheYearofHandicrafts-Regular", size: size)
        case .quranPage(let size):
            return QuranFont.hafs.font(size: size)
        case .quranPageFixed(let size):
            return QuranFont.hafsFixed.font(size: size)
        case .quranTitle(let size):
            return QuranFont.titles.font(size: size)
        case .quranNumber(let size):
            return QuranFont.numbers.font(size: size)
        case .uthmanicNaskh(let size, let bold):
            return (bold ? QuranFont.uthmanicNaskhBold : QuranFont.uthmanicNaskh).font(size: size)
        case .uthmanicHafs(let size):
            return QuranFont.uthmanicHafs.font(size: size)
        default:
            return .body
        }
    }
}

// MARK: - ViewModifier

struct AppTextStyleModifier: ViewModifier {
    let style: AppTextStyle

    @ViewBuilder
    func body(content: Content) -> some View {
        if let fontStyle = style.fontStyle {
            content.modifier(CustomFontModifier(fontStyle: fontStyle))
        } else {
            content.font(style.directFont)
        }
    }
}

// MARK: - View extension

public extension View {
    /// Apply any app text style — the only font modifier you need.
    func customStyle(_ style: AppTextStyle) -> some View {
        modifier(AppTextStyleModifier(style: style))
    }

    func customStyle(_ style: AppTextStyle, _ color: ColorStyle) -> some View {
        modifier(AppTextStyleModifier(style: style))
            .customForeground(color)
    }
}
