//
//  QuranPageBars.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - QuranPageHeaderBar

/// Top bar shared by QuranPageView and QuranTextPageView.
/// Shows the surah name on the right and the first verse number on the left (RTL layout).
struct QuranPageHeaderBar: View {

    let surahName: String
    let firstVerse: Int
    let textColor: Color

    var body: some View {
        HStack {
            Text(verbatim: "آية \(firstVerse.arabicNumerals)")
                .customStyle(.kitab(size: 17))
                .foregroundColor(textColor.opacity(0.55))
            Spacer()
            Text(surahName)
                .customStyle(.kitab(size: 17))
                .foregroundColor(textColor.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .allowsHitTesting(false)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

// MARK: - QuranPageFooterBar

/// Bottom bar shared by QuranPageView and QuranTextPageView.
/// Shows the ornamental page-number badge, hugging the outer edge.
struct QuranPageFooterBar: View {

    let pageNumber: Int
    let isDarkMode: Bool
    let theme: Theme

    private var isRightPage: Bool { pageNumber % 2 != 0 }

    var body: some View {
        HStack {
            if isRightPage {
                Spacer()
                badge.padding(.leading, 12)
            } else {
                badge.padding(.trailing, 12)
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }

    private var badge: some View {
        OrnamentalPageBadge(
            text: pageNumber.arabicNumerals,
            isDarkMode: isDarkMode,
            theme: theme
        )
    }
}
