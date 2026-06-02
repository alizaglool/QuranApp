//
//  QuranSearchView.swift
//  QuranApp
//

import SwiftUI
import Core

struct QuranSearchView: View {

    var onSelect: ((_ surah: Int, _ verse: Int) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var query: String = ""
    @State private var results: [QuranSearchResult] = []
    @State private var isSearching: Bool = false

    private var layoutDirection: LayoutDirection {
        localization.currentLanguage.direction
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            Divider()
            resultsList
        }
        .background(Color.background)
        .environment(\.layoutDirection, layoutDirection)
        .task(id: query) {
            guard query.trimmingCharacters(in: .whitespaces).count >= 2 else {
                results = []
                isSearching = false
                return
            }
            isSearching = true
            // Small debounce
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            let q = query
            let found = await Task.detached(priority: .userInitiated) {
                QuranSearchService.shared.search(q)
            }.value
            results = found
            isSearching = false
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(AppLocalizedKeys.searchQuran.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.outlineVariant.opacity(0.5), in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(AppLocalizedKeys.searchSurahOrAyah.value, text: $query)
                .customStyle(.kitab(size: 16), .onSurface)
                .submitLabel(.search)
                .environment(\.layoutDirection, .rightToLeft)

            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsList: some View {
        if query.trimmingCharacters(in: .whitespaces).count < 2 {
            emptyPrompt
        } else if isSearching {
            Spacer()
            ProgressView()
            Spacer()
        } else if results.isEmpty {
            noResults
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(results) { result in
                        resultRow(result)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var emptyPrompt: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.4))
            Text(AppLocalizedKeys.searchSurahOrAyah.value)
                .customStyle(.kitab(size: 15))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var noResults: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text(AppLocalizedKeys.noResults.value)
                .customStyle(.kitab(size: 15))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private func resultRow(_ result: QuranSearchResult) -> some View {
        Button {
            onSelect?(result.surahNumber, result.verseNumber)
        } label: {
            VStack(alignment: .trailing, spacing: 6) {
                // Surah name : verse number  •  page badge
                HStack {
                    Text("ص \(result.page)")
                        .customStyle(.kitab(size: 12))
                        .foregroundColor(ColorStyle.primary.color)
                        .environment(\.layoutDirection, .leftToRight)

                    Spacer()

                    Text("\(result.surahName): \(result.verseNumber)")
                        .customStyle(.kitab(size: 14, bold: true))
                        .foregroundColor(ColorStyle.primary.color)
                }

                // Verse text — truncated, right-aligned Arabic
                Text(result.text)
                    .customStyle(.kitab(size: 15))
                    .foregroundColor(.primary.opacity(0.85))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
