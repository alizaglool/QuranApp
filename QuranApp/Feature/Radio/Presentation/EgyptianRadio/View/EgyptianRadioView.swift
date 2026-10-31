//
//  EgyptianRadioView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

// MARK: - EgyptianRadioView

struct EgyptianRadioView: View {

    @StateObject private var viewModel: EgyptianRadioViewModel
    @ObservedObject private var player = RadioPlayer.shared
    @ObservedObject private var reachability = NetworkReachability.shared

    init(coordinator: any RadioCoordinating) {
        _viewModel = StateObject(wrappedValue: EgyptianRadioViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension EgyptianRadioView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(spacing: .big) {
                    stationCard
                    controls

                    if !reachability.isOnline {
                        banner(icon: "wifi.slash", text: viewModel.offlineBannerText)
                    }

                    if let message = viewModel.failureMessage {
                        banner(icon: "exclamationmark.triangle.fill", text: message)
                    }

                    liveNote
                }
                .padding(.horizontal, .big)
                .padding(.top, .sm)
                .padding(.bottom, .xxxBig)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .animation(.easeInOut(duration: 0.22), value: viewModel.isPlaying)
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.screenTitle)
                    .customStyle(.heading3, .onSurface)
                Text(viewModel.screenSubtitle)
                    .customStyle(.caption1, .subtitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Station

private extension EgyptianRadioView {

    var stationCard: some View {
        VStack(spacing: .md) {
            artwork

            if viewModel.isPlaying {
                liveBadge
            }

            Text(viewModel.stationName)
                .customStyle(.headline, .onSurface)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.statusText)
                .customStyle(.caption1, .subtitle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .xBig)
        .padding(.horizontal, .md)
        .background {
            RoundedRectangle(cornerRadius: .cornerXxl)
                .fill(Color.cardSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        }
    }

    var artwork: some View {
        ZStack {
            Circle()
                .fill(ColorStyle.quickAccentRadio.color.opacity(0.14))
                .frame(width: 148, height: 148)

            Circle()
                .fill(ColorStyle.quickAccentRadio.color.opacity(0.18))
                .frame(width: 104, height: 104)

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 44, weight: .regular))
                .customForeground(.quickAccentRadio)
        }
        .overlay(alignment: .center) {
            if viewModel.isConnecting {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(ColorStyle.quickAccentRadio.color)
                    .offset(y: 54)
            }
        }
    }

    var liveBadge: some View {
        HStack(spacing: 5) {
            Circle()
                .customFill(.onPrimary)
                .frame(width: 6, height: 6)

            Text(viewModel.liveBadgeTitle)
                .customStyle(.caption2, .onPrimary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .customFill(.error)
        }
    }
}

// MARK: - Controls

private extension EgyptianRadioView {

    var controls: some View {
        HStack(spacing: .sm) {
            Button(action: viewModel.onPlaybackToggled) {
                HStack(spacing: .xSm) {
                    Image(systemName: viewModel.toggleActionIcon)
                        .font(.system(size: 15, weight: .semibold))

                    Text(viewModel.toggleActionTitle)
                        .customStyle(.buttonText, .onPrimary)
                }
                .customForeground(.onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .background {
                    RoundedRectangle(cornerRadius: .cornerMd)
                        .customFill(.quickAccentRadio)
                }
            }
            .buttonStyle(.plain)

            if viewModel.isStopAvailable {
                Button(action: viewModel.onStopTapped) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .customForeground(.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                        .background {
                            RoundedRectangle(cornerRadius: .cornerMd)
                                .customFill(.surfaceContainerHigh)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.stopActionTitle)
            }
        }
    }

    var liveNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle")
                .font(.system(size: 14))
                .customForeground(.subtitle)

            Text(viewModel.liveNoteText)
                .customStyle(.caption2, .subtitle)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    func banner(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .customForeground(.error)

            Text(text)
                .customStyle(.caption1, .onSurface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: .cornerMd)
                .fill(ColorStyle.error.color.opacity(0.12))
        }
    }
}
