//
//  HadithChaptersView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import SwiftUI
import Core

struct HadithChaptersView: View {

    @StateObject private var viewModel: HadithChaptersViewModel

    private var accentColor: Color { Color(hex: viewModel.book.colorHex) }

    init(coordinator: HadithCoordinating, book: HadithBook) {
        _viewModel = StateObject(
            wrappedValue: HadithChaptersViewModel(coordinator: coordinator, book: book)
        )
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .onAppear {
            viewModel.onAppear()
            hideTabBar()
        }
        .navigationBarHidden(true)
    }

    // MARK: – English number formatter (always Latin digits)
    private func formatNumber(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle        = .decimal
        f.locale             = Locale(identifier: "en_US")
        f.groupingSeparator  = ","
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Main Content

extension HadithChaptersView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navigationBar
            Divider().opacity(0.4)
            chaptersListContent
        }
        .customBackground(.background)
    }

    private var navigationBar: some View {
        HStack(spacing: .sm) {
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(.cornerMd)
            }

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(viewModel.book.title)
                    .customStyle(.heading3, .onSurface)
                    .lineLimit(1)

                Text(viewModel.book.author)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            Text(formatNumber(viewModel.book.hadithCount))
                .customFont(.caption1)
                .foregroundColor(accentColor)
                .padding(.horizontal, .xSm)
                .padding(.vertical, .xxSm)
                .background(accentColor.opacity(0.12))
                .cornerRadius(.cornerXSm)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    private var chaptersListContent: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 0) {
                ForEach(
                    Array(viewModel.chapters.enumerated()),
                    id: \.element.id
                ) { index, chapter in
                    HadithChapterRow(
                        chapter: chapter,
                        accentColor: accentColor,
                        formatNumber: formatNumber
                    ) {
                        viewModel.selectChapter(chapter)
                    }
                    if index < viewModel.chapters.count - 1 {
                        Divider().padding(.leading, .big)
                    }
                }
            }
            .padding(.bottom, .xxxBig)
        }
    }
}

// MARK: - Chapter Row

struct HadithChapterRow: View {
    let chapter: HadithChapter
    let accentColor: Color
    let formatNumber: (Int) -> String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .md) {
                Text(formatNumber(chapter.number))
                    .customFont(.caption1)
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.10))
                    .cornerRadius(.cornerXSm)

                Text(chapter.title)
                    .customStyle(.bodyMedium, .onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .customForeground(.onSurfaceVariant)
            }
            .padding(.horizontal, .big)
            .padding(.vertical, .md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
