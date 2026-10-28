//
//  WorshipYearGrid.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct WorshipWeekColumn: Identifiable {
    let id: String
    let cells: [WorshipDayCell]
}

struct WorshipYearGrid: View {

    let cells: [WorshipDayCell]

    private let cellSize: CGFloat = 11
    private let cellSpacing: CGFloat = 3
    private let rowsPerColumn = 7

    var body: some View {
        ScrollViewReader { scrollProxy in
            NoIndicatorsScrollView(.horizontal) {
                HStack(alignment: .top, spacing: cellSpacing) {
                    ForEach(weekColumns) { column in
                        VStack(spacing: cellSpacing) {
                            ForEach(column.cells) { cell in
                                dayTile(for: cell)
                            }
                        }
                        .id(column.id)
                    }
                }
                .padding(.vertical, .xxSm)
            }
            .onAppear { scrollToMostRecentWeek(using: scrollProxy) }
            .onChange(of: mostRecentWeekIdentifier) { _, _ in
                scrollToMostRecentWeek(using: scrollProxy)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .frame(height: CGFloat(rowsPerColumn) * cellSize + CGFloat(rowsPerColumn - 1) * cellSpacing + .xSm)
        .accessibilityHidden(true)
    }
}

// MARK: - Layout

private extension WorshipYearGrid {

    var weekColumns: [WorshipWeekColumn] {
        stride(from: 0, to: cells.count, by: rowsPerColumn).map { start in
            let slice = Array(cells[start..<min(start + rowsPerColumn, cells.count)])
            return WorshipWeekColumn(id: slice.first?.id ?? "\(start)", cells: slice)
        }
    }

    var mostRecentWeekIdentifier: String? {
        weekColumns.last?.id
    }

    func dayTile(for cell: WorshipDayCell) -> some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(cell.intensityFill)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: 2.5)
                    .stroke(ColorStyle.primary.color,
                            lineWidth: cell.isToday ? 1.5 : 0)
            )
    }

    func scrollToMostRecentWeek(using scrollProxy: ScrollViewProxy) {
        guard let identifier = mostRecentWeekIdentifier else { return }
        DispatchQueue.main.async {
            scrollProxy.scrollTo(identifier, anchor: .trailing)
        }
    }
}

// MARK: - Intensity Palette

extension WorshipDayCell {

    var intensityFill: Color {
        switch level {
        case 1: return ColorStyle.primary.color.opacity(0.22)
        case 2: return ColorStyle.primary.color.opacity(0.45)
        case 3: return ColorStyle.primary.color.opacity(0.7)
        case 4: return ColorStyle.primary.color
        default: return ColorStyle.outlineVariant.color.opacity(0.22)
        }
    }
}
