//
//  HijriCalendarDayDetailCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct HijriCalendarDayDetailCard: View {

    let hijriDateText: String
    let gregorianDateText: String
    let occasionsSectionTitle: String
    let noOccasionMessage: String
    let occasions: [IslamicOccasion]
    let occasionTitle: (IslamicOccasion) -> String

    private static let badgeDiameter: CGFloat = 32

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            dateStack

            Divider()
                .overlay(ColorStyle.cardBorder.color)

            occasionStack
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .background(Color.cardSurface)
        .cornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .strokeBorder(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }
}

// MARK: - Dates

private extension HijriCalendarDayDetailCard {

    var dateStack: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            Text(hijriDateText)
                .customStyle(.heading3, .onSurface)

            Text(gregorianDateText)
                .customStyle(.caption1, .onSurfaceVariant)
        }
    }
}

// MARK: - Occasions

private extension HijriCalendarDayDetailCard {

    @ViewBuilder
    var occasionStack: some View {
        if occasions.isEmpty {
            Text(noOccasionMessage)
                .customStyle(.bodySmall, .onSurfaceVariant)
        } else {
            VStack(alignment: .leading, spacing: .sm) {
                Text(occasionsSectionTitle)
                    .customStyle(.caption2, .onSurfaceVariant)

                ForEach(occasions) { occasion in
                    occasionRow(occasion)
                }
            }
        }
    }

    func occasionRow(_ occasion: IslamicOccasion) -> some View {
        HStack(spacing: .sm) {
            Image(systemName: iconName(occasion.kind))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accentColor(occasion.kind))
                .frame(width: HijriCalendarDayDetailCard.badgeDiameter,
                       height: HijriCalendarDayDetailCard.badgeDiameter)
                .background(Circle().fill(accentColor(occasion.kind).opacity(0.12)))
                .accessibilityHidden(true)

            Text(occasionTitle(occasion))
                .customStyle(.bodySmall, .onSurface)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    func iconName(_ kind: IslamicOccasionKind) -> String {
        switch kind {
        case .celebration: return "sparkles"
        case .fasting:     return "moon.stars"
        case .sacred:      return "star.circle"
        case .remembrance: return "book.closed"
        }
    }

    func accentColor(_ kind: IslamicOccasionKind) -> Color {
        switch kind {
        case .celebration: return ColorStyle.success.color
        case .fasting:     return ColorStyle.primary.color
        case .sacred:      return ColorStyle.warning.color
        case .remembrance: return ColorStyle.secondary.color
        }
    }
}
