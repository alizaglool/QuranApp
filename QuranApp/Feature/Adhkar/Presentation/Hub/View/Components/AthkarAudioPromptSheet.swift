//
//  AthkarAudioPromptSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import SwiftUI
import Core

struct AthkarAudioPromptSheet: View {

    @StateObject private var viewModel: AthkarAudioPromptViewModel

    let onReadWithoutAudio: () -> Void

    init(pack: AthkarPack, onReadWithoutAudio: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AthkarAudioPromptViewModel(pack: pack))
        self.onReadWithoutAudio = onReadWithoutAudio
    }

    var body: some View {
        card
            .padding(.horizontal, .big)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(Color.background)
            .appDirection()
    }
}

// MARK: - Layout

private extension AthkarAudioPromptSheet {

    var card: some View {
        VStack(spacing: .sm) {
            icon

            Text(viewModel.title)
                .customStyle(.headline, .onSurface)
                .multilineTextAlignment(.center)

            Text(viewModel.detail)
                .customStyle(.caption1, .onSurfaceVariant)
                .multilineTextAlignment(.center)

            if !viewModel.message.isEmpty {
                Text(viewModel.message)
                    .customStyle(.bodySmall, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, .xxSm)
            }

            if let progress = viewModel.progress {
                progressTrack(progress)
            }

            if viewModel.isInstalling {
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding(.top, .xSm)
            } else if viewModel.isActionVisible {
                actionButton
            }

            if viewModel.isSecondaryVisible {
                secondaryButton
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .xBig)
        .frame(maxWidth: .infinity)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }

    var icon: some View {
        ZStack {
            Circle()
                .fill(ColorStyle.quickAccentAdhkar.color.opacity(0.12))

            Image(systemName: viewModel.iconName)
                .font(.system(size: 24, weight: .medium))
                .customForeground(.quickAccentAdhkar)
        }
        .frame(width: 56, height: 56)
        .padding(.bottom, .xxSm)
    }

    func progressTrack(_ progress: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.25))

                Capsule()
                    .fill(ColorStyle.quickAccentAdhkar.color)
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: 6)
        .padding(.top, .xSm)
        .animation(.easeInOut(duration: 0.2), value: progress)
    }

    var actionButton: some View {
        Button(action: viewModel.onActionTapped) {
            Text(viewModel.actionTitle)
                .customStyle(.buttonText, .onPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .background(Capsule().fill(ColorStyle.primary.color))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isActionEnabled)
        .opacity(viewModel.isActionEnabled ? 1 : 0.45)
        .padding(.top, .xSm)
    }

    var secondaryButton: some View {
        Button(action: onReadWithoutAudio) {
            Text(viewModel.secondaryTitle)
                .customStyle(.buttonText, .onSurfaceVariant)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
