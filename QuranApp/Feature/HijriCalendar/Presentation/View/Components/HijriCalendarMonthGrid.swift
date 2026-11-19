//
//  HijriCalendarMonthGrid.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct HijriCalendarMonthGrid: View {

    let weekdayTitles: [String]
    let cells: [HijriCalendarCell]
    let selectedDayID: String?
    let dayNumber: (HijriCalendarDay) -> String
    let dayAccessibilityLabel: (HijriCalendarDay) -> String
    let onSelect: (HijriCalendarDay) -> Void

    private static let columnSpacing: CGFloat = 6
    private static let rowSpacing: CGFloat = 6
    private static let occasionDotDiameter: CGFloat = 5

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: HijriCalendarMonthGrid.columnSpacing),
              count: HijriMonthGridBuilder.weekdayCount)
    }

    var body: some View {
        VStack(spacing: .xSm) {
            weekdayHeader

            LazyVGrid(columns: columns, spacing: HijriCalendarMonthGrid.rowSpacing) {
                ForEach(cells) { cell in
                    cellView(cell)
                }
            }
        }
        .padding(.md)
        .background(Color.cardSurface)
        .cornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .strokeBorder(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }
}

// MARK: - Header

private extension HijriCalendarMonthGrid {

    var weekdayHeader: some View {
        HStack(spacing: HijriCalendarMonthGrid.columnSpacing) {
            ForEach(weekdayTitles, id: \.self) { title in
                Text(title)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Cells

private extension HijriCalendarMonthGrid {

    @ViewBuilder
    func cellView(_ cell: HijriCalendarCell) -> some View {
        if let day = cell.day {
            Button {
                onSelect(day)
            } label: {
                dayLabel(day)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(dayAccessibilityLabel(day))
            .accessibilityAddTraits(.isButton)
        } else {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
        }
    }

    func dayLabel(_ day: HijriCalendarDay) -> some View {
        let isSelected = day.id == selectedDayID

        return VStack(spacing: 2) {
            Text(dayNumber(day))
                .customStyle(.bodySmall)
                .foregroundColor(numberColor(day, isSelected: isSelected))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Circle()
                .fill(dotColor(day, isSelected: isSelected))
                .frame(width: HijriCalendarMonthGrid.occasionDotDiameter,
                       height: HijriCalendarMonthGrid.occasionDotDiameter)
                .opacity(day.hasOccasion ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(
            Circle()
                .fill(isSelected ? ColorStyle.primary.color : Color.clear)
        )
        .overlay(
            Circle()
                .strokeBorder(ColorStyle.primary.color,
                              lineWidth: day.isToday && !isSelected ? 1.5 : 0)
        )
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }

    func numberColor(_ day: HijriCalendarDay, isSelected: Bool) -> Color {
        if isSelected { return ColorStyle.onPrimary.color }
        if day.isToday { return ColorStyle.primary.color }
        return ColorStyle.onSurface.color
    }

    func dotColor(_ day: HijriCalendarDay, isSelected: Bool) -> Color {
        if isSelected { return ColorStyle.onPrimary.color.opacity(0.9) }
        guard day.highlightKind == .celebration else { return ColorStyle.primary.color.opacity(0.7) }
        return ColorStyle.success.color
    }
}
