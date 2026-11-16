//
//  KhatmahTodayCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahTodayCard: View {

    let sectionTitle: String
    let captionTracking: CGFloat
    let statusText: String
    let isBehindSchedule: Bool
    let percentText: String
    let progressFraction: Double
    let dayOfTotalText: String
    let portionText: String
    let pageRangeText: String
    let metrics: [KhatmahMetric]
    let metricsAccessibilityLabel: String
    let hasStarted: Bool
    let startsOnText: String
    let isTodayCompleted: Bool
    let todayDoneTitle: String
    let readActionTitle: String
    let markCompleteActionTitle: String
    let onReadTapped: () -> Void
    let onMarkCompleteTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            header
            portion
            divider
            metricsRow
            divider
            actions
        }
        .padding(.big)
        .khatmahCardChrome()
    }
}

// MARK: - Header

private extension KhatmahTodayCard {

    var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: .xSm) {
            Text(sectionTitle)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(captionTracking)
                .lineLimit(1)

            Spacer(minLength: 0)

            statusChip
        }
    }

    @ViewBuilder
    var statusChip: some View {
        if !statusText.isEmpty {
            Text(statusText)
                .customStyle(.caption1, isBehindSchedule ? .warning : .primary)
                .lineLimit(1)
                .padding(.horizontal, .xSm)
                .padding(.vertical, 6)
                .background(isBehindSchedule
                            ? ColorStyle.warning.color.opacity(0.12)
                            : ColorStyle.washPrimary.color)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Portion

private extension KhatmahTodayCard {

    var portion: some View {
        HStack(spacing: .md) {
            KhatmahProgressRing(fraction: progressFraction, label: percentText)

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(dayOfTotalText)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
                    .monospacedDigit()

                Text(portionText)
                    .customStyle(.kitab(size: 17, bold: true), .onSurface)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)

                Text(pageRangeText)
                    .customStyle(.caption1, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Metrics

private extension KhatmahTodayCard {

    var metricsRow: some View {
        HStack(spacing: .sm) {
            ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                if index > 0 {
                    verticalDivider
                }

                metricColumn(metric)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(metricsAccessibilityLabel)
    }

    func metricColumn(_ metric: KhatmahMetric) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(metric.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .monospacedDigit()

            Text(metric.title)
                .customStyle(.caption2, .onSurfaceVariant)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var verticalDivider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color.opacity(0.3))
            .frame(width: 1, height: 36)
    }

    var divider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color.opacity(0.3))
            .frame(height: 1)
    }
}

// MARK: - Actions

private extension KhatmahTodayCard {

    @ViewBuilder
    var actions: some View {
        if !hasStarted {
            Text(startsOnText)
                .customStyle(.caption1, .onSurfaceVariant)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
        } else if isTodayCompleted {
            VStack(spacing: .xxSm) {
                doneBanner
                quietButton(title: readActionTitle, action: onReadTapped)
            }
        } else {
            VStack(spacing: .xxSm) {
                readButton
                quietButton(title: markCompleteActionTitle, action: onMarkCompleteTapped)
            }
        }
    }

    var readButton: some View {
        Button(action: onReadTapped) {
            Text(readActionTitle)
                .customStyle(.buttonText, .onPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .background(Capsule().fill(ColorStyle.primary.color))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    var doneBanner: some View {
        Label(todayDoneTitle, systemImage: "checkmark.circle.fill")
            .labelStyle(.titleAndIcon)
            .customStyle(.buttonText, .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .sm)
            .background(Capsule().fill(ColorStyle.washPrimary.color))
            .accessibilityAddTraits(.isStaticText)
    }

    func quietButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .customStyle(.buttonText, .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
