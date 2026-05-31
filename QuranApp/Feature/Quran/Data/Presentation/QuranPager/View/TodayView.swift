//
//  TodayView.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - TodayView

struct TodayView: View {
    @Environment(\.dismiss) private var dismiss

    private let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
    private let now = Date()

    private var hijriDay: Int    { hijriCalendar.component(.day,   from: now) }
    private var hijriMonth: Int  { hijriCalendar.component(.month, from: now) }
    private var gregDay: Int     { Calendar.current.component(.day,   from: now) }
    private var gregMonth: Int   { Calendar.current.component(.month, from: now) }

    private var hijriMonthName: String {
        let names = ["محرم","صفر","ربيع الأول","ربيع الآخر",
                     "جمادى الأولى","جمادى الآخرة","رجب","شعبان",
                     "رمضان","شوال","ذو القعدة","ذو الحجة"]
        guard (1...12).contains(hijriMonth) else { return "" }
        return names[hijriMonth - 1]
    }

    private var gregMonthName: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ar")
        fmt.dateFormat = "MMMM"
        return fmt.string(from: now)
    }

    // Computed once per body evaluation — same verse for the whole day.
    private var verseOfDay: DailyVerse { DailyVerseService.verseForToday() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(width: 30, height: 30)
                                .background(Color.outlineVariant.opacity(0.5), in: Circle())
                        }
                        Spacer()
                        Text("اليوم")
                            .customStyle(.kitab(size: 17, bold: true), .onSurface)
                        Spacer()
                        Color.clear.frame(width: 30)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    HStack(spacing: 12) {
                        dateCard(label: hijriMonthName, day: hijriDay)
                        dateCard(label: gregMonthName,  day: gregDay)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 12) {
                        Text("آية اليوم")
                            .customStyle(.kitab(size: 17, bold: true), .onSurface)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 20)

                        NavigationLink {
                            TafsirView(
                                surahNumber: verseOfDay.surah,
                                verseNumber: verseOfDay.verse,
                                ref: verseOfDay.ref,
                                onDismissSheet: { dismiss() }
                            )
                        } label: {
                            VStack(spacing: 0) {
                                verseCard(verseOfDay)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 16)
                                    .padding(.bottom, 12)

                                Divider().padding(.horizontal, 16)

                                HStack {
                                    Image(systemName: "chevron.backward")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("التفسير")
                                        .customStyle(.kitab(size: 15))
                                        .foregroundColor(Color.playerControls)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .background(Color.mushafPage)
                            .customCornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color.surfaceContainerLow.ignoresSafeArea())
            .environment(\.layoutDirection, .rightToLeft)
            .navigationBarHidden(true)
        }
    }

    // MARK: - Verse Card

    private func verseCard(_ verse: DailyVerse) -> some View {
        let text  = QuranTextService.shared.text(surah: verse.surah, verse: verse.verse) ?? ""
        let glyph = QuranTextService.verseEndGlyph(for: verse.verse).map { " \($0)" } ?? ""
        return VStack(alignment: .trailing, spacing: 10) {
            Text(text + glyph)
                .font(.custom("KFGQPCHafsSmart-Regular", size: 22))
                .lineSpacing(10)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .customForeground(.onSurface)

            Text(verse.ref)
                .customStyle(.kitab(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Date Card

    private func dateCard(label: String, day: Int) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .customStyle(.kitab(size: 13))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color.playerControls)

            ZStack {
                Image(systemName: "calendar")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundColor(Color.playerControls.opacity(0.07))
                Text(day.arabicNumerals)
                    .customStyle(.kitab(size: 36, bold: true), .onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
