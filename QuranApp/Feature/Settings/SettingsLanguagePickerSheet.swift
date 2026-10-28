//
//  SettingsLanguagePickerSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct SettingsLanguagePickerSheet: View {

    let title: String
    let options: [SettingsOptionItem]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: .big) {
            SettingsSheetGrabber()

            Text(title)
                .customStyle(.kitab(size: 18, bold: true), .onSurface)

            VStack(spacing: .no) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    languageRow(for: option)

                    if index < options.count - 1 {
                        Rectangle()
                            .fill(ColorStyle.outlineVariant.color)
                            .frame(height: 0.5)
                            .padding(.horizontal, .md)
                    }
                }
            }
            .background(Color.cardSurface)
            .customCornerRadius(.cornerLg)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerLg)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
            .padding(.horizontal, .md)

            Spacer(minLength: 0)
        }
        .padding(.top, .sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Parts

private extension SettingsLanguagePickerSheet {

    func languageRow(for option: SettingsOptionItem) -> some View {
        Button {
            onSelect(option.id)
        } label: {
            HStack(spacing: .sm) {
                Text(option.title)
                    .customStyle(.kitab(size: 16, bold: option.isSelected), .onSurface)

                Spacer(minLength: 0)

                if option.isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .customForeground(.primary)
                }
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .md)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(option.isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
