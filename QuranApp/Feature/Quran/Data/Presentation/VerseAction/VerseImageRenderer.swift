//
//  VerseImageRenderer.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import SwiftUI
import Core

@MainActor
enum VerseImageRenderer {

    // MARK: - Localized Titles

    static var shareAsImageTitle: String {
        AppLocalizedKeys.verseActionShareAsImage.value
    }

    static var shareFailureMessage: String {
        AppLocalizedKeys.verseImageShareFailed.value
    }

    static var shareFailureDismissTitle: String {
        AppLocalizedKeys.done.value
    }

    // MARK: - Rendering

    static func image(surahNumber: Int,
                      surahName: String,
                      verseNumber: Int,
                      colorScheme: ColorScheme) -> UIImage? {
        guard let content = cardContent(surahNumber: surahNumber,
                                        surahName: surahName,
                                        verseNumber: verseNumber)
        else { return nil }

        let renderer = ImageRenderer(content: VerseImageCard(content: content)
            .environment(\.colorScheme, colorScheme))

        renderer.scale = VerseImageCard.renderScale
        renderer.isOpaque = true

        return renderer.uiImage
    }

    // MARK: - Card Content

    private static func cardContent(surahNumber: Int,
                                    surahName: String,
                                    verseNumber: Int) -> VerseImageCardContent? {
        let verseText = QuranTextService.shared.text(surah: surahNumber, verse: verseNumber) ?? ""

        guard !verseText.isEmpty else { return nil }

        let language = LocalizationManager.shared.currentLanguage

        return VerseImageCardContent(
            verseText: verseText,
            verseEndGlyph: QuranTextService.verseEndGlyph(for: verseNumber),
            reference: "\(surahName): \(localizedNumber(verseNumber, language: language))",
            brandName: AppLocalizedKeys.appName.value,
            layoutDirection: language.direction)
    }

    private static func localizedNumber(_ value: Int,
                                        language: LocalizationManager.Language) -> String {
        language == .Arabic ? value.arabicNumerals : "\(value)"
    }
}
