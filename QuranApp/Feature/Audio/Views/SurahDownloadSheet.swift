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
        .appDirection()
        .onAppear { buildGroups() }
        .onChange(of: downloads.activeDownloads.count) { _, _ in refreshID = UUID() }
        .onChange(of: downloads.deleteTick) { _, _ in refreshID = UUID() }
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
                        Text(AppLocalizedKeys.back.value)
                            .customStyle(.kitab(size: 14), .primary)
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 12))
                            .customForeground(.primary)
                    }
                }
            } else {
                Color.clear.frame(width: 60)
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
            // Action icon — left
            Group {
                if isDownloaded {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(.systemRed).opacity(0.8))
                } else if isDownloading {
                    ProgressView()
                        .tint(ColorStyle.primary.color)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 20))
                        .foregroundColor(ColorStyle.primary.color)
                }
            }
            .frame(width: 26, height: 26)

            Spacer()

            // Surah name — right
            Text("\(arabicIndic(surah.id)). \(surah.arabicName)")
                .customStyle(.kitab(size: 16), .onSurface)
                .id(refreshID)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture {
            if isDownloaded {
                downloads.deleteSurah(for: reciter, surahNumber: surah.id)
            } else if !isDownloading {
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
            let name = ReciterLibrary.surahArabicNames[surahNum] ?? String(format: AppLocalizedKeys.surahFallback.value, surahNum)
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
        AppLocalizedKeys.juzKey(juz).value
    }
}
