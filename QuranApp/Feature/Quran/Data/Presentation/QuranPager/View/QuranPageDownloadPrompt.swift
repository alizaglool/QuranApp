//
//  QuranPageDownloadPrompt.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import SwiftUI
import Core

struct QuranPageDownloadPrompt: View {

    @StateObject private var viewModel: QuranPageDownloadPromptViewModel

    init(page: Int) {
        _viewModel = StateObject(wrappedValue: QuranPageDownloadPromptViewModel(page: page))
    }

    var body: some View {
        card
            .frame(maxWidth: 340)
            .padding(.horizontal, .big)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { viewModel.onAppear() }
    }
}

// MARK: - Layout

private extension QuranPageDownloadPrompt {

    var card: some View {
        VStack(spacing: .sm) {
            icon

            Text(viewModel.title)
                .customStyle(.headline, .onSurface)
                .multilineTextAlignment(.center)

            if !viewModel.detail.isEmpty {
                Text(viewModel.detail)
                    .customStyle(.caption1, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }

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
                .fill(ColorStyle.quickAccentQuran.color.opacity(0.12))

            Image(systemName: viewModel.iconName)
                .font(.system(size: 24, weight: .medium))
                .customForeground(.quickAccentQuran)
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
                    .fill(ColorStyle.quickAccentQuran.color)
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: 6)
        .padding(.top, .xSm)
        .animation(.easeInOut(duration: 0.2), value: progress)
    }

    var actionButton: some View {
        Button(action: viewModel.onActionTapped) {
            HStack(spacing: .xSm) {
                if viewModel.isRefreshingCatalog {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(ColorStyle.onPrimary.color)
                }

                Text(viewModel.actionTitle)
                    .customStyle(.buttonText, .onPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .sm)
            .background(Capsule().fill(ColorStyle.primary.color))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, .xSm)
    }
}
