//
//  VerseImageRendererTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import XCTest
import SwiftUI
import Core
@testable import QuranApp

@MainActor
final class VerseImageRendererTests: XCTestCase {

    private let surahNumber = 1
    private let surahName = "الفاتحة"
    private let verseNumber = 1

    private func image(colorScheme: ColorScheme) -> UIImage? {
        VerseImageRenderer.image(surahNumber: surahNumber,
                                 surahName: surahName,
                                 verseNumber: verseNumber,
                                 colorScheme: colorScheme)
    }

    // MARK: - Rendering

    func testRendersAnImageInBothColorSchemes() throws {
        for colorScheme in [ColorScheme.light, .dark] {
            let rendered = try XCTUnwrap(image(colorScheme: colorScheme))

            XCTAssertEqual(rendered.scale, VerseImageCard.renderScale)
            XCTAssertEqual(rendered.size.width, VerseImageCard.imageWidth, accuracy: 1)
            XCTAssertGreaterThan(rendered.size.height, 0)
        }
    }

    func testLightAndDarkRendersDifferInTheirPixels() throws {
        let light = try XCTUnwrap(image(colorScheme: .light)?.pngData())
        let dark = try XCTUnwrap(image(colorScheme: .dark)?.pngData())

        XCTAssertNotEqual(light, dark)
    }

    func testRendersInBothLanguages() throws {
        let manager = LocalizationManager.shared
        let original = manager.currentLanguage
        defer { manager.currentLanguage = original }

        for language in [LocalizationManager.Language.Arabic, .English] {
            manager.currentLanguage = language
            let rendered = try XCTUnwrap(image(colorScheme: .light))

            XCTAssertGreaterThan(rendered.size.height, 0)
        }
    }

    func testLongVerseStaysWithinAShareableHeight() throws {
        let longest = VerseImageRenderer.image(surahNumber: 2,
                                               surahName: "البقرة",
                                               verseNumber: 282,
                                               colorScheme: .light)
        let rendered = try XCTUnwrap(longest)

        XCTAssertEqual(rendered.size.width, VerseImageCard.imageWidth, accuracy: 1)
        XCTAssertLessThan(rendered.size.height, VerseImageCard.imageWidth * 6)
    }

    func testMissingVerseRendersNothing() {
        XCTAssertNil(VerseImageRenderer.image(surahNumber: 999,
                                              surahName: surahName,
                                              verseNumber: 1,
                                              colorScheme: .light))
        XCTAssertNil(VerseImageRenderer.image(surahNumber: 1,
                                              surahName: surahName,
                                              verseNumber: 999,
                                              colorScheme: .light))
    }

    // MARK: - Localized Titles

    func testShareTitlesResolveToLocalizedText() {
        for title in [VerseImageRenderer.shareAsImageTitle,
                      VerseImageRenderer.shareFailureMessage,
                      VerseImageRenderer.shareFailureDismissTitle] {
            XCTAssertFalse(title.isEmpty)
            XCTAssertFalse(title.contains("verseAction"))
            XCTAssertFalse(title.contains("verseImage"))
        }
    }
}
