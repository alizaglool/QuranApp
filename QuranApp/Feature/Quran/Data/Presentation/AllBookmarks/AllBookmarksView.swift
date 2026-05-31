//
//  AllBookmarksView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-21.
//

import SwiftUI
import Core

struct AllBookmarksView: View {
    @StateObject private var viewModel: AllBookmarksViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared

    /// Optional callback fired when the user picks a color and the sheet should
    /// dismiss. The parent (VerseActionSheet) uses this to also dismiss itself.
    private let onSelected: (() -> Void)?

    private var layoutDirection: LayoutDirection {
        localization.currentLanguage.direction
    }

    init(
        page: Int,
        surahNumber: Int,
        surahName: String,
        verseNumber: Int,
        onSelected: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: AllBookmarksViewModel(
                page: page,
                surahNumber: surahNumber,
                surahName: surahName,
                verseNumber: verseNumber
            )
        )
        self.onSelected = onSelected
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content
        }
        .background(Color.background)
        .environment(\.layoutDirection, layoutDirection)
    }

    // MARK: - Header
    // Leading: verse reference button | Center: title | Trailing: X

    private var header: some View {
        HStack {
            // Leading — verse reference (tapping navigates to that verse)
            Button(action: { viewModel.navigateToVerse() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ColorStyle.primary.color)

                    Text("\(viewModel.surahName): \(viewModel.verseNumber)")
                        .customStyle(.kitab(size: 15))                        .foregroundColor(ColorStyle.primary.color)
                }
            }

            Spacer()

            Text(AppLocalizedKeys.bookmarks.value)
                .customStyle(.kitab(size: 17, bold: true))                .customForeground(.onSurface)

            Spacer()

            // Trailing — close sheet
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            bookmarkList
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Bookmark List
    // White card with dividers between rows — no divider after the last row

    private var bookmarkList: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.bookmarks.enumerated()), id: \.element.id) { index, bookmark in
                bookmarkRow(bookmark)

                if index < viewModel.bookmarks.count - 1 {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.surfaceContainerLow)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Bookmark Row
    // Whole-row Button: icon + label + (checkmark when active).
    // .contentShape(Rectangle()) makes the entire row including the Spacer
    // hit-testable — without it, taps over the empty space were being dropped.

    private func bookmarkRow(_ bookmark: BookmarkType) -> some View {
        let active = viewModel.isActive(bookmark)

        return Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                viewModel.selectBookmark(bookmark)
            }
            // Tight delay — just enough to see the checkmark animation pop
            // before both sheets dismiss back to the Mushaf page.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
                onSelected?()
            }
        } label: {
            HStack(spacing: 14) {
                // Colored bookmark icon — slightly larger when active for visual emphasis.
                Image(systemName: "bookmark.fill")
                    .font(.system(size: active ? 22 : 20))
                    .foregroundColor(bookmark.color)
                    .frame(width: 24, height: 24)

                Text(bookmark.titleKey.value)
                    .customStyle(.kitab(size: 16))                    .customForeground(.onSurface)

                Spacer(minLength: 0)

                // Active checkmark — auto-mirrors in RTL (semantic trailing position).
                if active {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(bookmark.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                // Subtle tinted background on the active row.
                RoundedRectangle(cornerRadius: 10)
                    .fill(active ? bookmark.color.opacity(0.12) : Color.clear)
                    .padding(.horizontal, 6)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
