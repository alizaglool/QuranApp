//
//  TodayView.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - DailyVerse

struct DailyVerse {
    let surah: Int
    let verse: Int
    let ref: String
}

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

    private var verseOfDayIndex: Int { max(0, hijriDay - 1) % Self.verses.count }
    private var verseOfDay: DailyVerse { Self.verses[verseOfDayIndex] }

    static let verses: [DailyVerse] = [
        DailyVerse(surah: 94,  verse: 6,   ref: "الشرح: ٦"),
        DailyVerse(surah: 2,   verse: 153, ref: "البقرة: ١٥٣"),
        DailyVerse(surah: 65,  verse: 3,   ref: "الطلاق: ٣"),
        DailyVerse(surah: 3,   verse: 173, ref: "آل عمران: ١٧٣"),
        DailyVerse(surah: 13,  verse: 28,  ref: "الرعد: ٢٨"),
        DailyVerse(surah: 20,  verse: 114, ref: "طه: ١١٤"),
        DailyVerse(surah: 12,  verse: 87,  ref: "يوسف: ٨٧"),
        DailyVerse(surah: 24,  verse: 35,  ref: "النور: ٣٥"),
        DailyVerse(surah: 2,   verse: 216, ref: "البقرة: ٢١٦"),
        DailyVerse(surah: 2,   verse: 155, ref: "البقرة: ١٥٥"),
        DailyVerse(surah: 9,   verse: 120, ref: "التوبة: ١٢٠"),
        DailyVerse(surah: 11,  verse: 88,  ref: "هود: ٨٨"),
        DailyVerse(surah: 20,  verse: 25,  ref: "طه: ٢٥-٢٦"),
        DailyVerse(surah: 16,  verse: 128, ref: "النحل: ١٢٨"),
        DailyVerse(surah: 94,  verse: 5,   ref: "الشرح: ٥"),
        DailyVerse(surah: 2,   verse: 282, ref: "البقرة: ٢٨٢"),
        DailyVerse(surah: 2,   verse: 201, ref: "البقرة: ٢٠١"),
        DailyVerse(surah: 29,  verse: 45,  ref: "العنكبوت: ٤٥"),
        DailyVerse(surah: 42,  verse: 19,  ref: "الشورى: ١٩"),
        DailyVerse(surah: 4,   verse: 81,  ref: "النساء: ٨١"),
        DailyVerse(surah: 12,  verse: 76,  ref: "يوسف: ٧٦"),
        DailyVerse(surah: 11,  verse: 56,  ref: "هود: ٥٦"),
        DailyVerse(surah: 112, verse: 1,   ref: "الإخلاص: ١"),
        DailyVerse(surah: 67,  verse: 1,   ref: "الملك: ١"),
        DailyVerse(surah: 3,   verse: 8,   ref: "آل عمران: ٨"),
        DailyVerse(surah: 2,   verse: 286, ref: "البقرة: ٢٨٦"),
        DailyVerse(surah: 62,  verse: 1,   ref: "الجمعة: ١"),
        DailyVerse(surah: 4,   verse: 103, ref: "النساء: ١٠٣"),
        DailyVerse(surah: 7,   verse: 205, ref: "الأعراف: ٢٠٥"),
        DailyVerse(surah: 2,   verse: 127, ref: "البقرة: ١٢٧"),
    ]

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
                            .font(.system(size: 17, weight: .semibold))
                            .customForeground(.onSurface)
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
                            .font(.system(size: 17, weight: .bold))
                            .customForeground(.onSurface)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 20)

                        NavigationLink(value: verseOfDayIndex) {
                            VStack(spacing: 0) {
                                VerseSnippetView(surahNumber: verseOfDay.surah, verseNumber: verseOfDay.verse)
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
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color.playerControls)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .background(Color.mushafPage)
                            .cornerRadius(14)
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
            .navigationDestination(for: Int.self) { idx in
                TafsirView(verses: Self.verses, startIndex: idx, onDismissSheet: { dismiss() })
            }
        }
    }

    private func dateCard(label: String, day: Int) -> some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.custom("Kitab-Regular", size: 13))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color.playerControls)

            ZStack {
                Image(systemName: "calendar")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundColor(Color.playerControls.opacity(0.07))
                Text(day.arabicNumerals)
                    .font(.system(size: 36, weight: .bold))
                    .customForeground(.onSurface)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
