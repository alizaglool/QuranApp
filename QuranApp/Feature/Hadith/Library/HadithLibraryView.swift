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
    @EnvironmentObject private var localizationManager: LocalizationManager
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

    // MARK: - Card Styling

    private var primaryCardGradient: LinearGradient {
        LinearGradient(
            colors: [Color.primaryColor, Color.primaryContainer],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var adaptiveCardBackground: Color { .hadithCardWash }
}

// MARK: - Main Content

extension HadithLibraryView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navigationBar
            if viewModel.isSearching {
                searchBarView.padding(.bottom, .xSm)
                HadithSearchResultsView(viewModel: viewModel)
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
            Text(viewModel.authenticTraditionsTitle)
                .customStyle(.caption2, .primary)

            Text(AppLocalizedKeys.exploringLegacy.value)
                .customStyle(.adhkar(size: 28, bold: true), .onSurface)
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
                HStack(alignment: .center) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.secondaryColor)
                    Text(viewModel.continueReadingTitle)
                        .customStyle(.caption2)
                        .foregroundColor(Color.secondaryColor)
                    Spacer()
                    Text(viewModel.readingProgressText(for: position))
                        .customStyle(.caption2)
                        .foregroundColor(Color.white.opacity(0.50))
                }

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
                        Text(viewModel.resumeTitle)
                            .customStyle(.caption2)
                    }
                    .foregroundColor(Color.primaryColor)
                    .padding(.horizontal, .sm)
                    .padding(.vertical, .xSm + 1)
                    .background(Color.secondaryColor)
                    .cornerRadius(.cornerXSm)
                }

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
        VStack(alignment: .leading, spacing: .big) {
            bookSection(title: viewModel.nineBooksSectionTitle,
                        books: viewModel.nineBooks)

            bookSection(title: viewModel.otherCollectionsSectionTitle,
                        books: viewModel.otherCollections)
        }
        .padding(.horizontal, .big)
        .padding(.bottom, .xxBig)
    }

    @ViewBuilder
    private func bookSection(title: String, books: [HadithBook]) -> some View {
        if !books.isEmpty {
            VStack(alignment: .leading, spacing: .sm) {
                Text(title)
                    .customStyle(.subheadline, .onSurface)

                VStack(spacing: .xSm) {
                    ForEach(books) { book in
                        bookRow(book)
                    }
                }
            }
        }
    }

    private func bookRow(_ book: HadithBook) -> some View {
        let downloadState = downloadManager.state(for: book.id)

        return HadithBookRow(
            book: book,
            metaText: viewModel.metaText(for: book),
            isDownloaded: downloadState == .downloaded,
            onSelect: { viewModel.selectBook(book) }
        ) {
            downloadButton(for: book, state: downloadState)
        }
    }
}


// MARK: - Download Button

extension HadithLibraryView {

    @ViewBuilder
    private func downloadButton(for book: HadithBook,
                                state: HadithDownloadState,
                                on surface: DownloadSurface = .adaptive) -> some View {
        let stroke: Color = surface.stroke.color
        let bg: Color     = surface.fill.color
        let icon: Color   = surface.icon.color

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
                .customStyle(.adhkar(size: 28, bold: true))
                .foregroundColor(Color.secondaryColor.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, .xSm)

            Text(AppLocalizedKeys.hadithLibraryQuote.value)
                .customStyle(.adhkar(size: 17, bold: true), .onSurface)
                .multilineTextAlignment(.center)
                .italic()
                .frame(maxWidth: .infinity)
                .padding(.horizontal, .xSm)
                .padding(.bottom, .big)

            Rectangle()
                .fill(Color.secondaryColor.opacity(0.30))
                .frame(width: 40, height: 1)
                .padding(.bottom, .sm)

            Text(viewModel.propheticNarrationTitle)
                .customStyle(.caption2, .primary)
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

extension HadithLibraryView {

    enum DownloadSurface {
        case adaptive
        case alwaysDark

        var stroke: ColorStyle {
            switch self {
            case .adaptive:   return .downloadStroke
            case .alwaysDark: return .downloadStrokeOnDark
            }
        }

        var fill: ColorStyle {
            switch self {
            case .adaptive:   return .downloadSurface
            case .alwaysDark: return .downloadSurfaceOnDark
            }
        }

        var icon: ColorStyle {
            switch self {
            case .adaptive:   return .downloadIcon
            case .alwaysDark: return .downloadIconOnDark
            }
        }
    }
}
