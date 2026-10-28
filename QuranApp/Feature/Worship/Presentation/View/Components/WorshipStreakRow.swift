//
//  WorshipStreakRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct WorshipStreakRow: View {

    let sections: [WorshipCategorySection]
    let bestTitle: String
    let daysUnit: String

    var body: some View {
        HStack(spacing: .sm) {
            ForEach(sections) { section in
                streakTile(for: section)
            }
        }
    }
}

// MARK: - Parts

private extension WorshipStreakRow {

    func streakTile(for section: WorshipCategorySection) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            HStack(spacing: .xxSm) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .customForeground(section.accent)

                Text(section.title)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            HStack(alignment: .firstTextBaseline, spacing: .xxSm) {
                Text("\(section.currentStreak)")
                    .customStyle(.kitab(size: 20, bold: true), .onSurface)

                Text(daysUnit)
                    .customStyle(.caption2, .onSurfaceVariant)
            }

            Text("\(bestTitle) \(section.bestStreak)")
                .customStyle(.caption2, .onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.sm)
        .background(section.accent.color.opacity(0.08))
        .customCornerRadius(.cornerLg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.title) \(section.currentStreak) \(daysUnit)")
    }
}
