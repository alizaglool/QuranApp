//
//  SurahListSheet.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - SurahListSheet

struct SurahListSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentSurahNumber: Int
    let currentPage: Int
    let onSelectSurah: (Int) -> Void
    let onSelectPage: ((Int) -> Void)?

    @State private var selectedTab = 0   // 0 = السور, 1 = الأرباع

    private let db = QuranDatabase.shared
    private let surahsByJuz: [(juz: Int, surahs: [SurahInfo])]
    private let quartersByJuz: [(juz: Int, quarters: [QuarterEntry])]

    // MARK: - Quarter entry model

    struct QuarterEntry: Identifiable {
        let id: Int                 // 0…239 (global index)
        let hizbNumber: Int         // 1…60
        let quarterInHizb: Int      // 1…4; 1 = hizb start, 2-4 = inner quarter
        let surahNumber: Int
        let verseNumber: Int
        let page: Int
        let surahName: String

        var isHizbStart: Bool { quarterInHizb == 1 }
    }

    // MARK: - Init

    init(currentSurahNumber: Int,
         currentPage: Int = 1,
         onSelectSurah: @escaping (Int) -> Void,
         onSelectPage: ((Int) -> Void)? = nil) {
        self.currentSurahNumber = currentSurahNumber
        self.currentPage = currentPage
        self.onSelectSurah = onSelectSurah
        self.onSelectPage = onSelectPage

        let db = QuranDatabase.shared

        // Build surahs grouped by juz
        var grouped: [Int: [SurahInfo]] = [:]
        for surah in db.getAllSurahs() {
            let juz = db.getJuz(forPage: surah.startPage)
            grouped[juz, default: []].append(surah)
        }
        surahsByJuz = grouped.sorted { $0.key < $1.key }
            .map { (juz: $0.key, surahs: $0.value) }

        // Build quarters grouped by juz
        let surahNames = ReciterLibrary.surahArabicNames
        var qsByJuz: [Int: [QuarterEntry]] = [:]
        for (idx, pos) in Self.quarterPositions.enumerated() {
            let hizbNumber = idx / 4 + 1
            let quarterInHizb = idx % 4 + 1
            let page = db.getPage(forSurah: pos.surah, verse: pos.verse)
            let juz = db.getJuz(forPage: max(1, page))
            let entry = QuarterEntry(
                id: idx,
                hizbNumber: hizbNumber,
                quarterInHizb: quarterInHizb,
                surahNumber: pos.surah,
                verseNumber: pos.verse,
                page: page,
                surahName: surahNames[pos.surah] ?? "سورة \(pos.surah)"
            )
            qsByJuz[juz, default: []].append(entry)
        }
        quartersByJuz = qsByJuz.sorted { $0.key < $1.key }
            .map { (juz: $0.key, quarters: $0.value) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            grabHandle
            header
            titleView

            ScrollViewReader { proxy in
                // LTR: sidebar on physical LEFT, content on physical RIGHT
                HStack(spacing: 0) {
                    juzSidebar(proxy: proxy)

                    if selectedTab == 0 {
                        surahListContent(proxy: proxy)
                    } else {
                        quartersContent(proxy: proxy)
                    }
                }
                .environment(\.layoutDirection, .leftToRight)
            }
        }
        .background(Color.background.ignoresSafeArea())
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

    // MARK: - Header (LTR: [dismiss circle] [spacer] [segmented control] [spacer] [placeholder])

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.secondary.opacity(0.12), in: Circle())
            }

            Spacer()

            segmentedControl

            Spacer()

            Spacer()
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .environment(\.layoutDirection, .leftToRight)
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segTab(title: AppLocalizedKeys.surahs.value, index: 0)
            segTab(title: AppLocalizedKeys.quarters.value, index: 1)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
        )
        .frame(height: 36)
    }

    private func segTab(title: String, index: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { selectedTab = index } } label: {
            Text(title)
                .customStyle(.kitab(size: 14))                .foregroundColor(selectedTab == index ? .primary : .secondary)
                .frame(width: 90, height: 36)
                .background(
                    Group {
                        if selectedTab == index {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color(.systemGray3))
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Title ("الفهرس" right-aligned)

    private var titleView: some View {
        Text(AppLocalizedKeys.surahIndex.value)
            .customStyle(.kitab(size: 36, bold: true), .onSurface)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Juz Sidebar (physical LEFT, LTR internal)

    private func juzSidebar(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            ForEach(1...30, id: \.self) { juz in
                Button {
                    withAnimation {
                        if selectedTab == 0 {
                            if let first = surahsByJuz.first(where: { $0.juz == juz })?.surahs.first {
                                proxy.scrollTo("surah_\(first.id)", anchor: .top)
                            }
                        } else {
                            if let first = quartersByJuz.first(where: { $0.juz == juz })?.quarters.first {
                                proxy.scrollTo("quarter_\(first.id)", anchor: .top)
                            }
                        }
                    }
                } label: {
                    Text(arabicIndic(juz))
                        .customStyle(.kitab(size: 9, bold: true), .primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 24)
        .padding(.vertical, 4)
    }

    // MARK: - Surah List (السور tab) — RTL rows

    private func surahListContent(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(surahsByJuz, id: \.juz) { group in
                    juzSectionHeader(group.juz)

                    ForEach(group.surahs) { surah in
                        VStack(spacing: 0) {
                            surahRow(surah)
                            Divider().opacity(0.15)
                        }
                        .id("surah_\(surah.id)")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectSurah(surah.id)
                            dismiss()
                        }
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            proxy.scrollTo("surah_\(currentSurahNumber)", anchor: .center)
        }
    }

    // Juz header — right-aligned Arabic ("الجزء الأول")
    private func juzSectionHeader(_ juz: Int) -> some View {
        Text(juzName(juz))
            .customStyle(.kitab(size: 13))            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)  // .leading in RTL = physical RIGHT
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }

    // Row: badge on RIGHT, name+subtitle to the LEFT (RTL HStack)
    private func surahRow(_ surah: SurahInfo) -> some View {
        let isCurrent = surah.id == currentSurahNumber
        return HStack(spacing: 14) {
            // First child = physical RIGHT in RTL: number badge
            ZStack {
                Circle()
                    .fill(isCurrent ? ColorStyle.primary.color : Color(.systemGray5))
                    .frame(width: 40, height: 40)
                Text(arabicIndic(surah.id))
                    .customStyle(.kitab(size: 13, bold: true))                    .foregroundColor(isCurrent ? .white : ColorStyle.primary.color)
            }

            // Second child = physical LEFT of badge: name + subtitle, right-aligned text
            VStack(alignment: .leading, spacing: 3) {  // .leading in RTL = physical RIGHT
                Text(surah.arabicTitle)
                    .customStyle(.kitab(size: 19, bold: true), .onSurface)

                Text("\(AppLocalizedKeys.pagePrefix.value) \(arabicIndic(surah.startPage)) - \(arabicIndic(surah.versesCount)) \(AppLocalizedKeys.verses.value) - \(surah.isMeccan ? AppLocalizedKeys.meccan.value : AppLocalizedKeys.medinan.value)")
                    .customStyle(.kitab(size: 12))                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // fill remaining, text anchored RIGHT
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Quarters Content (الأرباع tab) — RTL rows

    private func quartersContent(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(quartersByJuz, id: \.juz) { group in
                    juzSectionHeader(group.juz)

                    ForEach(group.quarters) { entry in
                        VStack(spacing: 0) {
                            quarterRow(entry)
                            Divider().opacity(0.15)
                        }
                        .id("quarter_\(entry.id)")
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let navigate = onSelectPage {
                                navigate(entry.page)
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear {
            let closest = quartersByJuz.flatMap(\.quarters)
                .min(by: { abs($0.page - currentPage) < abs($1.page - currentPage) })
            if let c = closest {
                proxy.scrollTo("quarter_\(c.id)", anchor: .center)
            }
        }
    }

    // Row: badge on RIGHT, surah name + subtitle to the LEFT (RTL HStack)
    private func quarterRow(_ entry: QuarterEntry) -> some View {
        HStack(spacing: 14) {
            // First child = physical RIGHT in RTL: hizb badge
            ZStack {
                Circle()
                    .fill(entry.isHizbStart ? ColorStyle.primary.color : Color(.systemGray5))
                    .frame(width: 40, height: 40)

                if entry.isHizbStart {
                    Text(arabicIndic(entry.hizbNumber))
                        .customStyle(.kitab(size: 13, bold: true))                        .foregroundColor(.white)
                } else {
                    quarterIcon(entry.quarterInHizb)
                }
            }

            // Second child = physical LEFT: surah name + verse info
            VStack(alignment: .leading, spacing: 3) {  // .leading in RTL = physical RIGHT
                Text(entry.surahName)
                    .customStyle(.kitab(size: 17, bold: true), .onSurface)

                Text("\(entry.surahName): \(arabicIndic(entry.verseNumber)) - \(AppLocalizedKeys.pagePrefix.value) \(arabicIndic(entry.page))")
                    .customStyle(.kitab(size: 12))                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .environment(\.layoutDirection, .rightToLeft)
    }

    /// Pie-slice icon representing how far into the hizb this quarter is.
    private func quarterIcon(_ quarterInHizb: Int) -> some View {
        let fraction: Double = Double(quarterInHizb - 1) / 4.0
        return Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            var path = Path()
            path.move(to: center)
            path.addArc(center: center, radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90 + 360 * fraction),
                        clockwise: false)
            path.closeSubpath()
            context.fill(path, with: .color(Color.secondary.opacity(0.6)))
        }
        .frame(width: 20, height: 20)
    }

    // MARK: - Helpers

    private func arabicIndic(_ n: Int) -> String {
        let digits = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c in
            guard let d = c.wholeNumberValue else { return String(c) }
            return digits[d]
        }.joined()
    }

    private func juzName(_ juz: Int) -> String {
        AppLocalizedKeys.juzKey(juz).value
    }

    // MARK: - Static quarter data (240 entries: 60 aḥzāb × 4 quarters each)

    private static let quarterPositions: [(surah: Int, verse: Int)] = [
        // Hizb 1
        (1, 1), (2, 26), (2, 44), (2, 62),
        // Hizb 2
        (2, 75), (2, 92), (2, 107), (2, 122),
        // Hizb 3
        (2, 142), (2, 158), (2, 177), (2, 190),
        // Hizb 4
        (2, 203), (2, 219), (2, 233), (2, 246),
        // Hizb 5
        (2, 253), (2, 268), (2, 283), (3, 1),
        // Hizb 6
        (3, 11), (3, 31), (3, 48), (3, 62),
        // Hizb 7
        (3, 75), (3, 93), (3, 113), (3, 133),
        // Hizb 8
        (3, 150), (3, 168), (3, 187), (4, 1),
        // Hizb 9
        (4, 12), (4, 25), (4, 36), (4, 52),
        // Hizb 10
        (4, 58), (4, 72), (4, 88), (4, 101),
        // Hizb 11
        (4, 114), (4, 128), (4, 142), (4, 155),
        // Hizb 12
        (4, 163), (4, 176), (5, 1),  (5, 13),
        // Hizb 13
        (5, 27), (5, 41), (5, 53), (5, 68),
        // Hizb 14
        (5, 82), (5, 96), (5, 109), (6, 1),
        // Hizb 15
        (6, 20), (6, 36), (6, 53), (6, 69),
        // Hizb 16
        (6, 84), (6, 103), (6, 119), (6, 136),
        // Hizb 17
        (6, 151), (7, 1),  (7, 18), (7, 32),
        // Hizb 18
        (7, 46), (7, 66), (7, 88), (7, 110),
        // Hizb 19
        (7, 128), (7, 146), (7, 160), (7, 171),
        // Hizb 20
        (7, 189), (8, 1),  (8, 17), (8, 32),
        // Hizb 21
        (8, 41), (8, 56), (8, 69), (9, 1),
        // Hizb 22
        (9, 18), (9, 34), (9, 48), (9, 60),
        // Hizb 23
        (9, 72), (9, 88), (9, 100), (9, 112),
        // Hizb 24
        (9, 122), (10, 1), (10, 26), (10, 53),
        // Hizb 25
        (10, 71), (10, 90), (11, 1), (11, 19),
        // Hizb 26
        (11, 36), (11, 54), (11, 72), (11, 96),
        // Hizb 27
        (11, 111), (12, 1),  (12, 21), (12, 38),
        // Hizb 28
        (12, 53), (12, 70), (12, 89), (13, 1),
        // Hizb 29
        (13, 19), (14, 1),  (14, 22), (15, 1),
        // Hizb 30
        (15, 50), (15, 85), (16, 1),  (16, 31),
        // Hizb 31
        (16, 51), (16, 71), (16, 91), (16, 111),
        // Hizb 32
        (16, 128), (17, 1), (17, 23), (17, 50),
        // Hizb 33
        (17, 70), (17, 99), (18, 1),  (18, 22),
        // Hizb 34
        (18, 42), (18, 60), (18, 83), (19, 1),
        // Hizb 35
        (19, 39), (19, 65), (20, 1),  (20, 53),
        // Hizb 36
        (20, 82), (20, 116), (21, 1), (21, 29),
        // Hizb 37
        (21, 51), (21, 83), (22, 1),  (22, 19),
        // Hizb 38
        (22, 38), (22, 60), (23, 1),  (23, 29),
        // Hizb 39
        (23, 57), (23, 90), (24, 1),  (24, 21),
        // Hizb 40
        (24, 36), (24, 53), (25, 1),  (25, 21),
        // Hizb 41
        (25, 44), (26, 1),  (26, 42), (26, 84),
        // Hizb 42
        (26, 125), (26, 165), (26, 196), (27, 1),
        // Hizb 43
        (27, 26), (27, 56), (28, 1),  (28, 22),
        // Hizb 44
        (28, 44), (28, 61), (29, 1),  (29, 26),
        // Hizb 45
        (29, 46), (30, 1),  (30, 29), (31, 1),
        // Hizb 46
        (31, 22), (32, 1),  (33, 1),  (33, 22),
        // Hizb 47
        (33, 51), (34, 1),  (34, 24), (35, 1),
        // Hizb 48
        (35, 29), (36, 1),  (36, 28), (36, 60),
        // Hizb 49
        (37, 1),  (37, 65), (37, 145), (38, 1),
        // Hizb 50
        (38, 38), (39, 1),  (39, 22), (39, 48),
        // Hizb 51
        (39, 71), (40, 1),  (40, 29), (40, 57),
        // Hizb 52
        (41, 1),  (41, 25), (41, 47), (42, 1),
        // Hizb 53
        (42, 27), (43, 1),  (43, 36), (43, 68),
        // Hizb 54
        (44, 1),  (45, 1),  (46, 1),  (46, 20),
        // Hizb 55
        (47, 1),  (47, 21), (48, 1),  (48, 20),
        // Hizb 56
        (49, 1),  (51, 1),  (52, 1),  (53, 1),
        // Hizb 57
        (54, 1),  (55, 1),  (56, 1),  (57, 1),
        // Hizb 58
        (58, 1),  (59, 1),  (60, 1),  (61, 1),
        // Hizb 59
        (62, 1),  (63, 1),  (64, 1),  (65, 1),
        // Hizb 60
        (67, 1),  (69, 1),  (72, 1),  (78, 1),
    ]
}
