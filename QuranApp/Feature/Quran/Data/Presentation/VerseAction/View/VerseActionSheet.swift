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
    @State private var isAllBookmarksPresenting = false
    @State private var isTafsirPresenting = false
    @State private var isPlayToPresenting = false
    @State private var inlineTafsir: String? = nil
    @State private var isCopied = false
    @State private var isTafsirExpanded = false

    // MARK: - Computed helpers

    /// Color currently saved on THIS specific verse (nil = no highlight).
    private var currentVerseHighlightColor: String? {
        _ = storage.bookmarksRevision
        return storage.getBookmark(page: page, ayahNumber: verseNumber)?.color
    }

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

    // Tafsir book used for the inline preview — selected tafsir book or default (المختصر)
    private var selectedTafsirBook: TafsirBook {
        if case .tafsir(let id) = storage.getSettings()?.mushafDisplayType,
           let book = TafsirBook.find(id: id) {
            return book
        }
        if let id = UserDefaults.standard.string(forKey: "selectedTafsirBookId"),
           let book = TafsirBook.find(id: id) {
            return book
        }
        return TafsirBook.default
    }

    private var textColor: Color { colorScheme == .dark ? .white : .black }

    private var verseText: String {
        QuranTextService.shared.text(surah: surahNumber, verse: verseNumber) ?? ""
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
        .task {
            isTafsirExpanded = false
            let book = selectedTafsirBook
            inlineTafsir = try? await TafsirService.shared.fetch(
                bookId: book.id,
                surah: surahNumber,
                verse: verseNumber
            )
        }
        .customSheet(isPresented: $isAllBookmarksPresenting, fraction: 0.45, detents: [.medium]) {
            AllBookmarksView(
                page: page,
                surahNumber: surahNumber,
                surahName: surahName,
                verseNumber: verseNumber,
                onSelected: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        dismiss()
                    }
                }
            )
            .presentationDragIndicator(.visible)
        }
        .customSheet(isPresented: $isTafsirPresenting, fraction: 1.0, detents: [.large]) {
            TafsirView(
                surahNumber: surahNumber,
                verseNumber: verseNumber,
                ref: "\(surahName): \(verseNumber)",
                onDismissSheet: { isTafsirPresenting = false }
            )
            .presentationDragIndicator(.visible)
        }
        .customSheet(isPresented: $isPlayToPresenting, fraction: 0.88, detents: [.large]) {
            PlayToSheetView(
                page: page,
                surahNumber: surahNumber,
                surahName: surahName,
                verseNumber: verseNumber,
                onPlay: { dismiss() }
            )
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header
    // Leading = Edit button | Center = title | Trailing = X
    // In RTL: leading = right side physically, trailing = left side physically

    private var header: some View {
        HStack {
            Button(action: { }) {
                Text(AppLocalizedKeys.edit.value)
                    .customStyle(.kitab(size: 15), .primary)
            }

            Spacer()

            Text("\(surahName): \(verseNumber)")
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

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
            .customStyle(.kitab(size: 15, bold: true), .onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bookmark Buttons

    private var bookmarkButtons: some View {
        HStack(spacing: 12) {
            actionCard(icon: "list.bullet", title: AppLocalizedKeys.allBookmarks.value, hasChevron: true) {
                isAllBookmarksPresenting = true
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
                        .customStyle(.kitab(size: 14), .onSurface)

                    if let subtitle = inlineSubtitle {
                        Text(subtitle)
                            .customStyle(.kitab(size: 11))
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
                isPlayToPresenting = true
            }

            actionCard(
                icon: audio.isPlaying && isCurrentVerse ? "pause.fill" : "play.fill",
                title: audio.isPlaying && isCurrentVerse ? AppLocalizedKeys.pause.value : AppLocalizedKeys.play.value
            ) {
                if audio.isPlaying && isCurrentVerse {
                    audio.pause()
                } else {
                    audio.playFrom(surahNumber: surahNumber, verseNumber: verseNumber)
                }
                dismiss()
            }
        }
    }

    // MARK: - Tafsir Section

    private static let tafsirCollapsedLines = 4

    private var tafsirSection: some View {
        VStack(spacing: 8) {
            // Inline tafsir card — shows fetched text or a spinner
            VStack(alignment: .trailing, spacing: 10) {
                Group {
                    if let tafsir = inlineTafsir {
                        VStack(alignment: .trailing, spacing: 6) {
                            Text(tafsir)
                                .customStyle(.kitab(size: 15))
                                .foregroundColor(textColor.opacity(0.85))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .lineLimit(isTafsirExpanded ? nil : Self.tafsirCollapsedLines)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isTafsirExpanded.toggle()
                                }
                            } label: {
                                Text(isTafsirExpanded
                                     ? AppLocalizedKeys.seeLess.value
                                     : AppLocalizedKeys.seeMore.value)
                                    .customStyle(.kitab(size: 13))
                                    .foregroundColor(ColorStyle.primary.color)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    } else {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .padding(.vertical, 8)
                    }
                }

                // Book name — green, trailing edge
                Text(selectedTafsirBook.nameArabic)
                    .customStyle(.kitab(size: 13))
                    .foregroundColor(ColorStyle.primary.color)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(14)
            .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 14))
            .environment(\.layoutDirection, .rightToLeft)

            // Library row — opens the full tafsir picker
            actionCard(icon: "books.vertical.fill", title: AppLocalizedKeys.library.value, hasChevron: true) {
                isTafsirPresenting = true
            }
        }
    }

    // MARK: - Sharing Buttons
    // Share card is flexible width; download and copy are fixed-size square cards

    private var sharingButtons: some View {
        HStack(spacing: 12) {
            actionCard(icon: "square.and.arrow.up", title: AppLocalizedKeys.share.value, hasChevron: true) {
                shareVerse()
            }

            squareIconCard(icon: "arrow.down.to.line") {
                // Save as image — premium feature
            }

            squareIconCard(icon: isCopied ? "checkmark" : "doc.on.doc") {
                copyVerse()
            }
        }
    }

    private func shareVerse() {
        let shareText = "\(verseText)\n\n— \(surahName): \(verseNumber)"
        let vc = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }

    private func copyVerse() {
        UIPasteboard.general.string = verseText
        withAnimation(.spring(duration: 0.2)) { isCopied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring(duration: 0.2)) { isCopied = false }
        }
    }

    // MARK: - Highlight Colors

    private var highlightColors: some View {
        let pairs: [(Color, BookmarkColor)] = [
            (Color.purple.opacity(0.55), .purple),
            (Color.blue.opacity(0.45),   .blue),
            (Color.green.opacity(0.5),   .green),
            (Color.cyan.opacity(0.65),   .cyan),
            (Color.orange.opacity(0.55), .orange),
        ]
        return HStack(spacing: 12) {
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                let isActive = currentVerseHighlightColor == pair.1.rawValue
                Button {
                    _ = storage.setBookmarkColor(
                        page: page,
                        surahNumber: surahNumber,
                        surahName: surahName,
                        ayahNumber: verseNumber,
                        color: pair.1.rawValue
                    )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { dismiss() }
                } label: {
                    Circle()
                        .fill(pair.0)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Group {
                                if isActive {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(isActive ? Color.white.opacity(0.6) : Color.clear, lineWidth: 2)
                        )
                }
            }

            Button {
                storage.removeBookmarkForVerse(page: page, ayahNumber: verseNumber)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { dismiss() }
            } label: {
                Circle()
                    .stroke(ColorStyle.primary.color, lineWidth: 2)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "nosign")
                            .font(.system(size: 22))
                            .customForeground(.primary)
                    )
            }
        }
        .frame(maxWidth: .infinity)
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
                    .customStyle(.kitab(size: 14), .onSurface)

                if hasChevron {
                    Spacer()
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 12, weight: .medium))
                        .customForeground(.primary)
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
                .customForeground(.primary)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surfaceContainerLow)
                )
        }
    }
}
