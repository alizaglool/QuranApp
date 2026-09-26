//
//  QuranSearchView.swift
//  QuranApp
//

import SwiftUI
import Core

/// Inline search for the Quran pager. Renders the search field in the position the
/// pager's `topBar` occupies, with results in a translucent panel directly below, so
/// the mushaf page is never unmounted and stays visible behind.
struct QuranSearchView: View {

    /// Owned by `QuranPagerView` so entering search can focus the field.
    @FocusState.Binding var isFieldFocused: Bool

    /// The pager's own bar background, so the morph from `topBar` does not jump.
    let barBackground: Color

    let onSelect: (_ surah: Int, _ verse: Int) -> Void
    let onCancel: () -> Void

    @ObservedObject private var localization = LocalizationManager.shared

    @State private var query: String = ""
    @State private var results: [QuranSearchResult] = []
    @State private var isSearching: Bool = false
    /// The trimmed query `results` belong to. Lets "no results" appear only after a
    /// search has actually completed, instead of flashing during the debounce.
    @State private var searchedQuery: String = ""

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    private var hasCompletedSearch: Bool {
        !trimmedQuery.isEmpty && searchedQuery == trimmedQuery
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            searchResultsPanel
                .frame(maxHeight: .infinity)
        }
        // Quran content is RTL regardless of app language — same pin as `topBar`.
        .environment(\.layoutDirection, .rightToLeft)
        .task(id: query) {
            guard trimmedQuery.count >= 2 else {
                results = []
                searchedQuery = ""
                isSearching = false
                return
            }
            // Debounce. `isSearching` is deliberately NOT set until after the sleep:
            // setting it up front blanked the list and flashed a spinner on every
            // keystroke. The previous results stay on screen until new ones arrive.
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            isSearching = true
            let q = trimmedQuery
            let found = await Task.detached(priority: .userInitiated) {
                QuranSearchService.shared.search(q)
            }.value
            guard !Task.isCancelled else { return }
            results = found
            searchedQuery = q
            isSearching = false
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(ColorStyle.onSurfaceVariant.color)

                TextField(AppLocalizedKeys.searchSurahOrAyah.value, text: $query)
                    .customStyle(.uthmanicNaskh(size: 17))
                    .foregroundColor(ColorStyle.onSurface.color)
                    .submitLabel(.search)
                    .focused($isFieldFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !query.isEmpty {
                    Button { query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ColorStyle.onSurfaceVariant.color)
                    }
                    .accessibilityLabel(AppLocalizedKeys.cancel.value)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 10))

            Button(action: onCancel) {
                Text(AppLocalizedKeys.cancel.value)
                    .customStyle(.kitab(size: 16))
                    // Design-system green, not `Color.quranGreen`: the file defining
                    // that token is not in the target's Compile Sources, so it does
                    // not exist at build time. This is the token every sibling view
                    // in this folder uses, and unlike "Primary Color" it is
                    // theme-aware.
                    .foregroundColor(ColorStyle.primary.color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .safeAreaPadding(.horizontal)
        .background(barBackground.opacity(0.95))
    }

    // MARK: - Results Panel

    private var searchResultsPanel: some View {
        VStack(spacing: 0) {
            if trimmedQuery.count >= 2 {
                header
                if hasCompletedSearch && results.isEmpty {
                    noResults
                } else {
                    resultsCard
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // One material layer for the whole panel — the mushaf page stays visible
        // behind it. A second material on top of this reads muddy.
        .background(.regularMaterial)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if isSearching {
                ProgressView()
                    .controlSize(.small)
            }

            Spacer()

            if !isSearching && !results.isEmpty {
                Text(verbatim: "آيات (\(results.count.arabicNumerals))")
                    .customStyle(.kitab(size: 15, bold: true))
                    .foregroundColor(ColorStyle.onSurfaceVariant.color)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityValue(Text(verbatim: results.count.arabicNumerals))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Results

    private var resultsCard: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(results.enumerated()), id: \.element.id) { index, result in
                    resultRow(result)
                    if index < results.count - 1 {
                        Divider()
                            .overlay(ColorStyle.outlineVariant.color.opacity(0.4))
                            .padding(.horizontal, 14)
                    }
                }
            }
            // Translucent, not opaque: an opaque card would hide the page exactly
            // where the rows are, which is the whole point of the material panel.
            .background(Color.surfaceContainerLow.opacity(0.35),
                        in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var noResults: some View {
        VStack {
            Spacer()
            Text(AppLocalizedKeys.noResults.value)
                .customStyle(.kitab(size: 15))
                .foregroundColor(ColorStyle.onSurfaceVariant.color)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func resultRow(_ result: QuranSearchResult) -> some View {
        Button {
            onSelect(result.surahNumber, result.verseNumber)
        } label: {
            VStack(alignment: .trailing, spacing: 7) {
                HStack {
                    Text(result.page.arabicNumerals)
                        .customStyle(.kitab(size: 15, bold: true))
                        .foregroundColor(Color.verseMarkerGold)

                    Spacer()

                    Text(verbatim: "\(result.surahName): \(result.verseNumber.arabicNumerals)")
                        .customStyle(.kitab(size: 14, bold: true))
                        .foregroundColor(ColorStyle.onSurfaceVariant.color)
                }

                Text(highlighted(result.text))
                    .customStyle(.uthmanicNaskh(size: 17))
                    .foregroundColor(ColorStyle.quranText.color)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(result.surahName) آية \(result.verseNumber.arabicNumerals)، صفحة \(result.page.arabicNumerals)"
        )
    }

    // MARK: - Highlight

    /// Colours every occurrence of the query inside the Uthmani verse text.
    /// The ranges come from the normalized-to-original index map, because the
    /// displayed string and the matched string are different strings.
    private func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        for range in QuranSearchService.highlightRanges(in: text, query: trimmedQuery) {
            guard
                let lower = AttributedString.Index(range.lowerBound, within: attributed),
                let upper = AttributedString.Index(range.upperBound, within: attributed)
            else { continue }
            attributed[lower ..< upper].foregroundColor = Color.searchMatch
        }
        return attributed
    }
}
