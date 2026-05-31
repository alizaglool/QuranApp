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
    @ObservedObject private var downloadManager = HadithDownloadManager.shared
    // Kept for SwiftUI re-render subscription on language change
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme
    @FocusState private var searchFocused: Bool

    init(coordinator: HadithCoordinating) {
        _viewModel = StateObject(wrappedValue: HadithLibraryViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .id(localizationManager.currentLanguage.rawValue)
        .onAppear { viewModel.onAppear() }
        .onChange(of: viewModel.searchText) { viewModel.performSearch() }
    }

    // MARK: – English number formatter (always Latin digits)
    private func formatNumber(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle        = .decimal
        f.locale             = Locale(identifier: "en_US")
        f.groupingSeparator  = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: – Full-bleed gradient for hero and continue-reading cards
    private var primaryCardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryColor, Color.primaryContainer],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: – Subtle tinted surface for secondary cards
    private var adaptiveCardBackground: Color {
        colorScheme == .dark
            ? Color.primaryColor.opacity(0.20)
            : Color.primaryColor.opacity(0.07)
    }
}

// MARK: - Main Content

extension HadithLibraryView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navigationBar
            if viewModel.isSearching {
                searchBarView.padding(.bottom, .xSm)
                searchResultsList
            } else {
                NoIndicatorsScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        searchBarView.padding(.bottom, .xBig)
                        if let position = viewModel.lastRead {
                            continueReadingCard(position)
                                .padding(.horizontal, .big)
                                .padding(.bottom, .xBig)
                        }
                        bookListSection
                        propheticQuoteSection
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .customBackground(.background)
    }
}

// MARK: - Navigation Bar

extension HadithLibraryView {

    private var navigationBar: some View {
        Text(AppLocalizedKeys.hadithLibrary.value)
            .customStyle(.heading3, .primary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, .big)
            .padding(.vertical, .sm)
            .padding(.top, .xxSm)
    }
}

// MARK: - Header

extension HadithLibraryView {

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(AppLocalizedKeys.theAuthenticTraditions.value.uppercased())
                .customStyle(.caption2)
                .tracking(1.8)
                .customForeground(.primary)

            Text(AppLocalizedKeys.exploringLegacy.value)
                .customStyle(.kitab(size: 28, bold: true))
                .customForeground(.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .big)
        .padding(.top, .big)
        .padding(.bottom, .md)
    }
}

// MARK: - Search Bar

extension HadithLibraryView {

    private var searchBarView: some View {
        HStack(spacing: .xSm + 2) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .customForeground(.onSurfaceVariant)

            TextField(AppLocalizedKeys.searchNarrations.value, text: $viewModel.searchText)
                .customStyle(.bodyMedium, .onSurface)
                .focused($searchFocused)

            if !viewModel.searchText.isEmpty {
                Button { viewModel.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .customForeground(.onSurfaceVariant)
                }
            }
        }
        .padding(.horizontal, .md)
        .padding(.vertical, 11)
        .background(adaptiveCardBackground)
        .cornerRadius(.cornerMd)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerMd)
                .strokeBorder(Color.outlineVariant.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}

// MARK: - Continue Reading Card

extension HadithLibraryView {

    private func continueReadingCard(_ position: LastReadPosition) -> some View {
        Button { viewModel.resume() } label: {
            VStack(alignment: .leading, spacing: .md) {

                // Badge row + progress counter
                HStack(alignment: .center) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.secondaryColor)
                    Text(AppLocalizedKeys.continueReading.value.uppercased())
                        .customStyle(.caption2)
                        .tracking(1.4)
                        .foregroundColor(Color.secondaryColor)
                    Spacer()
                    Text("\(formatNumber(position.hadithIndex + 1)) OF \(formatNumber(position.bookHadithCount)) HADITH")
                        .customStyle(.caption2)
                        .tracking(0.4)
                        .foregroundColor(Color.white.opacity(0.50))
                }

                // Book title + chapter + resume button
                HStack(alignment: .center, spacing: .sm) {
                    VStack(alignment: .leading, spacing: .xxSm) {
                        Text(position.bookTitle)
                            .customStyle(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text(position.chapterTitle)
                            .customStyle(.caption1)
                            .foregroundColor(Color.white.opacity(0.60))
                            .lineLimit(1)
                    }
                    Spacer()
                    HStack(spacing: .xxSm + 1) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(AppLocalizedKeys.resume.value.uppercased())
                            .customStyle(.caption2)
                            .tracking(0.6)
                    }
                    .foregroundColor(Color.primaryColor)
                    .padding(.horizontal, .sm)
                    .padding(.vertical, .xSm + 1)
                    .background(Color.secondaryColor)
                    .cornerRadius(.cornerXSm)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 3)
                        let pct = position.bookHadithCount > 0
                            ? min(1, Double(position.hadithIndex + 1) / Double(position.bookHadithCount))
                            : 0
                        Capsule()
                            .fill(Color.secondaryColor)
                            .frame(width: geo.size.width * pct, height: 3)
                    }
                }
                .frame(height: 3)
            }
            .padding(.md)
            .background(primaryCardGradient)
            .cornerRadius(.cornerXl)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Book List Section

