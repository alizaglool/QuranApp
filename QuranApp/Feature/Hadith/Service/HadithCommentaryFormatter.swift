//
//  HadithCommentaryFormatter.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/11/2026.
//

import Foundation

enum HadithCommentaryFormatter {

    private static let directionMarks: Set<Character> = ["\u{200E}", "\u{200F}"]

    static func normalized(_ raw: String) -> String {
        guard !raw.isEmpty else { return "" }
        return paragraphs(raw).joined(separator: "\n")
    }

    static func paragraphs(_ raw: String) -> [String] {
        guard !raw.isEmpty else { return [] }

        let withoutMarks = String(raw.filter { !directionMarks.contains($0) })

        return withoutMarks
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
