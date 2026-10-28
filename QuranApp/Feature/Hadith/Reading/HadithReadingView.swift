//
//  HadithReadingView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import SwiftUI
import Core

// MARK: - HadithReadingView

struct HadithReadingView: View {

    @StateObject private var viewModel: HadithReadingViewModel
    @State private var isShareSheetPresenting = false

    init(coordinator: HadithCoordinating, hadiths: [HadithEntry], startIndex: Int,
         book: HadithBook, chapter: HadithChapter, chapters: [HadithChapter],
         highlight: HadithSearchQuery? = nil) {
        _viewModel = StateObject(wrappedValue: HadithReadingViewModel(
            coordinator: coordinator, hadiths: hadiths, startIndex: startIndex,
            book: book, chapter: chapter, chapters: chapters, highlight: highlight))
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
        .customSheet(isPresented: narratorBinding, fraction: 0.85, detents: [.medium, .large]) {
            if let narrator = viewModel.narrator {
                HadithNarratorSheet(presentation: narrator) { viewModel.closeNarrator() }
            }
        }
        .customSheet(isPresented: glossBinding, fraction: 0.4, detents: [.medium]) {
            if let gloss = viewModel.gloss {
                HadithGlossSheet(presentation: gloss) { viewModel.closeGloss() }
            }
        }
    }

    // MARK: Sheet bindings

    private var narratorBinding: Binding<Bool> {
        Binding(get: { viewModel.narrator != nil },
                set: { if !$0 { viewModel.closeNarrator() } })
    }

    private var glossBinding: Binding<Bool> {
        Binding(get: { viewModel.gloss != nil },
                set: { if !$0 { viewModel.closeGloss() } })
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
            set: { viewModel.show(index: $0) }
        )) {
            ForEach(viewModel.hadiths.indices, id: \.self) { idx in
                page(viewModel.hadiths[idx])
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func page(_ hadith: HadithEntry) -> some View {
        HadithPageContent(
            hadith: hadith,
            highlight: viewModel.highlight,
            presentation: viewModel.presentation(for: hadith),
            selectedTab: viewModel.selectedTab(for: hadith),
            onSelectTab: { viewModel.select($0, for: hadith) },
            onLink: { viewModel.handle($0, in: hadith) }
        )
    }

    // MARK: Reading Control Bar

    private var readingControlBar: some View {
        HStack(spacing: 0) {
            navigationArrow(icon: "arrow.backward", enabled: viewModel.canGoPrevious) { viewModel.previous() }
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
            navigationArrow(icon: "arrow.forward", enabled: viewModel.canGoNext) { viewModel.next() }
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
    let highlight: HadithSearchQuery?
    let presentation: HadithDetailPresentation
    let selectedTab: HadithDetailTab?
    let onSelectTab: (HadithDetailTab) -> Void
    let onLink: (HadithBodyLink) -> Void

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
                    .padding(.bottom, .big)
                details
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

                markupBody
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, .big)
                    .padding(.top, .md)
                    .padding(.bottom, .xxBig - 2)
            }
        }
    }

    private var markupBody: some View {
        Text(HadithBodyText.make(hadith.markup,
                                 fallback: hadith.arabicText,
                                 highlight: highlight))
            .customStyle(.quranPageFixed(size: 22), .hadithArabicText)
            .multilineTextAlignment(.center)
            .lineSpacing(14)
            .tint(Color.hadithGold)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.openURL, OpenURLAction { url in
                guard let link = HadithBodyLink(url) else { return .systemAction }
                onLink(link)
                return .handled
            })
    }

    // MARK: Details

    @ViewBuilder
    private var details: some View {
        if let tab = selectedTab, !presentation.isEmpty {
            VStack(alignment: .leading, spacing: .sm) {
                HadithDetailTabStrip(tabs: presentation.tabs,
                                     selection: tab,
                                     onSelect: onSelectTab)

                HadithDetailPanel(presentation: presentation,
                                  tab: tab,
                                  onLink: onLink)
                    .padding(.horizontal, .big)
            }
        }
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
