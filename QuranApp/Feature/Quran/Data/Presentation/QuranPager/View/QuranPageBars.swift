//
//  QuranPageBars.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - QuranPageHeaderBar

struct QuranPageHeaderBar: View {

    let surahName: String
    let juzNumber: Int

    var body: some View {
        HStack {
            Text(verbatim: "\(AppLocalizedKeys.juz.value) \(juzNumber.arabicNumerals)")
                .customStyle(.kitab(size: 17))
                .foregroundColor(Color.mushafBarLabel)
            Spacer()
            Text(surahName)
                .customStyle(.kitab(size: 17))
                .foregroundColor(Color.mushafBarLabel)
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
            theme: theme
        )
    }
}
