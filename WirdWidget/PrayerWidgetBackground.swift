//
//  PrayerWidgetBackground.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import WidgetKit

extension View {

    @ViewBuilder
    func prayerWidgetContainerBackground(_ family: WidgetFamily) -> some View {
        switch family {
        case .accessoryCircular:
            containerBackground(for: .widget) { AccessoryWidgetBackground() }
        case .accessoryRectangular, .accessoryInline:
            containerBackground(for: .widget) { Color.clear }
        default:
            containerBackground(for: .widget) {
                Rectangle()
                    .fill(.fill.tertiary)
                    .overlay(
                        LinearGradient(colors: [PrayerWidgetPalette.accent.opacity(0.16), .clear],
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
            }
        }
    }
}
