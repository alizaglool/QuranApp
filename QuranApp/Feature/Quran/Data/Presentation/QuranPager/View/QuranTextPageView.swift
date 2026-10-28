//
//  QuranTextPageView.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - QuranTextPageView

struct QuranTextPageView: View {

    let pageNumber: Int
    @ObservedObject var viewModel: QuranViewModel
    @ObservedObject private var storage = StorageManager.shared
    @Environment(\.colorScheme) var colorScheme

    private let quranDB = QuranDatabase.shared


    private var pageSurahName: String {
        let surahNumber = quranDB.getSurahsForPage(pageNumber).first?.id
            ?? quranDB.getVersesForPage(pageNumber).first?.chapterNumber
        guard let number = surahNumber else { return "" }
        return ReciterLibrary.surahArabicNames[number] ?? ""
    }

    private var pageJuzNumber: Int {
        quranDB.getJuz(forPage: pageNumber)
    }

    // MARK: - Data

    private struct VerseEntry: Identifiable {
        let id: Int
        let surahNumber: Int
        let verseNumber: Int
        let text: String
        let showHeader: Bool
    }

    private var verseEntries: [VerseEntry] {
        let verses = quranDB.getVersesForPage(pageNumber)
            .sorted {
                if $0.markerLine != $1.markerLine { return $0.markerLine < $1.markerLine }
                return $0.markerCenterX > $1.markerCenterX
            }

        let headerChapterNumbers = Set(
            quranDB.getChapterHeaders(forPage: pageNumber).map { $0.chapterNumber }
        )

        var result: [VerseEntry] = []
        var renderedHeaders = Set<Int>()

        for verse in verses {
            let showHeader = headerChapterNumbers.contains(verse.chapterNumber)
                          && !renderedHeaders.contains(verse.chapterNumber)
            renderedHeaders.insert(verse.chapterNumber)

            let text = QuranTextService.shared.text(surah: verse.chapterNumber, verse: verse.number) ?? ""

            result.append(VerseEntry(
                id:          verse.verseID,
                surahNumber: verse.chapterNumber,
                verseNumber: verse.number,
                text:        text,
                showHeader:  showHeader
            ))
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            QuranPageHeaderBar(surahName: pageSurahName, juzNumber: pageJuzNumber)
                .padding(.top, 8)
                .padding(.bottom, 4)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .center, spacing: 20) {
                        ForEach(verseEntries) { entry in
                            if entry.showHeader {
                                chapterHeaderImage
                                    .padding(.bottom, 4)
                            }
                            verseText(entry.text, entry: entry)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 16)
                                .background {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.surfaceContainerLow)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(ColorStyle.primary.color.opacity(isSelected(entry) ? 0.15 : 0))
                                        }
                                }
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onTapGesture {
                    if hasVisibleHighlight {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.clearSelection()
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.toggleOverlay()
                        }
                    }
                }
                .onAppear {
                    scrollToPendingVerse(proxy)
                }
                .onChange(of: viewModel.pendingScrollVerseID) { _, _ in
                    scrollToPendingVerse(proxy)
                }
            }

            QuranPageFooterBar(
                pageNumber: pageNumber,
                theme: storage.getSettings()?.selectedTheme ?? .tinted
            )
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .horizontal)
    }

    // MARK: - Selection

    private var hasVisibleHighlight: Bool {
        viewModel.selectedPage == pageNumber && viewModel.selectedVerseID != nil
    }

    private func isSelected(_ entry: VerseEntry) -> Bool {
        viewModel.selectedPage == pageNumber && viewModel.selectedVerseID == entry.id
    }

    private func scrollToPendingVerse(_ proxy: ScrollViewProxy) {
        guard let verseID = viewModel.pendingScrollVerseID,
              viewModel.selectedPage == pageNumber,
              verseEntries.contains(where: { $0.id == verseID })
        else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            proxy.scrollTo(verseID, anchor: .center)
        }
        viewModel.pendingScrollVerseID = nil
    }

    // MARK: - Chapter Header Image

    @ViewBuilder
    private var chapterHeaderImage: some View {
        let isTinted = storage.getSettings()?.selectedTheme == .tinted
        let imageName = isTinted ? "newClassicChapterHeader" : "tintedChapterHeader"
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
    }

    // MARK: - Verse Text

    private func verseText(_ text: String, entry: VerseEntry) -> some View {
        let theme      = storage.getSettings()?.selectedTheme ?? .tinted
        let fontSize: CGFloat = 26
        let badgeImage = QuranGlyphRenderer.verseMarkerImage(
            entry.verseNumber,
            lineHeight: fontSize * 1.8,
            scheme: colorScheme,
            theme: theme
        )

        return (Text(text) + Text("\u{00A0}") + Text(Image(uiImage: badgeImage)))
            .font(QuranFont.hafs.font(size: fontSize))
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .foregroundColor(.quranText)
            .frame(maxWidth: .infinity, alignment: .center)
            .environment(\.layoutDirection, .rightToLeft)
            .contentShape(Rectangle())
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                    viewModel.selectVerseDirectly(
                        verseID: entry.id,
                        surahNumber: entry.surahNumber,
                        verseNumber: entry.verseNumber,
                        pageNumber: pageNumber
                    )
                }
            )
    }

}
