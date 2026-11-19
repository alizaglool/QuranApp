//
//  PrayerScheduleWidget.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import WidgetKit

struct PrayerScheduleWidget: Widget {

    static let kind = "PrayerScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: PrayerScheduleWidget.kind,
                            provider: PrayerWidgetTimelineProvider()) { entry in
            PrayerScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName(PrayerWidgetGalleryText.text(\.scheduleGalleryTitle))
        .description(PrayerWidgetGalleryText.text(\.scheduleGalleryDescription))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct PrayerScheduleWidgetView: View {

    let entry: PrayerWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .prayerWidgetEnvironment(entry.snapshot)
            .prayerWidgetContainerBackground(family)
    }
}

// MARK: - Layout

private extension PrayerScheduleWidgetView {

    @ViewBuilder
    var content: some View {
        if entry.scheduleSlots.isEmpty {
            PrayerWidgetUnavailableView(message: entry.snapshot.labels.unavailableMessage,
                                        family: family)
        } else {
            VStack(alignment: .leading, spacing: isLarge ? 8 : 5) {
                header

                ForEach(entry.scheduleSlots) { slot in
                    row(slot)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    var isLarge: Bool { family == .systemLarge }

    var header: some View {
        HStack(spacing: 6) {
            Text(entry.snapshot.labels.scheduleTitle)
                .font(.system(size: isLarge ? 15 : 12, weight: .semibold))
                .foregroundStyle(PrayerWidgetPalette.title)
                .lineLimit(1)

            Spacer(minLength: 4)

            Text(locationOrDate)
                .font(.system(size: isLarge ? 12 : 10, weight: .regular))
                .foregroundStyle(PrayerWidgetPalette.caption)
                .lineLimit(1)
        }
        .padding(.bottom, isLarge ? 2 : 0)
        .accessibilityElement(children: .combine)
    }

    var locationOrDate: String {
        entry.snapshot.locationTitle.isEmpty ? entry.hijriDateText : entry.snapshot.locationTitle
    }

    func row(_ slot: PrayerWidgetSlot) -> some View {
        HStack(spacing: 8) {
            Image(systemName: slot.iconName)
                .font(.system(size: isLarge ? 13 : 11, weight: .regular))
                .foregroundStyle(isNext(slot) ? PrayerWidgetPalette.accent : PrayerWidgetPalette.caption)
                .frame(width: isLarge ? 18 : 15)

            Text(slot.title)
                .font(.system(size: isLarge ? 15 : 12,
                              weight: isNext(slot) ? .semibold : .regular))
                .foregroundStyle(PrayerWidgetPalette.title)
                .lineLimit(1)

            Spacer(minLength: 6)

            Text(slot.timeText)
                .font(.system(size: isLarge ? 15 : 12,
                              weight: isNext(slot) ? .semibold : .regular))
                .foregroundStyle(isNext(slot) ? PrayerWidgetPalette.accent : PrayerWidgetPalette.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, isLarge ? 10 : 7)
        .padding(.vertical, isLarge ? 6 : 3)
        .background(rowBackground(slot))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(slot.title) \(slot.timeText)")
    }

    @ViewBuilder
    func rowBackground(_ slot: PrayerWidgetSlot) -> some View {
        if isNext(slot) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(PrayerWidgetPalette.highlight)
        } else {
            Color.clear
        }
    }

    func isNext(_ slot: PrayerWidgetSlot) -> Bool {
        slot.id == entry.nextSlot?.id
    }
}
