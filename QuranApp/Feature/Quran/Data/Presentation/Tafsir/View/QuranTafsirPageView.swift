//
//  QuranTafsirPageView.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - QuranTafsirPageView

struct QuranTafsirPageView: View {

    let pageNumber: Int
    @ObservedObject var viewModel: QuranViewModel
    @ObservedObject private var storage = StorageManager.shared
    @Environment(\.colorScheme) var colorScheme

    @State private var tafsirTexts: [Int: String] = [:]

    private let quranDB = QuranDatabase.shared

    private var isDarkMode: Bool { colorScheme == .dark }
    private var textColor: Color { isDarkMode ? .white : .black }

    private var bookId: String {
        if case .tafsir(let id) = storage.getSettings()?.mushafDisplayType {
            return id
        }
        return TafsirBook.default.id
    }

    private var pageJuz: Int {
        quranDB.getJuz(forPage: pageNumber)
    }

    private var pageSurahName: String {
        let surahNumber = quranDB.getSurahsForPage(pageNumber).first?.id
            ?? quranDB.getVersesForPage(pageNumber).first?.chapterNumber
        guard let number = surahNumber else { return "" }
        return ReciterLibrary.surahArabicNames[number] ?? ""
    }

    private var firstVerseNumber: Int {
        quranDB.getVersesForPage(pageNumber)
            .min(by: { $0.markerLine < $1.markerLine })?.number ?? 1
    }

    // MARK: - Data

    private struct VerseEntry: Identifiable {
        let id: Int
        let surahNumber: Int
        let verseNumber: Int
        let text: String
        let bismillahText: String? // non-nil: show bismillah as a standalone line above the verse
        let showHeader: Bool
        let surahName: String
    }

    // Surah Al-Fatiha verse 1 text is the canonical bismillah after BOM stripping
    private static let bismillahPrefix: String = QuranTextService.shared.text(surah: 1, verse: 1) ?? ""

    private var verseEntries: [VerseEntry] {
        let verses = quranDB.getVersesForPage(pageNumber)
            .sorted {
                if $0.markerLine != $1.markerLine { return $0.markerLine < $1.markerLine }
                return $0.markerCenterX > $1.markerCenterX
            }

        let headerChapterNumbers = Set(
            quranDB.getChapterHeaders(forPage: pageNumber).map { $0.chapterNumber }
        )

        let bismillah = Self.bismillahPrefix
        var result: [VerseEntry] = []
        var renderedHeaders = Set<Int>()

        for verse in verses {
            let showHeader = headerChapterNumbers.contains(verse.chapterNumber)
                          && !renderedHeaders.contains(verse.chapterNumber)
            renderedHeaders.insert(verse.chapterNumber)

            let fullText = QuranTextService.shared.text(surah: verse.chapterNumber, verse: verse.number) ?? ""
            let surahName = ReciterLibrary.surahArabicNames[verse.chapterNumber] ?? ""

            // Split bismillah from verse 1 of every surah except Al-Fatiha (1) and At-Tawbah (9)
            let splitBismillah = verse.number == 1
                && showHeader
                && verse.chapterNumber != 1
                && verse.chapterNumber != 9
                && !bismillah.isEmpty
                && fullText.hasPrefix(bismillah)

            let displayText = splitBismillah
                ? String(fullText.dropFirst(bismillah.count)).trimmingCharacters(in: .whitespaces)
                : fullText

            result.append(VerseEntry(
                id: verse.verseID,
                surahNumber: verse.chapterNumber,
                verseNumber: verse.number,
                text: displayText,
                bismillahText: splitBismillah ? bismillah : nil,
                showHeader: showHeader,
                surahName: surahName
            ))
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            tafsirHeaderBar
                .padding(.top, 8)
                .padding(.bottom, 4)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .center, spacing: 24) {
                    ForEach(verseEntries) { entry in
                        if entry.showHeader {
                            chapterHeaderBanner(surahName: entry.surahName)
                                .padding(.bottom, 4)
                        }
                        verseBlock(entry: entry)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.toggleOverlay()
                }
            }

            QuranPageFooterBar(
                pageNumber: pageNumber,
                isDarkMode: isDarkMode,
                theme: storage.getSettings()?.selectedTheme ?? .classic
            )
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(edges: .horizontal)
        .task(id: pageNumber) {
            await loadTafsir()
        }
    }

    // MARK: - Header Bar

    private var tafsirHeaderBar: some View {
        HStack {
            Text(verbatim: "الجزء \(pageJuz.arabicNumerals)")
                .customStyle(.kitab(size: 17))
                .foregroundColor(textColor.opacity(0.55))
            Spacer()
            Text(pageSurahName)
                .customStyle(.kitab(size: 17))
                .foregroundColor(textColor.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .allowsHitTesting(false)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Chapter Header Banner

    @ViewBuilder
    private func chapterHeaderBanner(surahName: String) -> some View {
        let isTinted = storage.getSettings()?.selectedTheme == .tinted
        let imageName = isTinted ? "newClassicChapterHeader" : "tintedChapterHeader"
        let labelColor: Color = isDarkMode
            ? .white.opacity(0.85)
            : Color(red: 0.18, green: 0.13, blue: 0.08)

        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)

            Text(surahName)
                .font(.custom("KFGQPCHafsSmart-Regular", size: 20))
                .foregroundColor(labelColor)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Verse Block

    private func verseBlock(entry: VerseEntry) -> some View {
        VStack(spacing: 12) {
            if let bismillah = entry.bismillahText {
                bismillahLine(bismillah)
            }
            verseText(entry.text, entry: entry)
            tafsirCard(verseID: entry.id)
        }
    }

    // MARK: - Bismillah Line

    private func bismillahLine(_ text: String) -> some View {
        Text(text)
            .font(.custom("KFGQPCHafsSmart-Regular", size: 26))
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Verse Text

    private func verseText(_ text: String, entry: VerseEntry) -> some View {
        let theme = storage.getSettings()?.selectedTheme ?? .classic
        let fontSize: CGFloat = 26
        let badgeImage = QuranGlyphRenderer.verseMarkerImage(
            entry.verseNumber,
            lineHeight: fontSize * 1.8,
            isDarkMode: isDarkMode,
            theme: theme
        )

        return (Text(text) + Text("\u{00A0}") + Text(Image(uiImage: badgeImage)))
            .font(.custom("KFGQPCHafsSmart-Regular", size: fontSize))
            .lineSpacing(10)
            .multilineTextAlignment(.center)
            .foregroundColor(textColor)
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

    // MARK: - Tafsir Card

    private func tafsirCard(verseID: Int) -> some View {
        TafsirCardView(tafsir: tafsirTexts[verseID], isDarkMode: isDarkMode)
    }

    // MARK: - Async Tafsir Load

    private func loadTafsir() async {
        let entries = verseEntries
        let id = bookId
        tafsirTexts = [:]
        await withTaskGroup(of: (Int, String?).self) { group in
            for entry in entries {
                group.addTask {
                    let text = try? await TafsirService.shared.fetch(
                        bookId: id,
                        surah: entry.surahNumber,
                        verse: entry.verseNumber
                    )
                    return (entry.id, text)
                }
            }
            for await (verseID, text) in group {
                if let text { tafsirTexts[verseID] = text }
            }
        }
    }
}
