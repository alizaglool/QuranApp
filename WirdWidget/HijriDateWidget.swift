//
//  HijriDateWidget.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import WidgetKit

struct HijriDateWidget: Widget {

    static let kind = "HijriDateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: HijriDateWidget.kind,
                            provider: PrayerWidgetTimelineProvider()) { entry in
            HijriDateWidgetView(entry: entry)
        }
        .configurationDisplayName(PrayerWidgetGalleryText.text(\.dateGalleryTitle))
        .description(PrayerWidgetGalleryText.text(\.dateGalleryDescription))
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct HijriDateWidgetView: View {

    let entry: PrayerWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .prayerWidgetEnvironment(entry.snapshot)
            .prayerWidgetContainerBackground(family)
    }
}

// MARK: - Layout

private extension HijriDateWidgetView {

    @ViewBuilder
    var content: some View {
        if entry.hijriDateText.isEmpty {
            PrayerWidgetUnavailableView(message: entry.snapshot.labels.unavailableMessage,
                                        family: family)
        } else if family == .accessoryRectangular {
            rectangularContent
        } else {
            smallContent
        }
    }

    var smallContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(PrayerWidgetPalette.accent)

            Spacer(minLength: 4)

            Text(entry.hijriDateText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(PrayerWidgetPalette.title)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.gregorianDateText)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(PrayerWidgetPalette.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 4)

            if let slot = entry.nextSlot {
                Divider()
                    .overlay(PrayerWidgetPalette.separator)
                    .padding(.bottom, 4)

                HStack(spacing: 5) {
                    Image(systemName: slot.iconName)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(PrayerWidgetPalette.accent)

                    Text(slot.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(PrayerWidgetPalette.title)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Text(slot.timeText)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(PrayerWidgetPalette.caption)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    var rectangularContent: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.hijriDateText)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(entry.gregorianDateText)
                .font(.system(size: 12, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let slot = entry.nextSlot {
                Text("\(slot.title) \(slot.timeText)")
                    .font(.system(size: 11, weight: .regular))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    var accessibilityLabel: String {
        guard let slot = entry.nextSlot else {
            return "\(entry.hijriDateText) \(entry.gregorianDateText)"
        }
        return "\(entry.hijriDateText) \(entry.gregorianDateText) \(slot.title) \(slot.timeText)"
    }
}
