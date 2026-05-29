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
    @Environment(\.dismiss) private var dismiss

    init(verses: [DailyVerse], startIndex: Int, onDismissSheet: @escaping () -> Void) {
        self.verses = verses
        self._currentIndex = State(initialValue: startIndex)
        self.onDismissSheet = onDismissSheet
    }

    private var current: DailyVerse { verses[currentIndex] }

    private var tafsirText: String {
        TafsirDatabase.shared.getTafsir(surahNumber: current.surah, verseNumber: current.verse)
            ?? "التفسير غير متاح حالياً"
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                VStack(alignment: .trailing, spacing: 24) {
                    verseSection
                    tafsirSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }

            bottomBar
        }
        .background(Color.surfaceContainerLow.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var headerBar: some View {
        VStack(spacing: 0) {
            HStack {
                Button { onDismissSheet() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.outlineVariant.opacity(0.5), in: Circle())
                }
                .accessibilityLabel("إغلاق")

                Spacer()

                Text("التفسير")
                    .font(.system(size: 17, weight: .semibold))
                    .customForeground(.onSurface)

                Spacer()

                Button { dismiss() } label: {
                    HStack(spacing: 3) {
                        Text("اليوم")
                            .font(.system(size: 15))
                            .foregroundColor(Color.playerControls)
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.playerControls)
                    }
                }
                .accessibilityLabel("العودة إلى اليوم")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()
        }
        .background(Color.mushafPage)
    }

    // MARK: - Verse Section

    private var verseSection: some View {
        VerseSnippetView(surahNumber: current.surah, verseNumber: current.verse)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.mushafPage)
            .cornerRadius(14)
    }

    // MARK: - Tafsir Section

    private var tafsirSection: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Text("المختصر")
                .font(.system(size: 15, weight: .bold))
                .customForeground(.onSurface)

            Text(tafsirText)
                .font(.system(size: 15))
                .customForeground(.onSurface)
                .multilineTextAlignment(.trailing)
                .lineSpacing(7)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(16)
                .background(Color.background)
                .cornerRadius(14)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    if currentIndex > 0 { currentIndex -= 1 }
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(currentIndex > 0 ? .primary : Color.secondary.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .disabled(currentIndex <= 0)

            Text(current.ref)
                .font(.system(size: 15, weight: .medium))
                .customForeground(.onSurface)
                .frame(maxWidth: .infinity)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    if currentIndex < verses.count - 1 { currentIndex += 1 }
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(currentIndex < verses.count - 1 ? .primary : Color.secondary.opacity(0.3))
            }
            .frame(maxWidth: .infinity)
            .disabled(currentIndex >= verses.count - 1)

            Button {} label: {
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
}
