//
//  HadithSearchResultsView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 06/10/2026.
//

import SwiftUI
import Core

struct HadithSearchResultsView: View {

    @ObservedObject var viewModel: HadithLibraryViewModel

    var body: some View {
        content.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.searchPhase {
        case .idle:
            EmptyView()
        case .tooShort, .noResults:
            message
        case .running:
            if viewModel.searchOutcome.isEmpty { spinner } else { resultList }
        case .results:
            resultList
        }
    }

    // MARK: - States

    private var spinner: some View {
        VStack {
            Spacer()
            ProgressView().controlSize(.regular)
            Spacer()
        }
    }

    private var message: some View {
        VStack(spacing: .sm) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34, weight: .light))
                .customForeground(.onSurfaceVariant)
            Text(viewModel.searchStatusMessage)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .xxxBig)
            Spacer()
        }
    }

    // MARK: - List

    private var resultList: some View {
        NoIndicatorsScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                summary
                ForEach(viewModel.searchOutcome.books) { matches in
                    Section {
                        rows(matches)
                    } header: {
                        header(matches)
                    }
                }
                notInstalledNote
            }
            .padding(.bottom, .xxxBig)
        }
    }

    private var summary: some View {
        Text(viewModel.searchSummary)
            .customStyle(.caption2, .onSurfaceVariant)
            .padding(.horizontal, .big)
            .padding(.bottom, .xSm)
    }

    private func header(_ matches: HadithBookMatches) -> some View {
        HStack(spacing: .xSm + 2) {
            Capsule()
                .fill(accent(matches.book))
                .frame(width: 3, height: 14)

            Text(matches.book.title)
                .customStyle(.caption1, .onSurface)
                .lineLimit(1)

            Spacer(minLength: .xSm)

            Text(viewModel.matchCountLabel(for: matches))
                .customStyle(.caption2, .onSurfaceVariant)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .xSm + 2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.18))
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private func rows(_ matches: HadithBookMatches) -> some View {
        ForEach(Array(matches.results.enumerated()), id: \.element.id) { index, result in
            row(result, accent: accent(matches.book))
            if index < matches.results.count - 1 {
                Divider()
                    .padding(.horizontal, .big)
                    .opacity(0.45)
            }
        }
        if matches.hasMore {
            expandRow(matches)
        }
    }

    private func row(_ result: HadithSearchResult, accent: Color) -> some View {
        Button {
            viewModel.selectSearchResult(result)
        } label: {
            VStack(alignment: .leading, spacing: .xSm) {
                Text(viewModel.snippet(for: result))
                    .customStyle(.adhkar(size: 16), .onSurface)
                    .lineSpacing(7)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)

                if let translation = viewModel.translationSnippet(for: result) {
                    Text(translation)
                        .customStyle(.caption1, .onSurfaceVariant)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(viewModel.numberLabel(for: result))
                    .customStyle(.caption2)
                    .foregroundColor(accent)
            }
            .padding(.horizontal, .big)
            .padding(.vertical, .sm + 2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HadithSearchRowStyle())
    }

    private func expandRow(_ matches: HadithBookMatches) -> some View {
        Button {
            viewModel.expandResults(for: matches)
        } label: {
            HStack(spacing: .xSm) {
                if viewModel.expandedBookIds.contains(matches.id) {
                    ProgressView().controlSize(.mini)
                } else {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(viewModel.expandLabel(for: matches))
                    .customStyle(.caption1)
            }
            .foregroundColor(accent(matches.book))
            .padding(.horizontal, .big)
            .padding(.vertical, .sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(HadithSearchRowStyle())
        .disabled(viewModel.expandedBookIds.contains(matches.id))
    }

    @ViewBuilder
    private var notInstalledNote: some View {
        if !viewModel.searchOutcome.notInstalled.isEmpty {
            VStack(alignment: .leading, spacing: .xxSm) {
                HStack(spacing: .xSm) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13))
                    Text(viewModel.notInstalledTitle)
                        .customStyle(.caption1, .onSurface)
                }
                Text(viewModel.notInstalledSubtitle)
                    .customStyle(.caption2, .onSurfaceVariant)
            }
            .padding(.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.hadithCardWash)
            .cornerRadius(.cornerMd)
            .padding(.horizontal, .big)
            .padding(.top, .md)
        }
    }

    private func accent(_ book: HadithBook) -> Color { Color(hex: book.colorHex) }
}

// MARK: - Row press feedback

private struct HadithSearchRowStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.hadithCardWash : Color.clear)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
