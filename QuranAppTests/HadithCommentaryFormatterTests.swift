//
//  HadithCommentaryFormatterTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 18/11/2026.
//

import XCTest
@testable import QuranApp

final class HadithCommentaryFormatterTests: XCTestCase {

    private let rightToLeftMark = "\u{200F}"
    private let leftToRightMark = "\u{200E}"

    // MARK: - Empty input

    func testEmptyInputProducesNoParagraphs() {
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(""), [])
        XCTAssertEqual(HadithCommentaryFormatter.normalized(""), "")
    }

    func testDirectionMarksOnlyProduceNoParagraphs() {
        let raw = "\(rightToLeftMark)\n\(rightToLeftMark)\n\(rightToLeftMark)"
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(raw), [])
        XCTAssertEqual(HadithCommentaryFormatter.normalized(raw), "")
    }

    // MARK: - Bukhari export shape

    func testBukhariSandwichShapeCollapsesToCleanParagraphs() {
        let raw = "\(rightToLeftMark)\n\(rightToLeftMark)قوله ( وإذا استيقظ أحدكم من نومه )"
            + " \(rightToLeftMark)\n\(rightToLeftMark)الظاهر أن المقصود النهي"
            + " \(rightToLeftMark)\n\(rightToLeftMark)( فلا يغمس ) \(rightToLeftMark)"

        let paragraphs = HadithCommentaryFormatter.paragraphs(raw)

        XCTAssertEqual(paragraphs, [
            "قوله ( وإذا استيقظ أحدكم من نومه )",
            "الظاهر أن المقصود النهي",
            "( فلا يغمس )"
        ])
    }

    func testLeadingSandwichDoesNotProduceABlankFirstParagraph() {
        let raw = "\(rightToLeftMark)\n\(rightToLeftMark)قوله باب"
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(raw), ["قوله باب"])
    }

    func testTrailingMarkAfterSpaceLeavesNoTrailingWhitespace() {
        let raw = "قوله باب الوضوء \(rightToLeftMark)"
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(raw), ["قوله باب الوضوء"])
    }

    // MARK: - Wording preservation

    func testArabicWordingSurvivesUnchanged() {
        let sentence = "وقال ابن حجر رحمه الله: المراد بالماء الدائم الراكد"
        let raw = "\(rightToLeftMark)\(sentence)\(rightToLeftMark)"
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(raw), [sentence])
    }

    func testOnlyDirectionMarksAreStripped() {
        let raw = "\(leftToRightMark)قوله \(rightToLeftMark)( 1234 ) تمام"
        let output = HadithCommentaryFormatter.normalized(raw)
        XCTAssertEqual(output, "قوله ( 1234 ) تمام")
        XCTAssertFalse(output.unicodeScalars.contains { $0.value == 0x200F || $0.value == 0x200E })
    }

    // MARK: - Line ending normalization

    func testCarriageReturnsBecomeParagraphBreaks() {
        let raw = "الأول\r\nالثاني\rالثالث"
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(raw), ["الأول", "الثاني", "الثالث"])
    }

    func testBlankRunsCollapse() {
        let raw = "الأول\n\n\n   \n\nالثاني"
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(raw), ["الأول", "الثاني"])
        XCTAssertEqual(HadithCommentaryFormatter.normalized(raw), "الأول\nالثاني")
    }

    // MARK: - Paragraph bounding

    func testLongCommentarySplitsPerParagraphInsteadOfOneBlock() {
        let paragraph = String(repeating: "كلمة ", count: 400)
        let raw = Array(repeating: paragraph, count: 12)
            .joined(separator: " \(rightToLeftMark)\n\(rightToLeftMark)")

        let paragraphs = HadithCommentaryFormatter.paragraphs(raw)

        XCTAssertEqual(paragraphs.count, 12)
        for entry in paragraphs {
            XCTAssertLessThan(entry.count, raw.count)
        }
    }

    func testNormalizedRoundTripsThroughParagraphs() {
        let raw = "\(rightToLeftMark)\n\(rightToLeftMark)الأول \(rightToLeftMark)\n\(rightToLeftMark)الثاني \(rightToLeftMark)"
        let normalized = HadithCommentaryFormatter.normalized(raw)
        XCTAssertEqual(normalized, "الأول\nالثاني")
        XCTAssertEqual(HadithCommentaryFormatter.paragraphs(normalized),
                       HadithCommentaryFormatter.paragraphs(raw))
    }
}
