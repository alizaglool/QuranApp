//
//  PlayToSheetView.swift
//  QuranApp
//

import SwiftUI
import Core

struct PlayToSheetView: View {

    let page: Int
    let surahNumber: Int
    let surahName: String
    let verseNumber: Int
    /// Called after the user picks a mode and playback starts, so the parent can dismiss.
    var onPlay: (() -> Void)? = nil

    @ObservedObject private var audio = AudioEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSegment: Segment = .verse

    enum Segment: Int, CaseIterable {
        case verse, page, surah
        var label: String {
            switch self {
            case .verse: return "آية"
            case .page:  return "صفحة"
            case .surah: return "سورة"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    quickOptions
                        .padding(.top, 16)

                    // Segmented picker
                    Picker("", selection: $selectedSegment) {
                        ForEach(Segment.allCases, id: \.self) { seg in
                            Text(seg.label).tag(seg)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .environment(\.layoutDirection, .rightToLeft)

                    browseList
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.background)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(AppLocalizedKeys.playTo.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

            HStack {
                // Dismiss button – RTL leading = right; shows on the left side physically
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.outlineVariant.opacity(0.5), in: Circle())
                }
            }

            HStack {
                // Current verse reference badge
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(surahName): \(verseNumber)")
                        .customStyle(.kitab(size: 14, bold: true))
                }
                .foregroundColor(ColorStyle.primary.color)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Quick Options

    private var quickOptions: some View {
        VStack(spacing: 0) {
            quickOptionRow(
                icon: "doc.text.fill",
                title: AppLocalizedKeys.endOfPage.value,
                badge: "الصفحة \(page)"
            ) {
                startPlay(mode: .endOfPage(page: page))
            }
            Divider().padding(.leading, 52)
            quickOptionRow(
                icon: "book.closed.fill",
                title: AppLocalizedKeys.endOfSurah.value,
                badge: surahName
            ) {
                startPlay(mode: .endOfSurah)
            }
            Divider().padding(.leading, 52)
            quickOptionRow(
                icon: "infinity",
                title: AppLocalizedKeys.continuousPlay.value,
                badge: "∞"
            ) {
                startPlay(mode: .continuous)
            }
        }
        .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
    }

    private func quickOptionRow(
        icon: String,
        title: String,
        badge: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(ColorStyle.primary.color)
                    .frame(width: 28)

                Text(title)
                    .customStyle(.kitab(size: 16), .onSurface)

                Spacer()

                Text(badge)
                    .customStyle(.kitab(size: 14))
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.backward")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.outlineVariant)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Browse List

    @ViewBuilder
    private var browseList: some View {
        switch selectedSegment {
        case .verse:  verseBrowseList
        case .page:   pageBrowseList
        case .surah:  surahBrowseList
        }
    }

    // MARK: Verse list

    private var verseBrowseList: some View {
        LazyVStack(spacing: 8, pinnedViews: [.sectionHeaders]) {
            ForEach(1...114, id: \.self) { s in
                let count = max(1, ReciterLibrary.verseCounts[s] ?? 7)
                Section {
                    ForEach(1...count, id: \.self) { v in
                        verseStopRow(surahNum: s, verseNum: v)
                    }
                } header: {
                    Text(ReciterLibrary.surahArabicNames[s] ?? "سورة \(s)")
                        .customStyle(.kitab(size: 12))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.background)
                }
            }
        }
    }

    private func verseStopRow(surahNum: Int, verseNum: Int) -> some View {
        let versePage = QuranDatabase.shared.getPage(forSurah: surahNum, verse: verseNum)
        return Button {
            startPlay(mode: .stopAtVerse(surah: surahNum, verse: verseNum))
        } label: {
            HStack(spacing: 12) {
                Text("ص \(versePage)")
                    .customStyle(.kitab(size: 12))
                    .foregroundColor(ColorStyle.primary.color)
                    .frame(minWidth: 36, alignment: .leading)
                    .environment(\.layoutDirection, .leftToRight)

                Text("\(ReciterLibrary.surahArabicNames[surahNum] ?? ""): \(verseNum)")
                    .customStyle(.kitab(size: 14), .onSurface)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    // MARK: Page list

    private var pageBrowseList: some View {
        LazyVStack(spacing: 8) {
            ForEach(1...604, id: \.self) { p in
                Button {
                    startPlay(mode: .endOfPage(page: p))
                } label: {
                    HStack {
                        if p == page {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(ColorStyle.primary.color)
                        } else {
                            Color.clear.frame(width: 20, height: 20)
                        }
                        Text("الصفحة \(p)")
                            .customStyle(.kitab(size: 15), .onSurface)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: Surah list

    private var surahBrowseList: some View {
        LazyVStack(spacing: 8) {
            ForEach(1...114, id: \.self) { s in
                let lastVerse = max(1, ReciterLibrary.verseCounts[s] ?? 7)
                Button {
                    startPlay(mode: .stopAtVerse(surah: s, verse: lastVerse))
                } label: {
                    HStack {
                        Text("ص \(QuranDatabase.shared.getStartPage(forSurah: s))")
                            .customStyle(.kitab(size: 12))
                            .foregroundColor(ColorStyle.primary.color)
                            .environment(\.layoutDirection, .leftToRight)

                        Text(ReciterLibrary.surahArabicNames[s] ?? "سورة \(s)")
                            .customStyle(.kitab(size: 15), .onSurface)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Helpers

    private func startPlay(mode: PlayToMode) {
        audio.playToMode = mode
        audio.play(surahNumber: surahNumber, verseNumber: verseNumber)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            onPlay?()
        }
    }
}
