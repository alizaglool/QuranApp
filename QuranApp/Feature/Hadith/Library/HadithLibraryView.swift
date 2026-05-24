//
//  HadithLibraryView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import SwiftUI
import Core

struct HadithLibraryView: View {

    @StateObject private var viewModel: HadithLibraryViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    init(coordinator: HadithCoordinating) {
        _viewModel = StateObject(wrappedValue: HadithLibraryViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .onAppear { viewModel.onAppear() }
        .onChange(of: viewModel.searchText) { _ in viewModel.performSearch() }
    }
}

// MARK: - Main Content

extension HadithLibraryView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            searchBar
            if viewModel.isSearching {
                searchResultsList
            } else {
                NoIndicatorsScrollView {
                    bentoGrid
                        .padding(.horizontal, .big)
                        .padding(.bottom, 32)
                }
            }
        }
        .customBackground(.background)
    }

    private var navBar: some View {
        HStack {
            Text(AppLocalizedKeys.hadith.value)
                .customStyle(.heading2, .onSurface)
            Spacer()
        }
        .padding(.horizontal, .big)
        .padding(.top, .sm)
        .padding(.bottom, 4)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .customForeground(.onSurfaceVariant)

            TextField(AppLocalizedKeys.search.value, text: $viewModel.searchText)
                .customStyle(.bodyMedium, .onSurface)

            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .customForeground(.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
        .cornerRadius(12)
        .padding(.horizontal, .big)
        .padding(.bottom, 16)
    }
}

// MARK: - Bento Grid

extension HadithLibraryView {

    private var bentoGrid: some View {
        VStack(spacing: 12) {
            if viewModel.books.count >= 2 {
                heroRow
            }
            if viewModel.books.count >= 5 {
                tripleRow(books: Array(viewModel.books[2..<5]))
            }
            if viewModel.books.count >= 7 {
                doubleRow(books: Array(viewModel.books[5..<7]))
            }
            if viewModel.books.count >= 9 {
                doubleRow(books: Array(viewModel.books[7..<9]))
            }
        }
    }

    private var heroRow: some View {
        GeometryReader { geo in
            HStack(spacing: 12) {
                HadithBookCard(
                    book: viewModel.books[0],
                    style: .hero,
                    colorScheme: colorScheme,
                    isArabic: localizationManager.currentLanguage == .Arabic
                ) { viewModel.selectBook(viewModel.books[0]) }
                .frame(width: (geo.size.width - 12) * 2 / 3)

                HadithBookCard(
                    book: viewModel.books[1],
                    style: .compact,
                    colorScheme: colorScheme,
                    isArabic: localizationManager.currentLanguage == .Arabic
                ) { viewModel.selectBook(viewModel.books[1]) }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 180)
    }

    private func tripleRow(books: [HadithBook]) -> some View {
        HStack(spacing: 12) {
            ForEach(books) { book in
                HadithBookCard(
                    book: book,
                    style: .compact,
                    colorScheme: colorScheme,
                    isArabic: localizationManager.currentLanguage == .Arabic
                ) { viewModel.selectBook(book) }
            }
        }
        .frame(height: 140)
    }

    private func doubleRow(books: [HadithBook]) -> some View {
        HStack(spacing: 12) {
            ForEach(books) { book in
                HadithBookCard(
                    book: book,
                    style: .compact,
                    colorScheme: colorScheme,
                    isArabic: localizationManager.currentLanguage == .Arabic
                ) { viewModel.selectBook(book) }
            }
        }
        .frame(height: 140)
    }
}

// MARK: - Search Results

extension HadithLibraryView {

    private var searchResultsList: some View {
        Group {
            if viewModel.searchResults.isEmpty {
                emptySearchState
            } else {
                NoIndicatorsScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.searchResults) { result in
                            HadithSearchRow(result: result, isArabic: localizationManager.currentLanguage == .Arabic) {
                                viewModel.selectSearchResult(result)
                            }
                            Divider()
                                .padding(.leading, .big)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .customForeground(.onSurfaceVariant)
            Text(AppLocalizedKeys.noResults.value)
                .customStyle(.bodySmall, .onSurfaceVariant)
            Spacer()
        }
    }
}

// MARK: - Book Card

enum HadithBookCardStyle { case hero, compact }

struct HadithBookCard: View {
    let book: HadithBook
    let style: HadithBookCardStyle
    let colorScheme: ColorScheme
    let isArabic: Bool
    let action: () -> Void

    private var accentColor: Color { Color(hex: book.colorHex) }
    private var title: String { isArabic ? book.titleAr : book.titleEn }
    private var author: String { isArabic ? book.authorAr : book.authorEn }

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                background
                content
            }
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        ZStack(alignment: .topTrailing) {
            (colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
            Circle()
                .fill(accentColor.opacity(colorScheme == .dark ? 0.18 : 0.10))
                .frame(width: style == .hero ? 120 : 80)
                .offset(x: 20, y: -20)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 6) {
            Spacer()
            Text(title)
                .font(style == .hero
                    ? .custom("Kitab-Bold", size: 16)
                    : .custom("Kitab-Bold", size: 13))
                .foregroundColor(ColorStyle.onSurface.color)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if style == .hero {
                Text(author)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
            }

            HStack(spacing: 4) {
                Text(String(format: "%d", book.hadithCount))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(accentColor)
                Text(AppLocalizedKeys.hadithCount.value.components(separatedBy: " ").last ?? "hadiths")
                    .font(.system(size: 11))
                    .customForeground(.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
    }
}

// MARK: - Search Row

struct HadithSearchRow: View {
    let result: HadithSearchResult
    let isArabic: Bool
    let action: () -> Void

    private var bookTitle: String { isArabic ? result.book.titleAr : result.book.titleEn }
    private var accentColor: Color { Color(hex: result.book.colorHex) }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 4)
                }
                .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(bookTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(accentColor)
                            .lineLimit(1)
                        Spacer()
                        Text(String(format: "%d", result.hadith.number))
                            .customStyle(.caption2, .onSurfaceVariant)
                    }

                    Text(result.hadith.arabicText)
                        .font(.custom("Kitab-Bold", size: 14))
                        .foregroundColor(ColorStyle.onSurface.color)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    Text(result.hadith.translation)
                        .customStyle(.caption1, .onSurfaceVariant)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, .big)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color+Hex

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
