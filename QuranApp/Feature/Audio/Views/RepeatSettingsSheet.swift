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

    @State private var showFromPicker = false
    @State private var showToPicker = false

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
                .padding(.bottom, 40)
            }
        }
        .background(Color.background)
        .sheet(isPresented: $showFromPicker) {
            VersePickerSheet(surah: $fromSurah, verse: $fromVerse)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showToPicker) {
            VersePickerSheet(surah: $toSurah, verse: $toVerse)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
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
            Button(AppLocalizedKeys.done.value) {
                commit()
                audio.play(surahNumber: fromSurah, verseNumber: fromVerse)
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(ColorStyle.primary.color)

            Spacer()

            Text(AppLocalizedKeys.repeatSettings.value)
                .font(.system(size: 17, weight: .semibold))
                .customForeground(.onSurface)

            Spacer()

            Color.clear.frame(width: 50)
        }
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
                    showFromPicker = true
                }
                Divider().padding(.trailing, 16)
                versePickerRow(label: AppLocalizedKeys.toLabel.value,
                               surahNumber: toSurah, verseNumber: toVerse) {
                    showToPicker = true
                }
            }
            .background(Color.surfaceContainerLow)
            .cornerRadius(12)
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
                    .font(.system(size: 16))
                    .customForeground(.onSurface)

                Spacer()

                // Surah:verse + chevron on trailing side (left in RTL)
                HStack(spacing: 4) {
                    Text("\(surahName(surahNumber)): \(arabicIndic(verseNumber))")
                        .font(.custom("Kitab-Regular", size: 15))
                        .foregroundColor(ColorStyle.primary.color)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ColorStyle.primary.color)
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
                rangeRepeatCard
                verseRepeatCard
            }
        }
    }

    private var rangeRepeatCard: some View {
        VStack(spacing: 0) {
            HStack {
                // Label on leading side (right in RTL)
                Text(AppLocalizedKeys.rangeRepeat.value)
                    .font(.system(size: 16))
                    .customForeground(.onSurface)
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
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: rangeEnabled)
    }

    private var verseRepeatCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(AppLocalizedKeys.verseRepeat.value)
                    .font(.system(size: 16))
                    .customForeground(.onSurface)
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
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: verseEnabled)
    }

    // MARK: - Count Row (+/- stepper with ∞)
    // Reversed array order for RTL: label and count on RIGHT, ± pill on LEFT

    private func countRow(count: Binding<Int>) -> some View {
        HStack(spacing: 12) {
            // Label — first = rightmost in RTL
            Text(AppLocalizedKeys.repetitions.value)
                .font(.system(size: 16))
                .customForeground(.onSurface)

            // Count value — second
            Text(count.wrappedValue == 0 ? "∞" : arabicIndic(count.wrappedValue))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(ColorStyle.primary.color)
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
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 52, height: 40)
                }

                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 24)

                Button {
                    count.wrappedValue = count.wrappedValue >= 10 ? 0 : count.wrappedValue + 1
                } label: {
                    Text("+")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 52, height: 40)
                }
            }
            .background(Color.background)
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .bold))
            .customForeground(.onSurface)
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
    }
}
