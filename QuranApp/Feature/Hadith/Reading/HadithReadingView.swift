//
//  HadithReadingView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import SwiftUI
import Core

// MARK: - Scholarly Row Model

struct HadithScholarlyItem {
    let icon: String
    let labelEn: String
    let labelAr: String
    let content: String
    let isRTL: Bool
    var hasData: Bool { !content.isEmpty }
}

// MARK: - HadithReadingView

struct HadithReadingView: View {

    @StateObject private var viewModel: HadithReadingViewModel
    @State private var isShareSheetPresenting = false

    init(coordinator: HadithCoordinating, hadiths: [HadithEntry], startIndex: Int,
         book: HadithBook, chapter: HadithChapter, chapters: [HadithChapter]) {
        _viewModel = StateObject(wrappedValue: HadithReadingViewModel(
            coordinator: coordinator, hadiths: hadiths, startIndex: startIndex,
            book: book, chapter: chapter, chapters: chapters))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            ZStack {
                Color.hadithBg.ignoresSafeArea()
                VStack(spacing: 0) {
                    navigationBar
                    Divider().opacity(0.12)
                    navigationBreadcrumb
                    hadithPager
                    Spacer(minLength: 0)
                    Divider().opacity(0.12)
                    readingControlBar.padding(.bottom, .xxBig)
                }
                if viewModel.showJumpInput { jumpToHadithOverlay }
            }
        }
        .navigationBarHidden(true)
        .customSheet(isPresented: $viewModel.showTOC, fraction: 0.75, detents: [.medium, .large]) {
            HadithTOCSheet(
                chapters: viewModel.chapters,
                currentChapterId: viewModel.currentHadith?.chapterId
            ) { chapter in
                viewModel.jumpToChapter(chapter)
                viewModel.showTOC = false
            }
        }
        .customSheet(isPresented: $isShareSheetPresenting, fraction: 0.75, detents: [.medium, .large]) {
            if let h = viewModel.currentHadith {
                let grade = h.grade.isEmpty ? "" : "\n\n[\(h.grade)]"
                ShareSheet(items: ["\(h.arabicText)\n\n\(h.translation)\n\n— \(h.narrator)\(grade)"])
            }
        }
    }

    // MARK: Navigation Bar

    private var navigationBar: some View {
        HStack {
            HadithNavButton(icon: "arrow.backward") { viewModel.goBack() }
            Spacer()
            Text(viewModel.book.title)
                .customStyle(.buttonText, .hadithNav)
                .lineLimit(1)
            Spacer()
            HadithNavButton(icon: "magnifyingglass") { viewModel.showJumpInput = true }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .xSm + 2)
    }

    // MARK: Navigation Breadcrumb

    private var navigationBreadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .xSm) {
                breadcrumbChip(viewModel.book.title, active: true)
                if let ch = viewModel.currentChapter {
                    breadcrumbDot
                    breadcrumbChip(ch.title, active: false)
                }
                if let h = viewModel.currentHadith {
                    breadcrumbDot
                    breadcrumbChip(
                        "\(AppLocalizedKeys.hadithNumber.value.uppercased()) \(h.number)",
                        active: false
                    )
                }
            }
            .padding(.horizontal, .big)
            .padding(.vertical, .xSm + 2)
        }
    }

    private func breadcrumbChip(_ text: String, active: Bool) -> some View {
        VStack(alignment: .leading, spacing: .xxSm - 1) {
            Text(text.uppercased())
                .customStyle(.caption2)
                .tracking(1.0)
                .foregroundColor(active ? Color.hadithNav : Color.hadithSecondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            if active {
                Rectangle().fill(Color.hadithGold).frame(height: 1.5)
            }
        }
        .frame(maxWidth: 130, alignment: .leading)
    }

    private var breadcrumbDot: some View {
        Text("•")
            .customStyle(.adhkar(size: 8))            .foregroundColor(Color.hadithMuted)
    }

    // MARK: Hadith Pager

    private var hadithPager: some View {
        TabView(selection: Binding(
            get: { viewModel.currentIndex },
            set: { viewModel.currentIndex = $0 }
        )) {
            ForEach(viewModel.hadiths.indices, id: \.self) { idx in
                HadithPageContent(hadith: viewModel.hadiths[idx])
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // MARK: Reading Control Bar

    private var readingControlBar: some View {
        HStack(spacing: 0) {
            navigationArrow(icon: "arrow.right", enabled: viewModel.canGoPrevious) { viewModel.previous() }
            Spacer()
            HStack(spacing: .xxBig - 6) {
                HadithBottomBarButton(
                    icon: "list.bullet",
                    label: AppLocalizedKeys.hadithIndexTitle.value
                ) { viewModel.showTOC = true }

                HadithBottomBarButton(
                    icon: "number",
                    label: AppLocalizedKeys.goToHadith.value
                ) { viewModel.showJumpInput = true }

                HadithBottomBarButton(
                    icon: viewModel.isFavorite ? "bookmark.fill" : "bookmark",
                    label: AppLocalizedKeys.bookmark.value,
                    tint: viewModel.isFavorite ? Color.hadithGold : nil
                ) { viewModel.toggleFavorite() }

                HadithBottomBarButton(
                    icon: "square.and.arrow.up",
                    label: AppLocalizedKeys.share.value
                ) { isShareSheetPresenting = true }
            }
            Spacer()
            navigationArrow(icon: "arrow.left", enabled: viewModel.canGoNext) { viewModel.next() }
        }
        .padding(.horizontal, .big)
        .padding(.top, .sm)
    }

    private func navigationArrow(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(enabled ? Color.hadithNav : Color.hadithMuted)
                .frame(width: 44, height: 44)
                .background(Color.hadithCard.opacity(enabled ? 1 : 0.5))
                .cornerRadius(.cornerMd)
        }
        .disabled(!enabled)
    }

    // MARK: Jump-to-Hadith Overlay

    private var jumpToHadithOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showJumpInput = false
                    viewModel.jumpInput = ""
                }
            VStack(spacing: .md + 2) {
                Text(AppLocalizedKeys.jumpToHadith.value)
                    .customStyle(.buttonText)
                    .foregroundColor(.white)
                HStack(spacing: .sm) {
                    TextField("", text: $viewModel.jumpInput)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .customStyle(.bodyMedium)
                        .foregroundColor(.white)
                        .frame(width: 110, height: 50)
                        .background(Color.hadithCard)
                        .cornerRadius(.cornerMd)
                    Button {
                        if let n = Int(viewModel.jumpInput) { viewModel.jumpToHadith(number: n) }
                        viewModel.showJumpInput = false
                        viewModel.jumpInput = ""
                    } label: {
                        Text(AppLocalizedKeys.go.value)
                            .customStyle(.buttonText)
                            .foregroundColor(Color.hadithCard)
                            .frame(width: 80, height: 50)
                            .background(Color.hadithGold)
                            .cornerRadius(.cornerMd)
                    }
                }
            }
            .padding(.xxBig)
            .background(Color.hadithBg.opacity(0.97))
            .cornerRadius(.cornerXxl)
            .shadow(color: .black.opacity(0.5), radius: 24)
        }
    }
}

