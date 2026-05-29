//
//  VerseActionSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-04-07.
//

import SwiftUI
import Core

struct VerseActionSheet: View {
    let verseID: Int
    let page: Int
    let surahNumber: Int
    let surahName: String
    let verseNumber: Int
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss

    @ObservedObject private var localization = LocalizationManager.shared
    @ObservedObject private var storage = StorageManager.shared
    @ObservedObject private var audio = AudioEngine.shared
    @State private var showAllBookmarks = false

    // MARK: - Inline bookmark "default" derivation

    private var inlineBookmark: QuranBookmark? {
        _ = storage.bookmarksRevision
        if let here = storage.getBookmark(page: page, ayahNumber: verseNumber) {
            return here
        }
        return storage.getMostRecentBookmark()
    }

    private var inlineColorKey: String {
        inlineBookmark?.color ?? BookmarkColor.red.rawValue
    }

    private var inlineColor: Color {
        switch inlineColorKey {
        case BookmarkColor.yellow.rawValue: return .yellow
        case BookmarkColor.green.rawValue:  return .green
        case BookmarkColor.blue.rawValue:   return .blue
        default:                            return .red
        }
    }

    private var inlineLabel: String {
        switch inlineColorKey {
        case BookmarkColor.yellow.rawValue: return AppLocalizedKeys.yellowBookmark.value
        case BookmarkColor.green.rawValue:  return AppLocalizedKeys.greenBookmark.value
        case BookmarkColor.blue.rawValue:   return AppLocalizedKeys.blueBookmark.value
        default:                            return AppLocalizedKeys.redBookmark.value
        }
    }

    private var inlineSubtitle: String? {
        guard let bm = inlineBookmark, let ayah = bm.ayahNumber else { return nil }
        return "\(bm.surahName): \(ayah)"
    }

