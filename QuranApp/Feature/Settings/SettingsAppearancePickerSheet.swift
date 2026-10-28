//
//  SettingsAppearancePickerSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct SettingsAppearancePickerSheet: View {

    let title: String
    let options: [SettingsOptionItem]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: .big) {
            SettingsSheetGrabber()

            Text(title)
                .customStyle(.kitab(size: 18, bold: true), .onSurface)

            HStack(spacing: .sm) {
                ForEach(options) { option in
                    appearanceTile(for: option)
                }
            }
            .padding(.horizontal, .md)

            Spacer(minLength: 0)
        }
        .padding(.top, .sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Parts

private extension SettingsAppearancePickerSheet {

    func appearanceTile(for option: SettingsOptionItem) -> some View {
        Button {
            onSelect(option.id)
        } label: {
            VStack(spacing: .xSm) {
                Image(systemName: option.iconName ?? "circle")
                    .font(.system(size: 24, weight: .medium))
                    .customForeground(option.accent)
                    .frame(height: 30)

                Text(option.title)
                    .customStyle(.kitab(size: 13, bold: option.isSelected), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .md)
            .background(Color.cardSurface)
            .customCornerRadius(.cornerLg)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerLg)
                    .stroke(option.isSelected ? ColorStyle.primary.color : ColorStyle.cardBorder.color,
                            lineWidth: option.isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(option.isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Shared Grabber

struct SettingsSheetGrabber: View {

    var body: some View {
        Capsule()
            .fill(ColorStyle.outlineVariant.color)
            .frame(width: 40, height: 5)
    }
}