// MARK: - Hadith Page Content

struct HadithPageContent: View {

    let hadith: HadithEntry
    @State private var expanded: [String: Bool] = [:]

    var body: some View {
        NoIndicatorsScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !hadith.narrator.isEmpty {
                    Text(hadith.narrator)
                        .customStyle(.adhkar(size: 15))
                        .italic()
                        .customForeground(.hadithSecondary)
                        .lineSpacing(5)
                        .padding(.horizontal, .big)
                        .padding(.top, .xSm)
                        .padding(.bottom, .big)
                }
                arabicTextCard
                    .padding(.horizontal, .big)
                    .padding(.bottom, .xBig)
                scholarlyDetails
                    .padding(.horizontal, .big)
                    .padding(.bottom, 90)
            }
            .padding(.top, .xxSm)
        }
    }

    // MARK: Arabic Text Card

    private var arabicTextCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: .cornerCard)
                .fill(Color.hadithCard)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Text(AppLocalizedKeys.originalText.value)
                        .customStyle(.caption2)
                        .tracking(1.2)
                        .customForeground(.hadithMuted)
                        .padding(.horizontal, .xSm + 2)
                        .padding(.vertical, .xxSm - 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: .cornerXxSm)
                                .strokeBorder(Color.hadithSeparator, lineWidth: 1)
                        )
                }
                .padding(.top, .md)
                .padding(.trailing, .md)

                Text(hadith.arabicText)
                    .customStyle(.quranPageFixed(size: 22), .hadithArabicText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, .big)
                    .padding(.top, .md)
                    .padding(.bottom, .xxBig - 2)
            }
        }
    }

    // MARK: Scholarly Details

    @ViewBuilder
    private var scholarlyDetails: some View {
        let rows = buildScholarlyRows().filter { $0.hasData }
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: .sm) {
                Text(AppLocalizedKeys.scholarlyDetails.value)
                    .customStyle(.caption2)
                    .tracking(1.5)
                    .customForeground(.hadithMuted)

                VStack(spacing: 0) {
                    ForEach(rows.indices, id: \.self) { i in
                        let row = rows[i]
                        HadithScholarlyRow(
                            item: row,
                            isExpanded: Binding(
                                get: { expanded[row.labelEn] ?? false },
                                set: { expanded[row.labelEn] = $0 }
                            )
                        )
                        if i < rows.count - 1 {
                            Color.hadithSeparator
                                .frame(height: 1)
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(Color.hadithCard)
                .cornerRadius(.cornerLg)
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerLg)
                        .strokeBorder(Color.hadithSeparator, lineWidth: 1)
                )
            }
        }
    }

    private func buildScholarlyRows() -> [HadithScholarlyItem] {[
        HadithScholarlyItem(icon: "person.fill",           labelEn: "NARRATOR",       labelAr: "رواة",         content: hadith.narrator,      isRTL: true),
        HadithScholarlyItem(icon: "seal.fill",             labelEn: "GRADE ARABIC",   labelAr: "حكم",          content: hadith.grade,         isRTL: true),
        HadithScholarlyItem(icon: "globe",                 labelEn: "GRADE ENGLISH",  labelAr: "Authenticity", content: hadith.gradeEn,       isRTL: false),
        HadithScholarlyItem(icon: "text.book.closed.fill", labelEn: "COMMENTARY",     labelAr: "شرح",          content: hadith.commentary,    isRTL: true),
        HadithScholarlyItem(icon: "person.3.fill",         labelEn: "NARRATOR CHAIN", labelAr: "سلسلة الرواة", content: hadith.narratorChain, isRTL: true),
        HadithScholarlyItem(icon: "books.vertical.fill",   labelEn: "TAKHRIJ",        labelAr: "تخريج",        content: hadith.takhrij,       isRTL: true),
    ]}
}

