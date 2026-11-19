//
//  NextPrayerWidget.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import WidgetKit

struct NextPrayerWidget: Widget {

    static let kind = "NextPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: NextPrayerWidget.kind,
                            provider: PrayerWidgetTimelineProvider()) { entry in
            NextPrayerWidgetView(entry: entry)
        }
        .configurationDisplayName(PrayerWidgetGalleryText.text(\.nextPrayerGalleryTitle))
        .description(PrayerWidgetGalleryText.text(\.nextPrayerGalleryDescription))
        .supportedFamilies([.systemSmall,
                            .systemMedium,
                            .accessoryCircular,
                            .accessoryRectangular,
                            .accessoryInline])
    }
}

struct NextPrayerWidgetView: View {

    let entry: PrayerWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .prayerWidgetEnvironment(entry.snapshot)
            .prayerWidgetContainerBackground(family)
    }
}

// MARK: - Layout

private extension NextPrayerWidgetView {

    @ViewBuilder
    var content: some View {
        if let slot = entry.nextSlot {
            switch family {
            case .accessoryInline:
                inlineContent(slot)
            case .accessoryCircular:
                circularContent(slot)
            case .accessoryRectangular:
                rectangularContent(slot)
            case .systemMedium:
                mediumContent(slot)
            default:
                smallContent(slot)
            }
        } else {
            PrayerWidgetUnavailableView(message: entry.snapshot.labels.unavailableMessage,
                                        family: family)
        }
    }

    func smallContent(_ slot: PrayerWidgetSlot) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(slot)

            Spacer(minLength: 2)

            Text(slot.title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PrayerWidgetPalette.title)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(slot.timeText)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(PrayerWidgetPalette.accent)
                .lineLimit(1)

            Spacer(minLength: 2)

            countdown
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(slot))
    }

    func mediumContent(_ slot: PrayerWidgetSlot) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                header(slot)

                Spacer(minLength: 2)

                Text(slot.title)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(PrayerWidgetPalette.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(slot.timeText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PrayerWidgetPalette.accent)
                    .lineLimit(1)

                Spacer(minLength: 2)

                countdown
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            upcomingColumn
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(slot))
    }

    func rectangularContent(_ slot: PrayerWidgetSlot) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: slot.iconName)
                    .font(.system(size: 11, weight: .medium))

                Text(slot.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }

            Text(slot.timeText)
                .font(.system(size: 12, weight: .regular))
                .lineLimit(1)

            Text(entry.remainingText)
                .font(.system(size: 11, weight: .regular))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(slot))
    }

    func circularContent(_ slot: PrayerWidgetSlot) -> some View {
        VStack(spacing: 0) {
            Image(systemName: slot.iconName)
                .font(.system(size: 12, weight: .medium))

            Text(slot.timeText)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(slot))
    }

    func inlineContent(_ slot: PrayerWidgetSlot) -> some View {
        Text("\(slot.title) \(slot.timeText)")
            .accessibilityLabel(accessibilityLabel(slot))
    }
}

// MARK: - Components

private extension NextPrayerWidgetView {

    func header(_ slot: PrayerWidgetSlot) -> some View {
        HStack(spacing: 4) {
            Image(systemName: slot.iconName)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PrayerWidgetPalette.accent)

            Text(entry.snapshot.labels.nextPrayerTitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(PrayerWidgetPalette.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    var countdown: some View {
        Text(entry.remainingText)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(PrayerWidgetPalette.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    var upcomingColumn: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(entry.upcomingSlots.dropFirst().prefix(3))) { slot in
                HStack(spacing: 6) {
                    Image(systemName: slot.iconName)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(PrayerWidgetPalette.accent)
                        .frame(width: 13)

                    Text(slot.title)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(PrayerWidgetPalette.title)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(slot.timeText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(PrayerWidgetPalette.caption)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHidden(true)
    }

    func accessibilityLabel(_ slot: PrayerWidgetSlot) -> String {
        "\(entry.snapshot.labels.nextPrayerTitle) \(slot.title) \(slot.timeText) \(entry.remainingText)"
    }
}