extension HadithLibraryView {

    private var bookListSection: some View {
        let books = viewModel.books
        return VStack(spacing: .sm) {
            if let first = books.first {
                featuredBookCard(first)
                    .padding(.horizontal, .big)
            }
            if books.count > 1 {
                ForEach(
                    Array(books[1...].enumerated()),
                    id: \.offset
                ) { idx, book in
                    bookCard(book, iconIndex: idx)
                        .padding(.horizontal, .big)
                }
            }
        }
        .padding(.bottom, .xxBig)
    }

    // MARK: Featured Book Card (first book — full-height hero)

    private func featuredBookCard(_ book: HadithBook) -> some View {
        let dlState    = downloadManager.state(for: book.id)
        let downloaded = dlState == .downloaded
        let stats = "\(formatNumber(book.hadithCount)) HADITH · \(formatNumber(book.chapterCount)) BOOKS"

        return ZStack(alignment: .bottomLeading) {
            primaryCardGradient

            // Ghosted decorative icon — top right
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "book.open.fill")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(Color.white.opacity(0.10))
                        .padding([.top, .trailing], 18)
                }
                Spacer()
            }

            // Metadata — bottom left
            VStack(alignment: .leading, spacing: .xSm) {
                Spacer()
                Text(book.title)
                    .customStyle(.kitab(size: 24, bold: true))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                if !book.author.isEmpty {
                    Text(book.author)
                        .customStyle(.caption1)
                        .foregroundColor(Color.white.opacity(0.55))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(stats)
                    .customStyle(.caption2)
                    .tracking(0.5)
                    .foregroundColor(Color.secondaryColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.big)
        }
        .overlay(alignment: .topTrailing) {
            downloadButton(for: book, state: dlState, dark: true)
                .padding(.md)
        }
        .frame(height: 200)
        .cornerRadius(.cornerXxl)
        .contentShape(Rectangle())
        .onTapGesture { if downloaded { viewModel.selectBook(book) } }
    }

    // MARK: Book Card (all remaining books)

    private func bookCard(_ book: HadithBook, iconIndex: Int) -> some View {
        let icons      = ["books.vertical.fill", "scroll.fill", "doc.richtext.fill", "book.pages.fill"]
        let icon       = icons[iconIndex % icons.count]
        let isDark     = colorScheme == .dark
        let dlState    = downloadManager.state(for: book.id)
        let downloaded = dlState == .downloaded
        let iconColor  = isDark ? Color.white.opacity(0.55)  : Color.primaryColor.opacity(0.70)
        let titleColor = isDark ? Color.white                : Color.primaryColor
        let metaColor  = isDark ? Color.white.opacity(0.35)  : Color.primaryColor.opacity(0.45)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
                Spacer()
                downloadButton(for: book, state: dlState, dark: isDark)
            }
            .padding(.bottom, .sm)

            Text(book.title)
                .customStyle(.kitab(size: 18, bold: true))
                .foregroundColor(titleColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, .xxSm + 1)

            Text("\(formatNumber(book.hadithCount)) HADITH")
                .customStyle(.caption2)
                .tracking(0.5)
                .foregroundColor(Color.secondaryColor)

            if !book.author.isEmpty {
                Text(book.author.uppercased())
                    .customStyle(.caption2)
                    .tracking(1.0)
                    .foregroundColor(metaColor)
                    .lineLimit(1)
                    .padding(.top, .xxSm - 1)
            }
        }
        .padding(.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(adaptiveCardBackground)
        .cornerRadius(.cornerXl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXl)
                .strokeBorder(Color.outlineVariant.opacity(0.18), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { if downloaded { viewModel.selectBook(book) } }
    }
}