// MARK: - Scholarly Row

struct HadithScholarlyRow: View {

    let item: HadithScholarlyItem
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: .sm) {
                    HadithIconBadge(icon: item.icon)
                    VStack(alignment: .leading, spacing: .xxSm - 2) {
                        Text(item.labelEn)
                            .customStyle(.caption2, .hadithMuted)
                            .tracking(0.8)
                        Text(item.labelAr)
                            .customStyle(.subheadline, .hadithPrimary)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .customForeground(.hadithMuted)
                        .frame(width: 18)
                }
                .padding(.horizontal, .md)
                .padding(.vertical, .md)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Color.hadithSeparator.frame(height: 1).padding(.leading, 56)
                scholarlyContentView
            }
        }
    }

    @ViewBuilder
    private var scholarlyContentView: some View {
        if item.isRTL {
            Text(item.content)
                .customStyle(.adhkar(size: 15))
                .foregroundColor(gradeAwareColor)
                .lineSpacing(7)
                .multilineTextAlignment(.trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.md)
        } else {
            Text(item.content)
                .customStyle(.bodySmall)
                .foregroundColor(gradeAwareColor)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.md)
        }
    }

    private var gradeAwareColor: Color {
        guard item.labelEn == "GRADE ARABIC" || item.labelEn == "GRADE ENGLISH" else {
            return Color.hadithSecondary
        }
        let t = item.content
        if t.contains("صحيح") || t.lowercased().contains("sahih") || t.lowercased().contains("authentic") {
            return Color.hadithGreen
        }
        if t.contains("حسن") || t.lowercased().contains("hasan") || t.lowercased().contains("good") {
            return Color.hadithOrange
        }
        if t.contains("ضعيف") || t.lowercased().contains("da") {
            return Color.hadithRed
        }
        return Color.hadithSecondary
    }
}

// MARK: - Table of Contents Sheet

struct HadithTOCSheet: View {

    let chapters: [HadithChapter]
    let currentChapterId: Int?
    let onSelect: (HadithChapter) -> Void

    var body: some View {
        NavigationStack {
            List(chapters) { chapter in
                Button { onSelect(chapter) } label: {
                    HStack(spacing: .md) {
                        Text("\(chapter.number)")
                            .customStyle(.caption1)
                            .foregroundColor(Color.primaryColor)
                            .frame(width: 32, height: 32)
                            .background(Color.primaryColor.opacity(0.10))
                            .cornerRadius(.cornerXSm)

                        Text(chapter.title)
                            .customStyle(
                                chapter.id == currentChapterId ? .subheadline : .bodySmall
                            )
                            .foregroundColor(
                                chapter.id == currentChapterId ? Color.primaryColor : Color.onSurface
                            )
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if chapter.id == currentChapterId {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color.primaryColor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .navigationTitle(AppLocalizedKeys.tableOfContents.value)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
