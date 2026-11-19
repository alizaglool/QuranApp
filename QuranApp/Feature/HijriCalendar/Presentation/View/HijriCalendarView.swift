//
//  HijriCalendarView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct HijriCalendarView: View {

    @StateObject private var viewModel: HijriCalendarViewModel

    init(coordinator: any HijriCalendarCoordinating) {
        _viewModel = StateObject(wrappedValue: HijriCalendarViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension HijriCalendarView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(spacing: .md) {
                    monthHeader
                    monthGrid
                    dayDetail
                }
                .padding(.horizontal, .big)
                .padding(.bottom, .xxxBig)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.coordinateBack) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            Text(viewModel.navigationTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)

            if !viewModel.isCurrentMonth {
                Button(action: viewModel.returnToCurrentMonth) {
                    Text(viewModel.todayTitle)
                        .customStyle(.caption1, .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Month header

private extension HijriCalendarView {

    var monthHeader: some View {
        HStack(spacing: .sm) {
            monthStepButton(iconName: "chevron.backward",
                            accessibilityLabel: viewModel.previousMonthAccessibilityLabel,
                            action: viewModel.showPreviousMonth)

            Text(viewModel.monthTitle)
                .customStyle(.headline, .onSurface)
                .frame(maxWidth: .infinity)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            monthStepButton(iconName: "chevron.forward",
                            accessibilityLabel: viewModel.nextMonthAccessibilityLabel,
                            action: viewModel.showNextMonth)
        }
        .padding(.top, .xSm)
    }

    func monthStepButton(iconName: String,
                         accessibilityLabel: String,
                         action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .customForeground(.primary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(ColorStyle.surfaceContainerLow.color))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Grid and detail

private extension HijriCalendarView {

    var monthGrid: some View {
        HijriCalendarMonthGrid(weekdayTitles: viewModel.weekdayTitles,
                               cells: viewModel.cells,
                               selectedDayID: viewModel.selectedDay?.id,
                               dayNumber: viewModel.dayNumberText,
                               dayAccessibilityLabel: viewModel.dayAccessibilityLabel,
                               onSelect: viewModel.selectDay)
    }

    @ViewBuilder
    var dayDetail: some View {
        if viewModel.selectedDay != nil {
            HijriCalendarDayDetailCard(hijriDateText: viewModel.selectedHijriDateText,
                                       gregorianDateText: viewModel.selectedGregorianDateText,
                                       occasionsSectionTitle: viewModel.occasionsSectionTitle,
                                       noOccasionMessage: viewModel.noOccasionMessage,
                                       occasions: viewModel.selectedOccasions,
                                       occasionTitle: viewModel.occasionTitle)
        }
    }
}
