//
//  RepeatSettingsSheet.swift
//  QuranApp
//

import SwiftUI
import Core

struct RepeatSettingsSheet: View {
    @ObservedObject private var audio = AudioEngine.shared
    @Environment(\.dismiss) private var dismiss

    @State private var fromSurah: Int
    @State private var fromVerse: Int
    @State private var toSurah: Int
    @State private var toVerse: Int
    @State private var rangeEnabled: Bool
    @State private var verseEnabled: Bool
    @State private var rangeCount: Int
    @State private var verseCount: Int

    @State private var surahMode: Bool
    @State private var isFromPickerPresenting = false
    @State private var isToPickerPresenting = false

    init() {
        let a = AudioEngine.shared
        _fromSurah    = State(initialValue: a.repeatFromSurah)
        _fromVerse    = State(initialValue: a.repeatFromVerse)
        _toSurah      = State(initialValue: a.repeatToSurah)
        _toVerse      = State(initialValue: a.repeatToVerse)
        _rangeEnabled = State(initialValue: a.repeatRangeEnabled)
        _verseEnabled = State(initialValue: a.repeatVerseEnabled)
        _rangeCount   = State(initialValue: a.rangeRepeatCount)
        _verseCount   = State(initialValue: a.verseRepeatCount)
        _surahMode    = State(initialValue: a.playSurahMode)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
    
            ScrollView {
                VStack(spacing: 28) {
                    rangeSection
                    repeatSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
            }
        }
        .background(Color.background)
        .appDirection()
        .onChange(of: fromSurah) { _, _ in clampToAfterFrom() }
        .onChange(of: fromVerse) { _, _ in clampToAfterFrom() }
        .onChange(of: surahMode) { _, on in
            if on { rangeEnabled = false; verseEnabled = false }
        }
        .onChange(of: rangeEnabled) { _, on in if on { surahMode = false } }
        .onChange(of: verseEnabled) { _, on in if on { surahMode = false } }
        .onDisappear { commit() }
        .customSheet(isPresented: $isFromPickerPresenting, fraction: 1.0, detents: [.large]) {
            VersePickerSheet(surah: $fromSurah, verse: $fromVerse)
                .presentationDragIndicator(.visible)
        }
        .customSheet(isPresented: $isToPickerPresenting, fraction: 1.0, detents: [.large]) {
            VersePickerSheet(surah: $toSurah, verse: $toVerse)
                .presentationDragIndicator(.visible)
        }
    }

    private func clampToAfterFrom() {
        if toSurah < fromSurah || (toSurah == fromSurah && toVerse < fromVerse) {
            toSurah = fromSurah
            toVerse = fromVerse
        }
    }
    
    // MARK: - Header

    private var header: some View {
        HStack {
            Button(AppLocalizedKeys.done.value) {
                commit()
                if surahMode {
                    audio.playWholeSurah(surahNumber: audio.currentSurahNumber)
                } else {
                    audio.play(surahNumber: fromSurah, verseNumber: fromVerse)
                }
                dismiss()
            }
            .customStyle(.kitab(size: 16), .primary)

            Spacer()

            Text(AppLocalizedKeys.repeatSettings.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

            Spacer()

            Color.clear.frame(width: 50)
        }
        .frame(height: 70)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.background)
    }

    // MARK: - Range Section

