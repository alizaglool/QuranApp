//
//  SurahDownloadSheet.swift
//  QuranApp
//

import SwiftUI
import Core

struct SurahDownloadSheet: View {
    let reciter: ReciterInfo
    let onBack: (() -> Void)?

    @ObservedObject private var downloads = DownloadManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var juzGroups: [(juz: Int, name: String, surahs: [SurahRow])] = []
    @State private var refreshID = UUID()

    private let quranDB = QuranDatabase.shared

    struct SurahRow: Identifiable {
        let id: Int
        let arabicName: String
        let juz: Int
    }

    var body: some View {
        VStack(spacing: 0) {
            grabHandle
            header
            ZStack(alignment: .trailing) {
                surahList
                juzIndexOverlay
            }
        }
        .background(Color.background)
        .onAppear { buildGroups() }
        .onChange(of: downloads.activeDownloads.count) { _, _ in refreshID = UUID() }
    }

    // MARK: - Grab Handle

    private var grabHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 30, height: 30)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            Text(reciter.arabicName)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

            Spacer()

            if let onBack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Text(AppLocalizedKeys.reciterSelection.value)
                            .customStyle(.kitab(size: 14), .primary)
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 12))
                            .customForeground(.primary)
                    }
                }
            } else {
                Color.clear.frame(width: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.background)
    }

    // MARK: - Surah List

    private var surahList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: []) {
                    ForEach(juzGroups, id: \.juz) { group in
                        juzSection(group: group, proxy: proxy)
                            .id("juz_\(group.juz)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
                .padding(.trailing, 28)
            }
        }
    }

    @ViewBuilder
    private func juzSection(group: (juz: Int, name: String, surahs: [SurahRow]), proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack {
                Menu {
                    Button(action: { downloadJuz(group.surahs) }) {
                        Label(AppLocalizedKeys.downloadJuz.value, systemImage: "arrow.down.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                }

                Spacer()

                Text(group.name)
                    .customStyle(.kitab(size: 17, bold: true), .onSurface)
            }

            VStack(spacing: 0) {
                ForEach(Array(group.surahs.enumerated()), id: \.element.id) { idx, surah in
                    surahRow(surah)
                    if idx < group.surahs.count - 1 {
                        Divider().padding(.leading, 52)
                    }
                }
            }
            .background(Color.surfaceContainerLow)
            .customCornerRadius(12)
        }
    }

    @ViewBuilder
    private func surahRow(_ surah: SurahRow) -> some View {
        let isDownloaded  = downloads.isSurahFullyDownloaded(reciterSlug: reciter.id, surahNumber: surah.id)
        let isDownloading = downloads.isSurahDownloading(reciterSlug: reciter.id, surahNumber: surah.id)

        HStack(spacing: 12) {
            // Download / status icon
            Group {
                if isDownloaded {
                    Image(systemName: "checkmark.circle.fill")
                        .customForeground(.primary)
                } else if isDownloading {
                    ProgressView()
                        .tint(ColorStyle.primary.color)
                } else {
                    Image(systemName: "icloud.and.arrow.down")
                        .customForeground(.primary)
                }
            }
            .customStyle(.kitab(size: 22))            .frame(width: 32, height: 32)

            Text("\(arabicIndic(surah.id)). \(surah.arabicName)")
                .customStyle(.kitab(size: 16), .onSurface)
                .id(refreshID)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isDownloaded && !isDownloading {
                downloads.downloadSurah(for: reciter, surahNumber: surah.id)
            }
        }
    }

    // MARK: - Juz Index Overlay

    private var juzIndexOverlay: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                ForEach(1...30, id: \.self) { juz in
                    Button(action: {
                        withAnimation {
                            proxy.scrollTo("juz_\(juz)", anchor: .top)
                        }
                    }) {
                        Text(arabicIndic(juz))
                            .customStyle(.kitab(size: 9))
                            .foregroundColor(juzGroups.contains { $0.juz == juz }
                                             ? ColorStyle.primary.color : .secondary)
                            .frame(width: 20, height: 16)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color.clear)
        }
        .frame(width: 24)
    }

    // MARK: - Helpers

    private func arabicIndic(_ n: Int) -> String {
        let digits = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c in
            guard let d = c.wholeNumberValue else { return String(c) }
            return digits[d]
        }.joined()
    }

    private func downloadJuz(_ surahs: [SurahRow]) {
        for surah in surahs {
            downloads.downloadSurah(for: reciter, surahNumber: surah.id)
        }
    }

    private func buildGroups() {
        var groups: [Int: (name: String, surahs: [SurahRow])] = [:]
        for surahNum in 1...114 {
            let page = quranDB.getStartPage(forSurah: surahNum)
            let juz  = quranDB.getJuz(forPage: page)
            let name = ReciterLibrary.surahArabicNames[surahNum] ?? "سورة \(surahNum)"
            let row  = SurahRow(id: surahNum, arabicName: name, juz: juz)
            if groups[juz] == nil {
                groups[juz] = (juzName(juz), [row])
            } else {
                groups[juz]?.surahs.append(row)
            }
        }
        juzGroups = groups
            .sorted { $0.key < $1.key }
            .map { (juz: $0.key, name: $0.value.name, surahs: $0.value.surahs) }
    }

    private func juzName(_ juz: Int) -> String {
        let names = [
            1:"الجزء الأول", 2:"الجزء الثاني", 3:"الجزء الثالث",
            4:"الجزء الرابع", 5:"الجزء الخامس", 6:"الجزء السادس",
            7:"الجزء السابع", 8:"الجزء الثامن", 9:"الجزء التاسع",
            10:"الجزء العاشر", 11:"الجزء الحادي عشر", 12:"الجزء الثاني عشر",
            13:"الجزء الثالث عشر", 14:"الجزء الرابع عشر", 15:"الجزء الخامس عشر",
            16:"الجزء السادس عشر", 17:"الجزء السابع عشر", 18:"الجزء الثامن عشر",
            19:"الجزء التاسع عشر", 20:"الجزء العشرون",
            21:"الجزء الحادي والعشرون", 22:"الجزء الثاني والعشرون",
            23:"الجزء الثالث والعشرون", 24:"الجزء الرابع والعشرون",
            25:"الجزء الخامس والعشرون", 26:"الجزء السادس والعشرون",
            27:"الجزء السابع والعشرون", 28:"الجزء الثامن والعشرون",
            29:"الجزء التاسع والعشرون", 30:"الجزء الثلاثون"
        ]
        return names[juz] ?? "الجزء \(juz)"
    }
}