// MARK: - Download Button

extension HadithLibraryView {

    @ViewBuilder
    private func downloadButton(for book: HadithBook, state: HadithDownloadState, dark: Bool) -> some View {
        let stroke: Color = dark ? Color.white.opacity(0.35)       : Color.onSurface.opacity(0.30)
        let bg: Color     = dark ? Color.white.opacity(0.10)       : Color.onSurface.opacity(0.06)
        let icon: Color   = dark ? Color.white.opacity(0.80)       : Color.onSurface.opacity(0.70)

        switch state {
        case .notDownloaded:
            Button { viewModel.download(book) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: .cornerSm).fill(bg)
                    RoundedRectangle(cornerRadius: .cornerSm).strokeBorder(stroke, lineWidth: 1)
                    Image(systemName: "arrow.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(icon)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

        case .downloading(let progress):
            Button { viewModel.cancelDownload(book) } label: {
                ZStack {
                    Circle().stroke(stroke.opacity(0.40), lineWidth: 2.5)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.secondaryColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.15), value: progress)
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(icon)
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

        case .downloaded:
            EmptyView()

        case .failed:
            Button { viewModel.download(book) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: .cornerSm).fill(Color.red.opacity(0.10))
                    RoundedRectangle(cornerRadius: .cornerSm).strokeBorder(Color.red.opacity(0.40), lineWidth: 1)
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red.opacity(0.80))
                }
                .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Prophetic Quote Section

extension HadithLibraryView {

    private var propheticQuoteSection: some View {
        VStack(spacing: 0) {
            Text("\u{201C}")
                .customStyle(.kitab(size: 28, bold: true))                .foregroundColor(Color.secondaryColor.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, .xSm)

            Text(AppLocalizedKeys.hadithLibraryQuote.value)
                .customStyle(.kitab(size: 17, bold: true))
                .customForeground(.onSurface)
                .multilineTextAlignment(.center)
                .italic()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, .xSm)
                .padding(.bottom, .big)

            Rectangle()
                .fill(Color.secondaryColor.opacity(0.30))
                .frame(width: 40, height: 1)
                .padding(.bottom, .sm)

            Text(AppLocalizedKeys.propheticNarration.value.uppercased())
                .customStyle(.caption2)
                .tracking(1.8)
                .customForeground(.primary)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .xxBig)
        .frame(maxWidth: .infinity)
        .background(adaptiveCardBackground)
        .cornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .strokeBorder(Color.outlineVariant.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, .big)
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
                            HadithSearchRow(result: result) {
                                viewModel.selectSearchResult(result)
                            }
                            Divider().padding(.leading, .big)
                        }
                    }
                    .padding(.bottom, .xxxBig)
                }
            }
        }
    }

    private var emptySearchState: some View {
        VStack(spacing: .sm) {
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

// MARK: - Search Row

struct HadithSearchRow: View {
    let result: HadithSearchResult
    let action: () -> Void

    private var accentColor: Color { Color(hex: result.book.colorHex) }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: .sm) {
                RoundedRectangle(cornerRadius: .cornerXxSm)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 4)
                    .padding(.vertical, .xxSm)

                VStack(alignment: .leading, spacing: .xSm) {
                    HStack {
                        Text(result.book.title)
                            .customStyle(.caption2)
                            .foregroundColor(accentColor)
                            .lineLimit(1)
                        Spacer()
                        Text(String(format: "%d", result.hadith.number))
                            .customStyle(.caption2, .onSurfaceVariant)
                    }
                    Text(result.hadith.arabicText)
                        .customStyle(.kitab(size: 14, bold: true))
                        .customForeground(.onSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .rightToLeft)
                    Text(result.hadith.translation)
                        .customStyle(.caption1, .onSurfaceVariant)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, .big)
            .padding(.vertical, .sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