    private var rangeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppLocalizedKeys.rangeSection.value)

            VStack(spacing: 0) {
                versePickerRow(label: AppLocalizedKeys.fromLabel.value,
                               surahNumber: fromSurah, verseNumber: fromVerse) {
                    isFromPickerPresenting = true
                }
                Divider().padding(.trailing, 16)
                versePickerRow(label: AppLocalizedKeys.toLabel.value,
                               surahNumber: toSurah, verseNumber: toVerse) {
                    isToPickerPresenting = true
                }
            }
            .background(Color.surfaceContainerLow)
            .customCornerRadius(12)
            .opacity(surahMode ? 0.4 : 1)
            .disabled(surahMode)
        }
    }

    private func versePickerRow(
        label: String,
        surahNumber: Int,
        verseNumber: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                // Label on leading side (right in RTL)
                Text(label)
                    .customStyle(.kitab(size: 16), .onSurface)

                Spacer()

                // Surah:verse + chevron on trailing side (left in RTL)
                HStack(spacing: 4) {
                    Text("\(surahName(surahNumber)): \(arabicIndic(verseNumber))")
                        .customStyle(.kitab(size: 15), .primary)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 12, weight: .medium))
                        .customForeground(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Repeat Section

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(AppLocalizedKeys.repeatSection.value)

            VStack(spacing: 12) {
                surahModeCard
                rangeRepeatCard
                verseRepeatCard
            }
        }
    }

    private var surahModeCard: some View {
        HStack {
            Text("تشغيل السورة كاملة")
                .customStyle(.kitab(size: 16), .onSurface)
            Spacer()
            Toggle("", isOn: $surahMode)
                .labelsHidden()
                .tint(ColorStyle.primary.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.surfaceContainerLow)
        .customCornerRadius(12)
    }

    private var rangeRepeatCard: some View {
        VStack(spacing: 0) {
            HStack {
                // Label on leading side (right in RTL)
                Text(AppLocalizedKeys.rangeRepeat.value)
                    .customStyle(.kitab(size: 16), .onSurface)
                Spacer()
                Toggle("", isOn: $rangeEnabled)
                    .labelsHidden()
                    .tint(ColorStyle.primary.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if rangeEnabled {
                Divider().padding(.trailing, 16)
                countRow(count: $rangeCount)
            }
        }
        .background(Color.surfaceContainerLow)
        .customCornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: rangeEnabled)
    }

    private var verseRepeatCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(AppLocalizedKeys.verseRepeat.value)
                    .customStyle(.kitab(size: 16), .onSurface)
                Spacer()
                Toggle("", isOn: $verseEnabled)
                    .labelsHidden()
                    .tint(ColorStyle.primary.color)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if verseEnabled {
                Divider().padding(.trailing, 16)
                countRow(count: $verseCount)
            }
        }
        .background(Color.surfaceContainerLow)
        .customCornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: verseEnabled)
    }

    // MARK: - Count Row (+/- stepper with ∞)
    // Reversed array order for RTL: label and count on RIGHT, ± pill on LEFT

    private func countRow(count: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            // Label — first = rightmost in RTL
            Text(AppLocalizedKeys.repetitions.value)
                .customStyle(.kitab(size: 16), .onSurface)

            // Count value — second
            Text(count.wrappedValue == 0 ? "∞" : arabicIndic(count.wrappedValue))
                .customStyle(.kitab(size: 17, bold: true), .primary)
                .frame(minWidth: 36)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.background)
                )

            Spacer()

            // ± pill — last = leftmost in RTL
            // In RTL inner HStack: − is first=right, + is last=left → pill shows [+|−] ✓
            HStack(spacing: 0) {
                Button {
                    count.wrappedValue = count.wrappedValue <= 0 ? 10 : count.wrappedValue - 1
                } label: {
                    Text("−")
                        .customStyle(.kitab(size: 20))                        .foregroundColor(.primary)
                        .frame(width: 52, height: 40)
                }

                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 24)

                Button {
                    count.wrappedValue = count.wrappedValue >= 10 ? 0 : count.wrappedValue + 1
                } label: {
                    Text("+")
                        .customStyle(.kitab(size: 20))                        .foregroundColor(.primary)
                        .frame(width: 52, height: 40)
                }
            }
            .background(Color.background)
            .customCornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .customStyle(.kitab(size: 17, bold: true), .onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func arabicIndic(_ n: Int) -> String {
        let digits = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(n).map { c in
            guard let d = c.wholeNumberValue else { return String(c) }
            return digits[d]
        }.joined()
    }

    private func surahName(_ n: Int) -> String {
        ReciterLibrary.surahArabicNames[n] ?? "سورة \(n)"
    }

    private func commit() {
        audio.repeatFromSurah  = fromSurah
        audio.repeatFromVerse  = fromVerse
        audio.repeatToSurah    = toSurah
        audio.repeatToVerse    = toVerse
        audio.rangeRepeatCount = rangeCount
        audio.verseRepeatCount = verseCount
        audio.setRepeatRange(enabled: rangeEnabled)
        audio.setRepeatVerse(enabled: verseEnabled)
        if !rangeEnabled && !verseEnabled {
            audio.playSurahMode = surahMode
        }
    }
}
