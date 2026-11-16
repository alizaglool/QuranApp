//
//  KhatmahSettingRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahSettingRow<Accessory: View>: View {

    let icon: String
    let accent: ColorStyle
    let title: String
    var detail: String?
    var action: (() -> Void)?
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        if let action {
            Button(action: action) {
                rowContent
            }
            .buttonStyle(SettingsRowButtonStyle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
            .accessibilityAddTraits(.isButton)
        } else {
            rowContent
                .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Parts

private extension KhatmahSettingRow {

    var rowContent: some View {
        HStack(spacing: .sm) {
            iconTile

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .customStyle(.kitab(size: 16, bold: false), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .customStyle(.kitab(size: 13, bold: false), .onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }

            Spacer(minLength: 0)

            accessory()
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .contentShape(Rectangle())
    }

    var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerMd, style: .continuous)
                .fill(accent.color.opacity(0.14))

            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .customForeground(accent)
        }
        .frame(width: 40, height: 40)
    }

    var accessibilityText: String {
        guard let detail, !detail.isEmpty else { return title }
        return "\(title), \(detail)"
    }
}
