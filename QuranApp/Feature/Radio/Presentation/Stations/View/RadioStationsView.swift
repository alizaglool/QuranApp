//
//  RadioStationsView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core

// MARK: - RadioStationsView

struct RadioStationsView: View {

    @StateObject private var viewModel: RadioStationsViewModel
    @ObservedObject private var player = RadioPlayer.shared
    @ObservedObject private var offline = OfflineRadioService.shared
    @ObservedObject private var reachability = NetworkReachability.shared

    init(coordinator: any RadioCoordinating) {
        _viewModel = StateObject(wrappedValue: RadioStationsViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension RadioStationsView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            content
            if viewModel.isPlayerVisible {
                RadioMiniPlayer(
                    title: viewModel.playerTitle,
                    subtitle: viewModel.playerSubtitle,
                    isPlaying: viewModel.isPlayerPlaying,
                    isLoading: viewModel.isPlayerLoading,
                    toggleLabel: viewModel.playerToggleLabel,
                    stopLabel: viewModel.playerStopLabel,
                    onToggle: viewModel.toggleCurrent,
                    onStop: viewModel.stopCurrent
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .animation(.easeInOut(duration: 0.22), value: viewModel.isPlayerVisible)
        .sheet(isPresented: $viewModel.showReciterLibrary) {
            NavigationStack {
                ReciterLibraryView()
                    .environmentObject(AudioEngine.library)
            }
            .presentationDragIndicator(.visible)
        }
    }

    var navBar: some View {
        Text(viewModel.title)
            .customStyle(.subheadline, .onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .big)
            .padding(.vertical, .sm)
    }

    @ViewBuilder
    var content: some View {
        if viewModel.isLoadingCatalog {
            skeletonList
        } else if viewModel.catalogFailed, !viewModel.hasAnyContent {
            errorView
        } else {
            stationList
        }
    }
}

// MARK: - Header

private extension RadioStationsView {

    var heroSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(viewModel.title)
                .font(.system(size: 34, weight: .bold))
                .customForeground(.onSurface)
            Text(viewModel.subtitle)
                .customStyle(.bodySmall, .subtitle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .big)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    var offlineBanner: some View {
        if !reachability.isOnline {
            banner(icon: "wifi.slash", text: viewModel.offlineBanner)
        }
    }

    @ViewBuilder
    var failureBanner: some View {
        if let message = viewModel.failureMessage {
            banner(icon: "exclamationmark.triangle.fill", text: message)
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
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorStyle.error.color.opacity(0.12))
        )
        .padding(.horizontal, .big)
        .padding(.bottom, 16)
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .customForeground(.subtitle)
                .font(.system(size: 15))
            TextField(viewModel.searchPlaceholder, text: $viewModel.searchText)
                .font(.system(size: 15))
                .customForeground(.onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .customFill(.surface)
        )
        .padding(.horizontal, .big)
        .padding(.bottom, 16)
    }

    func sectionTitle(_ title: String, hint: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SectionHeader(title: title)
            if let hint {
                Text(hint)
                    .customStyle(.caption1, .subtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .big)
        .padding(.bottom, 12)
    }
}

// MARK: - List

private extension RadioStationsView {

    var stationList: some View {
        NoIndicatorsScrollView {
            VStack(spacing: 0) {
                heroSection
                offlineBanner
                failureBanner
                searchBar

                if viewModel.hasVisibleContent {
                    liveSection
                    stationsSection
                    downloadedSection
                } else if viewModel.hasSearchQuery {
                    emptyFilterState
                } else {
                    emptyOfflineState
                }
            }
            .padding(.bottom, 32)
        }
    }

    @ViewBuilder
    var liveSection: some View {
        if !viewModel.liveStations.isEmpty {
            sectionTitle(
                viewModel.liveSectionTitle,
                hint: viewModel.isOnline ? nil : viewModel.needsConnectionText
            )
            LazyVStack(spacing: 14) {
                ForEach(viewModel.liveStations) { station in
                    LiveChannelCard(
                        title: viewModel.name(for: station),
                        thumbnail: station.thumbnail,
                        badge: viewModel.liveBadge,
                        isEnabled: viewModel.isEnabled(station),
                        onTap: { viewModel.openLiveChannel(station) }
                    )
                }
            }
            .padding(.horizontal, .big)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    var stationsSection: some View {
        if !viewModel.audioStations.isEmpty {
            sectionTitle(viewModel.stationsSectionTitle)
            LazyVStack(spacing: 10) {
                ForEach(viewModel.audioStations) { station in
                    RadioStationRow(
                        title: viewModel.name(for: station),
                        detail: nil,
                        badge: nil,
                        isCurrent: viewModel.isCurrent(station),
                        isPlaying: viewModel.isCurrent(station) && player.isPlaying,
                        isLoading: viewModel.isCurrent(station) && player.isLoading,
                        isEnabled: viewModel.isEnabled(station),
                        onTap: { viewModel.play(station) }
                    )
                }
            }
            .padding(.horizontal, .big)
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    var downloadedSection: some View {
        if !viewModel.filteredOfflineStations.isEmpty {
            sectionTitle(viewModel.downloadedSectionTitle)
            LazyVStack(spacing: 10) {
                ForEach(viewModel.filteredOfflineStations) { station in
                    RadioStationRow(
                        title: viewModel.name(for: station),
                        detail: viewModel.detail(for: station),
                        badge: nil,
                        isCurrent: viewModel.isCurrent(station),
                        isPlaying: viewModel.isCurrent(station) && offline.isPlaying,
                        isLoading: viewModel.isCurrent(station) && offline.isLoading,
                        isEnabled: true,
                        onTap: { viewModel.play(station) }
                    )
                }
            }
            .padding(.horizontal, .big)
        } else if !viewModel.hasSearchQuery {
            sectionTitle(viewModel.downloadedSectionTitle)
            downloadsPrompt
        }
    }

    var downloadsPrompt: some View {
        Button {
            viewModel.openReciterLibrary()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 20))
                    .customForeground(.primary)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(ColorStyle.primary.color.opacity(0.12))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.downloadActionTitle)
                        .customStyle(.subheadline, .onSurface)
                    Text(viewModel.emptyOfflineMessage)
                        .customStyle(.caption1, .subtitle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .customForeground(.subtitle)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .customFill(.surface)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .big)
    }
}

// MARK: - States

private extension RadioStationsView {

    var skeletonList: some View {
        NoIndicatorsScrollView {
            VStack(spacing: 0) {
                heroSection
                searchBar
                LazyVStack(spacing: 10) {
                    ForEach(0..<8, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 14)
                            .customFill(.container)
                            .frame(height: 72)
                            .withShimmerOverlay(cornerRadius: 14)
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, 4)
                .redacted(reason: .placeholder)
            }
            .padding(.bottom, 32)
        }
    }

    var emptyFilterState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .customForeground(.subtitle)
                .padding(.top, 60)
            Text(viewModel.noResultsText)
                .customStyle(.bodySmall, .subtitle)
        }
        .frame(maxWidth: .infinity)
    }

    var emptyOfflineState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 42))
                .customForeground(.subtitle)
                .padding(.top, 50)
            Text(viewModel.emptyOfflineTitle)
                .customStyle(.subheadline, .onSurface)
                .multilineTextAlignment(.center)
            Text(viewModel.emptyOfflineMessage)
                .customStyle(.bodySmall, .subtitle)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Button {
                viewModel.openReciterLibrary()
            } label: {
                Text(viewModel.downloadActionTitle)
                    .customStyle(.subheadline, .onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .customFill(.primary)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
    }

    var errorView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .customForeground(.subtitle)
            Text(viewModel.offlineBanner)
                .customStyle(.bodySmall, .subtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                viewModel.retry()
            } label: {
                Text(viewModel.retryTitle)
                    .customStyle(.subheadline, .onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .customFill(.primary)
                    )
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
