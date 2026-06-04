//
//  VersePickerSheet.swift
//  QuranApp
//

import SwiftUI
import Core

struct VersePickerSheet: View {
    @Binding var surah: Int
    @Binding var verse: Int
    @Environment(\.dismiss) private var dismiss

    var parentTitle: String = AppLocalizedKeys.repeatSettings.value

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            verseList
        }
        .background(Color.background)
        .appDirection()
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(AppLocalizedKeys.chooseVerse.value)
                .customStyle(.kitab(size: 17, bold: true))                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)

            // In RTL body env: Spacer first=right, Button last=LEFT ✓
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    HStack(spacing: 2) {
                        Text(parentTitle)
                        Image(systemName: "chevron.forward")
                            .customStyle(.kitab(size: 12, bold: true))                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ColorStyle.primary.color)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.background)
    }

    // MARK: - Verse List

    private var verseList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .trailing, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    ForEach(1...114, id: \.self) { surahNum in
                        Section {
                            VStack(spacing: 8) {
                                ForEach(1...verseCount(surahNum), id: \.self) { verseNum in
                                    verseCard(surahNum: surahNum, verseNum: verseNum)
                                        .id("\(surahNum)_\(verseNum)")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                        } header: {
                            sectionHeader(surahName(surahNum))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.none) {
                        proxy.scrollTo("\(surah)_\(verse)", anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ name: String) -> some View {
        Text(name)
            .customStyle(.kitab(size: 12))            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.background)
    }

    // MARK: - Verse Card

    @ViewBuilder
    private func verseCard(surahNum: Int, verseNum: Int) -> some View {
        let isSelected = surahNum == surah && verseNum == verse
        let verseText  = QuranTextProvider.shared.text(surah: surahNum, verse: verseNum)

        Button {
            surah = surahNum
            verse = verseNum
            dismiss()
        } label: {
            HStack(alignment: .center, spacing: 12) {

                // ── Checkmark (left side in RTL) ──────────────────────────
                Group {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ColorStyle.primary.color)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: 20, height: 20)

                Spacer(minLength: 0)

                // ── Reference + text (right side in RTL) ─────────────────
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(surahName(surahNum)): \(arabicIndic(verseNum))")
                        .customStyle(.kitab(size: 15, bold: true))                        .foregroundColor(isSelected ? ColorStyle.primary.color : .primary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    if let text = verseText {
                        Text(text)
                            .customStyle(.kitab(size: 14))
                            .foregroundColor(Color(.systemGray))
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.surfaceContainerLow)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isSelected ? ColorStyle.primary.color.opacity(0.35) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func surahName(_ n: Int) -> String {
        ReciterLibrary.surahArabicNames[n] ?? "سورة \(n)"
    }

    private func verseCount(_ n: Int) -> Int {
        max(1, ReciterLibrary.verseCounts[n] ?? 1)
    }

    private func arabicIndic(_ n: Int) -> String {
        let digits = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c in
            guard let d = c.wholeNumberValue else { return String(c) }
            return digits[d]
        }.joined()
    }
}
