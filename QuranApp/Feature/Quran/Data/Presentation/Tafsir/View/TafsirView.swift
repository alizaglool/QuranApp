//
//  TafsirView.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - TafsirView

struct TafsirView: View {

    let verses: [DailyVerse]
    @State private var currentIndex: Int
    let onDismissSheet: () -> Void

    @StateObject private var vm = TafsirViewModel()
    @State private var isBookPickerPresenting = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Init

    /// Multi-verse mode: used from TodayView with navigable verse list.
    init(verses: [DailyVerse], startIndex: Int, onDismissSheet: @escaping () -> Void) {
        self.verses = verses
        self._currentIndex = State(initialValue: startIndex)
        self.onDismissSheet = onDismissSheet
    }

    /// Single-verse mode: used from VerseActionSheet.
    init(surahNumber: Int, verseNumber: Int, ref: String, onDismissSheet: @escaping () -> Void) {
        self.verses = [DailyVerse(surah: surahNumber, verse: verseNumber, ref: ref)]
        self._currentIndex = State(initialValue: 0)
        self.onDismissSheet = onDismissSheet
    }

    private var current: DailyVerse { verses[currentIndex] }
    private var hasNavigation: Bool { verses.count > 1 }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                VStack(alignment: .trailing, spacing: 20) {
                    verseSection
                    bookLabel
                    tafsirContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }

            if hasNavigation { bottomBar }
        }
        .background(Color.surfaceContainerLow.ignoresSafeArea())
        .appDirection()
        .navigationBarHidden(true)
        .customSheet(isPresented: $isBookPickerPresenting, fraction: 0.92, detents: [.large]) {
            TafsirBookPickerView(selectedBook: $vm.selectedBook)
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            vm.load(surah: current.surah, verse: current.verse)
        }
        .onChange(of: currentIndex) { _, _ in
            vm.load(surah: current.surah, verse: current.verse)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack {
                // Close
                Button { onDismissSheet() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.outlineVariant.opacity(0.5), in: Circle())
                }
                .accessibilityLabel("إغلاق")

                Spacer()

                // Title
                Text("التفسير")
                    .customStyle(.kitab(size: 17, bold: true), .onSurface)

                Spacer()

                // Back to parent (only when navigating from TodayView)
                if hasNavigation {
                    Button { dismiss() } label: {
                        HStack(spacing: 3) {
                            Text("اليوم")
                                .customStyle(.kitab(size: 15))
                                .foregroundColor(Color.playerControls)
                            Image(systemName: "chevron.forward")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.playerControls)
                        }
                    }
                    .accessibilityLabel("العودة إلى اليوم")
                } else {
                    Color.clear.frame(width: 30)
                }
            }
            .frame(height: 30)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)

            // Book picker button
            Button { isBookPickerPresenting = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ColorStyle.primary.color)
                    Text(vm.selectedBook.nameArabic)
                        .customStyle(.kitab(size: 14, bold: true), .primary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(ColorStyle.primary.color.opacity(0.1), in: Capsule())
            }
            .padding(.bottom, 12)

            Divider()
        }
        .background(Color.mushafPage)
    }

    // MARK: - Verse Section (JSON text)

    private var verseSection: some View {
        let text  = QuranTextService.shared.text(surah: current.surah, verse: current.verse) ?? ""
        let glyph = QuranTextService.verseEndGlyph(for: current.verse).map { " \($0)" } ?? ""
        return VStack(alignment: .trailing, spacing: 10) {
            Text(text + glyph)
                .font(.custom("KFGQPCHafsSmart-Regular", size: 22))
                .lineSpacing(10)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .customForeground(.onSurface)

            Text(current.ref)
                .customStyle(.kitab(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.mushafPage)
        .customCornerRadius(14)
    }

    // MARK: - Book Label

    private var bookLabel: some View {
        HStack(spacing: 6) {
            if let length = vm.selectedBook.length {
                Text(length.label)
                    .customStyle(.caption1, length == .brief ? .secondary : .primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((length == .brief ? ColorStyle.secondary.color : ColorStyle.primary.color).opacity(0.12))
                    )
            }
            Spacer()
            Text(vm.selectedBook.nameArabic)
                .customStyle(.kitab(size: 15, bold: true), .onSurface)
        }
    }

    // MARK: - Tafsir Content

    @ViewBuilder
    private var tafsirContent: some View {
        Group {
            if vm.isLoading {
                loadingView
            } else if let err = vm.errorMessage {
                errorView(message: err)
            } else {
                tafsirTextCard
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("جارٍ تحميل التفسير…")
                .customStyle(.kitab(size: 14), .subtitle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.background)
        .customCornerRadius(14)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 28))
                .foregroundColor(Color.outlineVariant)
            
            Text(message)
                .customStyle(.kitab(size: 14), .subtitle)
                .multilineTextAlignment(.center)
            
            Button { vm.retry() } label: {
                Text("إعادة المحاولة")
                    .customStyle(.kitab(size: 14, bold: true), .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(ColorStyle.primary.color.opacity(0.1), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .background(Color.background)
        .customCornerRadius(14)
    }

    private var tafsirTextCard: some View {
        let isRTL = vm.selectedBook.language.isRTL
        let alignment: TextAlignment = isRTL ? .leading : .trailing
        let frameAlignment: Alignment = isRTL ? .leading : .trailing

        return Text(vm.text.isEmpty ? "لا يوجد تفسير لهذه الآية" : vm.text)
            .customStyle(isRTL ? .kitab(size: 20) : .bodyMedium, .onSurface)
            .multilineTextAlignment(alignment)
            .lineSpacing(8)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .padding(16)
            .background(Color.background)
            .customCornerRadius(14)
            .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
    }

    // MARK: - Bottom Nav Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            navButton(icon: "chevron.right", enabled: currentIndex > 0) {
                withAnimation(.easeInOut(duration: 0.18)) { currentIndex -= 1 }
            }

            Text(current.ref)
                .customStyle(.kitab(size: 15), .onSurface)
                .frame(maxWidth: .infinity)

            navButton(icon: "chevron.left", enabled: currentIndex < verses.count - 1) {
                withAnimation(.easeInOut(duration: 0.18)) { currentIndex += 1 }
            }

            Button { isBookPickerPresenting = true } label: {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color.playerControls)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color.mushafPage
                .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: -2)
        )
    }

    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(enabled ? .primary : Color.secondary.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .disabled(!enabled)
    }
}
