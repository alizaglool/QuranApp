//
//  PrayerWidgetUnavailableView.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import WidgetKit

struct PrayerWidgetUnavailableView: View {

    let message: String
    let family: WidgetFamily

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(message)
    }
}

// MARK: - Layout

private extension PrayerWidgetUnavailableView {

    @ViewBuilder
    var content: some View {
        switch family {
        case .accessoryInline:
            Image(systemName: "moon.stars")
        case .accessoryCircular:
            Image(systemName: "moon.stars")
                .font(.system(size: 18, weight: .medium))
        default:
            VStack(spacing: 8) {
                Image(systemName: "moon.stars")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(PrayerWidgetPalette.accent)

                if !message.isEmpty {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(PrayerWidgetPalette.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
