//
//  AdhanVoiceView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 02/11/2026.
//

import Core
import SwiftUI

struct AdhanVoiceView: View {

    @StateObject private var viewModel: AdhanVoiceViewModel

    init(coordinator: any AdhanVoiceCoordinating, viewModel: AdhanVoiceViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? AdhanVoiceViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Adhan Voice Layout

private extension AdhanVoiceView {

    var mainContent: some View {
        VStack(spacing: .no) {
            navBar

            if let message = viewModel.playbackFailureMessage {
                failureBanner(message)
                    .padding(.horizontal, .big)
                    .padding(.bottom, .xSm)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    if viewModel.items.isEmpty {
                        unavailableCard
                    } else {
                        voiceSection
                        fullAdhanSection
                    }

                    Text(viewModel.footer)
                        .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, .xSm)
                }
                .padding(.horizontal, .big)
                .padding(.top, .xSm)
                .padding(.bottom, .xxxBig)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .animation(.easeInOut(duration: 0.2), value: viewModel.playbackFailureMessage)
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            Text(viewModel.screenTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    var voiceSection: some View {
        section(viewModel.voiceSectionTitle) {
            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                AdhanVoiceRow(item: item,
                              onSelect: { viewModel.onVoiceTapped(item.id) },
                              onPreview: { viewModel.onPreviewTapped(item.id) })

                if index < viewModel.items.count - 1 {
                    rowDivider
                }
            }
        }
    }

    var fullAdhanSection: some View {
        section(viewModel.fullAdhanSectionTitle) {
            AdhanFullPlaybackRow(title: viewModel.fullAdhanRowTitle,
                                 caption: viewModel.fullAdhanRowCaption,
                                 isPlaying: viewModel.isFullAdhanPlaying,
                                 isEnabled: viewModel.isFullAdhanAvailable,
                                 action: viewModel.onFullAdhanTapped)
        }
    }

    var unavailableCard: some View {
        card {
            Text(viewModel.unavailableMessage)
                .customStyle(.kitab(size: 14, bold: false), .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.md)
        }
    }

    func failureBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: .xSm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold))
                .customForeground(.error)

            Text(message)
                .customStyle(.kitab(size: 13, bold: false), .error)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.md)
        .background(ColorStyle.error.color.opacity(0.1))
        .customCornerRadius(.cornerXl)
    }

    func section<Content: View>(_ title: String,
                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(title)
                .customStyle(.kitab(size: 13, bold: true), .onSurfaceVariant)
                .padding(.horizontal, .xSm)

            card(content: content)
        }
    }

    func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: .no) {
            content()
        }
        .background(Color.cardSurface)
        .customCornerRadius(.cornerXl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }

    var rowDivider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color)
            .frame(height: 0.5)
            .padding(.leading, 68)
    }
}

// MARK: - Adhan Voice Rows

struct AdhanVoiceRow: View {

    let item: AdhanVoiceItem
    let onSelect: () -> Void
    let onPreview: () -> Void

    var body: some View {
        HStack(spacing: .no) {
            Button(action: onSelect) {
                HStack(spacing: .sm) {
                    PrayerNotificationIconTile(iconName: item.isSelected
                                                   ? "speaker.wave.2.fill"
                                                   : "speaker.wave.2")

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .customStyle(.kitab(size: 16, bold: item.isSelected), .onSurface)

                        Text(item.caption)
                            .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: .xSm)

                    if item.isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .customForeground(.primary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, .md)
                .padding(.vertical, .sm)
            }
            .buttonStyle(SettingsRowButtonStyle())
            .accessibilityAddTraits(item.isSelected ? [.isButton, .isSelected] : .isButton)

            previewButton
                .padding(.horizontal, .md)
        }
    }

    var previewButton: some View {
        Button(action: onPreview) {
            Image(systemName: item.isPreviewPlaying ? "stop.fill" : "play.fill")
                .font(.system(size: 12, weight: .semibold))
                .customForeground(.primary)
                .frame(width: 32, height: 32)
                .background(ColorStyle.primary.color.opacity(0.12))
                .customCornerRadius(.cornerMd)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.previewAccessibilityLabel))
    }
}

struct AdhanFullPlaybackRow: View {

    let title: String
    let caption: String
    let isPlaying: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                PrayerNotificationIconTile(iconName: "waveform")

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .customStyle(.kitab(size: 16, bold: false), .onSurface)

                    if !caption.isEmpty {
                        Text(caption)
                            .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: .xSm)

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
                    .background(ColorStyle.primary.color.opacity(0.12))
                    .customCornerRadius(.cornerMd)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
        }
        .buttonStyle(SettingsRowButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}
