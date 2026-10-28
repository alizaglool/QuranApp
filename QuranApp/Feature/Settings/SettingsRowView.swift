//
//  SettingsRowView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct SettingsRowView: View {

    let item: SettingsRowItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                iconTile

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .customStyle(.kitab(size: 16, bold: false), .onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .customStyle(.kitab(size: 13, bold: false), .onSurfaceVariant)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .customForeground(.outline)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Parts

private extension SettingsRowView {

    var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerMd, style: .continuous)
                .fill(item.iconAccent.color.opacity(0.14))

            Image(systemName: item.iconName)
                .font(.system(size: 18, weight: .medium))
                .customForeground(item.iconAccent)
        }
        .frame(width: 40, height: 40)
    }

    var accessibilityText: String {
        item.subtitle.isEmpty ? item.title : "\(item.title), \(item.subtitle)"
    }
}

// MARK: - Press Feedback

struct SettingsRowButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? ColorStyle.onSurface.color.opacity(0.06) : .clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
