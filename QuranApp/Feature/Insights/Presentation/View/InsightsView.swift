//
//  InsightsView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct InsightsView: View {

    @StateObject private var viewModel: InsightsViewModel

    init(coordinator: any InsightsCoordinating) {
        _viewModel = StateObject(wrappedValue: InsightsViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension InsightsView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            InsightsRangeChips(ranges: viewModel.ranges,
                               selectedRange: viewModel.range,
                               title: viewModel.rangeTitle,
                               onSelect: viewModel.selectRange)
                .padding(.horizontal, .big)
                .padding(.bottom, .sm)

            NoIndicatorsScrollView {
                VStack(spacing: .md) {
                    overviewCard

                    if viewModel.isEmptyStateVisible {
                        emptyStateCard
                    } else {
                        readingTrendCard
                        worshipTrendCard
                    }

                    if viewModel.isConsistencyVisible {
                        consistencyCard
                    }

                    khatmahCard
                    libraryCard
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
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    func card<Content: View>(_ title: String,
                             caption: String = "",
                             @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack(spacing: .xSm) {
                Text(title)
                    .customStyle(.subheadline, .onSurface)

                Spacer(minLength: 0)

                if !caption.isEmpty {
                    Text(caption)
                        .customStyle(.caption2, .onSurfaceVariant)
                }
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .background(ColorStyle.surfaceContainerLow.color)
        .cornerRadius(.cornerCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard)
                .strokeBorder(Color.outlineVariant.opacity(0.14), lineWidth: 1)
        )
    }
}

// MARK: - Sections

private extension InsightsView {

    var overviewCard: some View {
        card(viewModel.overviewTitle) {
            HStack(spacing: .xSm) {
                ForEach(viewModel.overviewMetrics) { metric in
                    InsightsMetricTile(item: metric)
                }
            }
        }
    }

    var emptyStateCard: some View {
        VStack(spacing: .sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30, weight: .light))
                .customForeground(.onSurfaceVariant)

            Text(viewModel.emptyStateMessage)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .xxBig)
        .padding(.horizontal, .md)
        .background(ColorStyle.surfaceContainerLow.color)
        .cornerRadius(.cornerCard)
    }

    var readingTrendCard: some View {
        card(viewModel.readingTrendTitle, caption: viewModel.readingAverageText) {
            InsightsBarChart(bars: viewModel.readingBars, accent: .primary)
        }
    }

    var worshipTrendCard: some View {
        card(viewModel.worshipTrendTitle, caption: viewModel.worshipAverageText) {
            InsightsBarChart(bars: viewModel.worshipBars, accent: .secondary)
        }
    }

    var consistencyCard: some View {
        card(viewModel.consistencyTitle, caption: viewModel.trackedDaysNote) {
            VStack(alignment: .leading, spacing: .sm) {
                ForEach(viewModel.consistencyItems) { item in
                    InsightsConsistencyRow(item: item)
                }

                highlightRow
            }
        }
    }

    @ViewBuilder
    var highlightRow: some View {
        let strongest = viewModel.strongestPrayerText
        let weakest = viewModel.weakestPrayerText

        if !strongest.isEmpty || !weakest.isEmpty {
            HStack(spacing: .sm) {
                if !strongest.isEmpty {
                    highlightChip(title: viewModel.strongestPrayerTitle,
                                  value: strongest,
                                  accent: .success)
                }

                if !weakest.isEmpty {
                    highlightChip(title: viewModel.weakestPrayerTitle,
                                  value: weakest,
                                  accent: .warning)
                }
            }
            .padding(.top, .xxSm)
        }
    }

    func highlightChip(title: String, value: String, accent: ColorStyle) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .customStyle(.caption2, .onSurfaceVariant)

            Text(value)
                .customStyle(.caption1, accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.sm)
        .background(accent.color.opacity(0.08))
        .customCornerRadius(.cornerMd)
    }

    @ViewBuilder
    var khatmahCard: some View {
        if viewModel.isKhatmahPlanActive {
            card(viewModel.khatmahTitle, caption: viewModel.khatmahPercentText) {
                VStack(alignment: .leading, spacing: .xSm) {
                    InsightsConsistencyRow(item: InsightsConsistencyItem(id: -1,
                                                                         title: viewModel.khatmahPagesText,
                                                                         value: viewModel.khatmahDriftText,
                                                                         fraction: viewModel.khatmahFraction,
                                                                         accent: viewModel.khatmahDriftAccent))

                    Text(viewModel.khatmahDaysText)
                        .customStyle(.caption2, .onSurfaceVariant)
                }
            }
        } else {
            card(viewModel.khatmahTitle) {
                Text(viewModel.khatmahNoPlanMessage)
                    .customStyle(.caption1, .onSurfaceVariant)
            }
        }
    }

    var libraryCard: some View {
        card(viewModel.libraryTitle) {
            HStack(spacing: .xSm) {
                ForEach(viewModel.libraryMetrics) { metric in
                    InsightsMetricTile(item: metric)
                }
            }
        }
    }
}