    /// Layout direction driven by the current app language (LTR for English, RTL for Arabic)
    private var layoutDirection: LayoutDirection {
        localization.currentLanguage.direction
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                sectionTitle(AppLocalizedKeys.bookmarks.value)
                bookmarkButtons

                sectionTitle(AppLocalizedKeys.recitation.value)
                recitationButtons

                sectionTitle(AppLocalizedKeys.tafsir.value)
                tafsirSection

                sectionTitle(AppLocalizedKeys.sharing.value)
                sharingButtons

                sectionTitle(AppLocalizedKeys.highlight.value)
                highlightColors
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(Color.background)
        .environment(\.layoutDirection, layoutDirection)
        .sheet(isPresented: $showAllBookmarks) {
            AllBookmarksView(
                page: page,
                surahNumber: surahNumber,
                surahName: surahName,
                verseNumber: verseNumber,
                onSelected: {
                    // AllBookmarksView already triggered its own dismiss via
                    // @Environment. Wait briefly for that animation to finish,
                    // then dismiss VerseActionSheet so the user lands back on
                    // the Mushaf page with the new highlight visible.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }
            )
            // Content is short (header + 4 rows) — use a fitted detent
            // so the sheet sizes to its content instead of stretching.
            .presentationDetents([.fraction(0.45), .medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header
    // Leading = Edit button | Center = title | Trailing = X
    // In RTL: leading = right side physically, trailing = left side physically

    private var header: some View {
        HStack {
            Button(action: { print("📋 Edit tapped") }) {
                Text(AppLocalizedKeys.edit.value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ColorStyle.primary.color)
            }

            Spacer()

            Text("\(surahName): \(verseNumber)")
                .font(.system(size: 17, weight: .semibold))
                .customForeground(.onSurface)

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Section Title
    // .leading alignment = right side in RTL, left side in LTR (semantic, no hardcoding)

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .customForeground(.onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bookmark Buttons

    private var bookmarkButtons: some View {
        HStack(spacing: 12) {
            actionCard(icon: "list.bullet", title: AppLocalizedKeys.allBookmarks.value, hasChevron: true) {
                showAllBookmarks = true
            }

            // Dynamic quick-save card — color and subtitle reflect the user's
            // last bookmark choice (or the bookmark already on this verse).
            inlineBookmarkCard
        }
    }

    // MARK: - Inline Bookmark Card

    private var inlineBookmarkCard: some View {
        Button {
            _ = storage.setBookmarkColor(
                page: page,
                surahNumber: surahNumber,
                surahName: surahName,
                ayahNumber: verseNumber,
                color: inlineColorKey
            )
            // Dismiss VerseActionSheet immediately so the user lands back on
            // the page and sees the new highlight without an extra tap.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 18))
                    .foregroundColor(inlineColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(inlineLabel)
                        .font(.system(size: 14, weight: .medium))
                        .customForeground(.onSurface)

                    if let subtitle = inlineSubtitle {
                        Text(subtitle)
                            .font(.custom("Kitab-Regular", size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceContainerLow)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recitation Buttons

    private var isCurrentVerse: Bool {
        audio.currentSurahNumber == surahNumber && audio.currentVerseNumber == verseNumber
    }

    private var recitationButtons: some View {
        HStack(spacing: 12) {
            actionCard(icon: "play.fill", title: AppLocalizedKeys.playTo.value, hasChevron: true) {
                audio.setRepeatMode(.surah)
                audio.play(surahNumber: surahNumber, verseNumber: verseNumber)
                dismiss()
            }

            actionCard(
                icon: audio.isPlaying && isCurrentVerse ? "pause.fill" : "play.fill",
                title: audio.isPlaying && isCurrentVerse ? AppLocalizedKeys.pause.value : AppLocalizedKeys.play.value
            ) {
                if audio.isPlaying && isCurrentVerse {
                    audio.pause()
                } else {
                    audio.play(surahNumber: surahNumber, verseNumber: verseNumber)
                }
                dismiss()
            }
        }
    }

    // MARK: - Tafsir Section
    // Two separate cards: tafsir text card + library card below

    private var tafsirSection: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalizedKeys.tafsirComingSoon.value)
                    .font(.custom("Kitab-Regular", size: 16))
                    .customForeground(.onSurface)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)

                Button(action: { print("📋 Tafsir summary tapped") }) {
                    Text(AppLocalizedKeys.tafsirSummary.value)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorStyle.primary.color)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceContainerLow)
            )

            // Card 2 — library navigation card
            actionCard(icon: "books.vertical.fill", title: AppLocalizedKeys.library.value, hasChevron: true) {
                print("📋 Library tapped")
            }
        }
    }

    // MARK: - Sharing Buttons
    // Share card is flexible width; download and copy are fixed-size square cards

    private var sharingButtons: some View {
        HStack(spacing: 12) {
            actionCard(icon: "square.and.arrow.up", title: AppLocalizedKeys.share.value, hasChevron: true) {
                print("📋 Share tapped")
            }

            squareIconCard(icon: "arrow.down.to.line") {
                print("📋 Save image tapped")
            }

            squareIconCard(icon: "doc.on.doc") {
                print("📋 Copy text tapped")
            }
        }
    }

    // MARK: - Highlight Colors

    private var highlightColors: some View {
        HStack(spacing: 12) {
            ForEach(Array(highlightColorOptions.enumerated()), id: \.offset) { _, color in
                Button(action: { print("📋 Highlight color tapped") }) {
                    Circle()
                        .fill(color)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }

            Button(action: { print("📋 Clear highlight") }) {
                Circle()
                    .stroke(ColorStyle.primary.color, lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "nosign")
                            .font(.system(size: 22))
                            .foregroundColor(ColorStyle.primary.color)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var highlightColorOptions: [Color] {
        [
            Color.purple.opacity(0.55),
            Color.blue.opacity(0.45),
            Color.green.opacity(0.5),
            Color.cyan.opacity(0.65),
            Color.orange.opacity(0.55)
        ]
    }

    // MARK: - Reusable Action Card
    // Layout: icon → title (leading side) | Spacer | chevron.backward (trailing side, auto-mirrors)
    // In RTL: leading = right physically, trailing = left physically — no manual flipping needed

    private func actionCard(
        icon: String,
        title: String,
        iconColor: Color? = nil,
        hasChevron: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor ?? ColorStyle.primary.color)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .customForeground(.onSurface)

                if hasChevron {
                    Spacer()
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorStyle.primary.color)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.surfaceContainerLow)
            )
        }
    }

    // MARK: - Square Icon-Only Card (for sharing row)

    private func squareIconCard(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(ColorStyle.primary.color)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceContainerLow)
                )
        }
    }
}
