//
//  AthkarReaderSettingsSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarReaderSettingsSheet: View {

    @ObservedObject var viewModel: AthkarReaderViewModel

    private var translationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showsTranslation },
            set: { viewModel.setShowsTranslation($0) }
        )
    }

    var body: some View {
        VStack(spacing: .big) {
            handle

            Text(viewModel.settingsTitle)
                .customStyle(.heading3, .onSurface)

            VStack(spacing: .sm) {
                layoutRow

                textSizeRow

                if viewModel.hasTranslatableContent {
                    translationRow
                }
            }

            startOverButton

            doneButton
        }
        .padding(.horizontal, .big)
        .padding(.bottom, .xBig)
        .frame(maxWidth: .infinity)
        .background(Color.background.ignoresSafeArea())
        .presentationDetents([.height(440)])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Rows

private extension AthkarReaderSettingsSheet {

    var handle: some View {
        Capsule()
            .fill(ColorStyle.outlineVariant.color)
            .frame(width: 40, height: 4)
            .padding(.top, .sm)
    }

    var layoutRow: some View {
        HStack(spacing: .sm) {
            Text(viewModel.layoutTitle)
                .customStyle(.subheadline, .onSurface)

            Spacer(minLength: .sm)

            layoutOption(
                title: viewModel.layoutPagesTitle,
                systemName: "rectangle.on.rectangle",
                layout: .horizontal
            )

            layoutOption(
                title: viewModel.layoutListTitle,
                systemName: "list.bullet.rectangle",
                layout: .vertical
            )
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .background(rowBackground)
    }

    func layoutOption(title: String, systemName: String, layout: AthkarReaderLayout) -> some View {
        let isSelected = viewModel.layout == layout

        return Button {
            viewModel.setLayout(layout)
        } label: {
            HStack(spacing: .xxSm) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .semibold))

                Text(title)
                    .customStyle(.caption1)
            }
            .customForeground(isSelected ? .onPrimary : .onSurfaceVariant)
            .padding(.horizontal, .sm)
            .frame(height: 34)
            .background(
                Capsule()
                    .fill(isSelected ? ColorStyle.primary.color : Color.surfaceContainerLow)
                    .overlay(Capsule().stroke(ColorStyle.cardBorder.color, lineWidth: isSelected ? 0 : 1))
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    var textSizeRow: some View {
        HStack(spacing: .sm) {
            Text(viewModel.textSizeTitle)
                .customStyle(.subheadline, .onSurface)

            Spacer(minLength: .sm)

            stepperButton(systemName: "textformat.size.smaller", enabled: viewModel.settings.canShrink) {
                viewModel.shrinkText()
            }

            Text(viewModel.textSizeValue)
                .customStyle(.subheadline, .onSurfaceVariant)
                .monospacedDigit()
                .frame(minWidth: 56)

            stepperButton(systemName: "textformat.size.larger", enabled: viewModel.settings.canGrow) {
                viewModel.growText()
            }
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .background(rowBackground)
    }

    var translationRow: some View {
        Toggle(isOn: translationBinding) {
            Text(viewModel.showTranslationTitle)
                .customStyle(.subheadline, .onSurface)
        }
        .tint(ColorStyle.primary.color)
        .padding(.horizontal, .md)
        .padding(.vertical, .xSm)
        .background(rowBackground)
    }

    var startOverButton: some View {
        Button(action: viewModel.startOver) {
            HStack(spacing: .xSm) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .semibold))

                Text(viewModel.startOverTitle)
                    .customStyle(.buttonText)
            }
            .customForeground(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, .md)
            .background(
                RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                    .fill(ColorStyle.washSecondarySubtle.color)
            )
        }
        .buttonStyle(.plain)
    }

    var doneButton: some View {
        Button(action: viewModel.closeSettings) {
            Text(viewModel.doneTitle)
                .customStyle(.buttonText, .onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .md)
                .background(
                    RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                        .fill(ColorStyle.primary.color)
                )
        }
        .buttonStyle(.plain)
    }

    func stepperButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .medium))
                .customForeground(enabled ? .onSurface : .outline)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.surfaceContainerLow)
                        .overlay(Circle().stroke(ColorStyle.cardBorder.color, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    var rowBackground: some View {
        RoundedRectangle(cornerRadius: .cornerXl, style: .continuous)
            .fill(Color.cardSurface)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXl, style: .continuous)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
    }
}
