//
//  GlobalSearchView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct GlobalSearchView: View {

    @StateObject private var viewModel: GlobalSearchViewModel
    @FocusState private var isSearchFieldFocused: Bool

    init(coordinator: any GlobalSearchCoordinating) {
        _viewModel = StateObject(wrappedValue: GlobalSearchViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .onChange(of: viewModel.searchText) { viewModel.performSearch() }
    }
}

// MARK: - Layout

private extension GlobalSearchView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            searchField
                .padding(.bottom, .sm)

            GlobalSearchScopeChips(scopes: viewModel.scopes,
                                   selectedScope: viewModel.scope,
                                   title: viewModel.scopeTitle,
                                   onSelect: viewModel.selectScope)
                .padding(.bottom, .xSm)

            phaseContent
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .onAppear { isSearchFieldFocused = true }
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.coordinateBack) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            Text(viewModel.navigationTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    var searchField: some View {
        HStack(spacing: .xSm + 2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .customForeground(.onSurfaceVariant)

            TextField(viewModel.searchPlaceholder, text: $viewModel.searchText)
                .customStyle(.bodyMedium, .onSurface)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button(action: viewModel.clearSearch) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .customForeground(.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, .md)
        .padding(.vertical, 11)
        .background(ColorStyle.surfaceContainerLow.color)
        .cornerRadius(.cornerMd)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerMd)
                .strokeBorder(Color.outlineVariant.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}

// MARK: - Phases

private extension GlobalSearchView {

    @ViewBuilder
    var phaseContent: some View {
        switch viewModel.phase {
        case .idle:
            messageState(viewModel.promptMessage, iconName: "sparkle.magnifyingglass")
        case .tooShort:
            messageState(viewModel.statusMessage, iconName: "magnifyingglass")
        case .noResults:
            emptyResultsState
        case .running:
            loadingState
        case .results:
            resultsList
        }
    }

    var emptyResultsState: some View {
        VStack(spacing: .md) {
            messageState(viewModel.statusMessage, iconName: "magnifyingglass")

            if viewModel.isUninstalledNarrationNoticeVisible {
                uninstalledNarrationNotice
                    .padding(.horizontal, .md)
                    .padding(.bottom, .md)
            }
        }
    }

    var loadingState: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(ColorStyle.primary.color)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    func messageState(_ message: String, iconName: String) -> some View {
        VStack(spacing: .md) {
            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 34, weight: .light))
                .customForeground(.onSurfaceVariant)

            Text(message)
                .customStyle(.bodyMedium, .onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .xxBig)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Results

private extension GlobalSearchView {

    var resultsList: some View {
        NoIndicatorsScrollView {
            LazyVStack(alignment: .leading, spacing: .md) {
                ForEach(viewModel.outcome.sections) { section in
                    sectionView(section)
                }

                if viewModel.isUninstalledNarrationNoticeVisible {
                    uninstalledNarrationNotice
                }
            }
            .padding(.vertical, .sm)
        }
    }

    func sectionView(_ section: GlobalSearchSection) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            sectionHeader(section)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(section.hits) { hit in
                    GlobalSearchResultRow(hit: hit,
                                          snippet: viewModel.highlightedSnippet(hit)) {
                        viewModel.select(hit)
                    }

                    if hit.id != section.hits.last?.id {
                        Divider()
                            .overlay(Color.outlineVariant.opacity(0.14))
                            .padding(.horizontal, .md)
                    }
                }
            }
            .background(ColorStyle.surfaceContainerLow.color)
            .cornerRadius(.cornerCard)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerCard)
                    .strokeBorder(Color.outlineVariant.opacity(0.14), lineWidth: 1)
            )
        }
        .padding(.horizontal, .big)
    }

    func sectionHeader(_ section: GlobalSearchSection) -> some View {
        HStack(spacing: .xSm) {
            Text(viewModel.scopeTitle(section.scope))
                .customStyle(.subheadline, .onSurface)

            Text(viewModel.matchCountText(section))
                .customStyle(.caption2, .onSurfaceVariant)

            Spacer(minLength: 0)

            if section.isTruncated {
                Button { viewModel.selectScope(section.scope) } label: {
                    Text(viewModel.showAllTitle)
                        .customStyle(.caption1, .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .xSm)
    }

    var uninstalledNarrationNotice: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            Text(viewModel.uninstalledNarrationTitle)
                .customStyle(.caption1, .onSurface)

            Text(viewModel.uninstalledNarrationSubtitle)
                .customStyle(.caption2, .onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .background(ColorStyle.surfaceContainerLow.color)
        .cornerRadius(.cornerMd)
        .padding(.horizontal, .big)
    }
}
