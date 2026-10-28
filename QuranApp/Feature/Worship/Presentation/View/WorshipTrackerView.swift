//
//  WorshipTrackerView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct WorshipTrackerView: View {

    @StateObject private var viewModel: WorshipTrackerViewModel

    init(coordinator: any WorshipCoordinating) {
        _viewModel = StateObject(wrappedValue: WorshipTrackerViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension WorshipTrackerView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    todayCard
                    actCategorySections
                    streaksSection
                    weekSection
                    yearSection
                    yesterdayToggleButton
                    disclaimerCard
                }
                .padding(.horizontal, .big)
                .padding(.top, .sm)
                .padding(.bottom, .xxxBig)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.screenTitle)
                    .customStyle(.heading3, .onSurface)
                Text(viewModel.isShowingYesterday ? viewModel.yesterdayTitle : viewModel.todayTitle)
                    .customStyle(.caption1, .subtitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Sections

private extension WorshipTrackerView {

    var todayCard: some View {
        WorshipTodayCard(
            title: viewModel.isShowingYesterday ? viewModel.yesterdayTitle : viewModel.todayTitle,
            completedText: viewModel.completedText,
            percentText: viewModel.percentText,
            fraction: viewModel.fraction,
            currentStreakTitle: viewModel.currentStreakTitle,
            currentStreakValue: viewModel.currentStreakText,
            bestStreakTitle: viewModel.bestStreakTitle,
            bestStreakValue: viewModel.bestStreakText,
            daysUnit: viewModel.dayStreakUnit
        )
    }

    var actCategorySections: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(viewModel.hintText)
                .customStyle(.caption1, .onSurfaceVariant)

            ForEach(viewModel.sections) { section in
                VStack(alignment: .leading, spacing: .xSm) {
                    Text(section.title)
                        .customStyle(.subheadline, .onSurface)

                    VStack(spacing: .xSm) {
                        ForEach(section.items) { item in
                            WorshipActRow(item: item,
                                          accent: section.accent,
                                          lockedText: viewModel.lockedText) {
                                viewModel.toggleCompletion(for: item)
                            }
                        }
                    }
                }
            }
        }
    }

    var streaksSection: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.streaksTitle)
                .customStyle(.subheadline, .onSurface)

            WorshipStreakRow(sections: viewModel.sections,
                             bestTitle: viewModel.bestStreakTitle,
                             daysUnit: viewModel.dayStreakUnit)
        }
    }

    var weekSection: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.weekTitle)
                .customStyle(.subheadline, .onSurface)

            HStack(spacing: .xSm) {
                ForEach(viewModel.weekCells) { cell in
                    RoundedRectangle(cornerRadius: .cornerSm)
                        .fill(cell.intensityFill)
                        .frame(height: 34)
                        .overlay(
                            RoundedRectangle(cornerRadius: .cornerSm)
                                .stroke(ColorStyle.primary.color,
                                        lineWidth: cell.isToday ? 1.5 : 0)
                        )
                }
            }
        }
    }

    var yearSection: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.yearTitle)
                .customStyle(.subheadline, .onSurface)

            WorshipYearGrid(cells: viewModel.yearCells)
        }
    }

    var yesterdayToggleButton: some View {
        Button {
            viewModel.toggleYesterdayEditing()
        } label: {
            HStack(spacing: .xSm) {
                Image(systemName: viewModel.isShowingYesterday ? "arrow.uturn.forward" : "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .semibold))
                    .customForeground(.primary)

                Text(viewModel.isShowingYesterday ? viewModel.backToTodayTitle : viewModel.editYesterdayTitle)
                    .customStyle(.buttonText, .primary)

                Spacer(minLength: 0)
            }
            .padding(.sm)
            .frame(maxWidth: .infinity)
            .background(ColorStyle.primary.color.opacity(0.08))
            .customCornerRadius(.cornerLg)
        }
        .buttonStyle(.plain)
    }

    var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            HStack(spacing: .xxSm) {
                Image(systemName: "hand.raised")
                    .font(.system(size: 12, weight: .semibold))
                    .customForeground(.onSurfaceVariant)

                Text(viewModel.disclaimerTitle)
                    .customStyle(.caption1, .onSurfaceVariant)
            }

            Text(viewModel.disclaimerBody)
                .customStyle(.caption2, .onSurfaceVariant)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .background(ColorStyle.outlineVariant.color.opacity(0.18))
        .customCornerRadius(.cornerLg)
    }
}
