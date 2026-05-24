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
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    private var accentColor: Color {
        let hex = viewModel.book.colorHex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        return Color(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue: Double(int         & 0xFF) / 255
        )
    }

    init(coordinator: HadithCoordinating, book: HadithBook) {
        _viewModel = StateObject(wrappedValue: HadithChaptersViewModel(coordinator: coordinator, book: book))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .onAppear { viewModel.onAppear() }
        .navigationBarHidden(true)
    }
}

// MARK: - Main Content

extension HadithChaptersView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            Divider().opacity(0.4)
            chaptersList
        }
        .customBackground(.background)
    }

    private var navBar: some View {
        HStack(spacing: 12) {
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(localizationManager.currentLanguage == .Arabic
                    ? viewModel.book.titleAr
                    : viewModel.book.titleEn)
                    .customStyle(.heading3, .onSurface)
                    .lineLimit(1)

                Text(localizationManager.currentLanguage == .Arabic
                    ? viewModel.book.authorAr
                    : viewModel.book.authorEn)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
            }

            Spacer()

            Text(String(format: "%d", viewModel.book.hadithCount))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(accentColor.opacity(0.12))
                .cornerRadius(8)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    private var chaptersList: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.chapters.enumerated()), id: \.element.id) { index, chapter in
                    HadithChapterRow(
                        chapter: chapter,
                        accentColor: accentColor,
                        isArabic: localizationManager.currentLanguage == .Arabic
                    ) {
                        viewModel.selectChapter(chapter)
                    }
                    if index < viewModel.chapters.count - 1 {
                        Divider().padding(.leading, .big)
                    }
                }
            }
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Chapter Row

struct HadithChapterRow: View {
    let chapter: HadithChapter
    let accentColor: Color
    let isArabic: Bool
    let action: () -> Void

    private var title: String { isArabic ? chapter.titleAr : chapter.titleEn }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(String(format: "%d", chapter.number))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.10))
                    .cornerRadius(8)

                Text(title)
                    .customStyle(.bodyMedium, .onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .customForeground(.onSurfaceVariant)
            }
            .padding(.horizontal, .big)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}
