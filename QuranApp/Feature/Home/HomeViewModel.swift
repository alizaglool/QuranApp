//
//  HomeViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation
import Core
import SwiftUI

struct PrayerTimeItem: Identifiable {
    let id = UUID()
    let name: String
    let time: String
    let isActive: Bool
}

struct QuickAccessItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let type: QuickAccessType
}

enum QuickAccessType {
    case quran, adhkar, hadith, lessons
}

struct FeaturedLesson: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

final class HomeViewModel: MainViewModel {

    @Published var prayerTimes: [PrayerTimeItem] = []
    @Published var prayerTimesLoaded: Bool = false
    @Published var hadithArabic: String = ""
    @Published var hadithTranslation: String = ""
    @Published var hadithReference: String = ""
    @Published var hijriDate: String = ""
    @Published var gregorianDate: String = ""
    @Published var userName: String = "'Zaghloul'"
    @Published var loadingState: LoadingState = .loading

    // Last read — nil means the user hasn't started reading yet
    @Published var lastReadPage: Int? = nil
    @Published var lastReadSurahName: String = ""
    @Published var lastReadProgress: Double = 0.0

    private let service = QuranService.shared
    private var coordinator: HomeCoordinating

    let quickAccessItems: [QuickAccessItem] = [
        QuickAccessItem(title: AppLocalizedKeys.quran.value, icon: "book.fill", type: .quran),
        QuickAccessItem(title: AppLocalizedKeys.adhkar.value, icon: "sparkles", type: .adhkar),
        QuickAccessItem(title: AppLocalizedKeys.hadith.value, icon: "text.book.closed.fill", type: .hadith),
        QuickAccessItem(title: AppLocalizedKeys.lessons.value, icon: "play.rectangle.fill", type: .lessons)
    ]

    let featuredLessons: [FeaturedLesson] = [
        FeaturedLesson(name: "Sheikh Omar\nSuleiman", imageName: "sheikh_omar"),
        FeaturedLesson(name: "Dr. Yasir Qadhi", imageName: "sheikh_yasir"),
        FeaturedLesson(name: "Mufti Menk", imageName: "mufti_menk")
    ]

    init(coordinator: HomeCoordinating) {
        self.coordinator = coordinator
    }
}

// MARK: - Lifecycle

extension HomeViewModel {

    func onAppear() {
        loadPrayerTimes()
        loadHadithOfTheDay()
        loadLastRead()
    }

    func onRefresh() {
        loadPrayerTimes()
    }
}

// MARK: - Prayer Times

extension HomeViewModel {

    private func loadPrayerTimes() {
        Task { @MainActor in
            do {
                let data = try await service.fetchPrayerTimes(city: "Riyadh", country: "SA")

                let timings = data.timings
                let now = Date()
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"

                let times = [
                    (AppLocalizedKeys.fajr.value, timings.Fajr),
                    (AppLocalizedKeys.dhuhr.value, timings.Dhuhr),
                    (AppLocalizedKeys.asr.value, timings.Asr),
                    (AppLocalizedKeys.maghrib.value, timings.Maghrib),
                    (AppLocalizedKeys.isha.value, timings.Isha)
                ]

                let activePrayer = findNextPrayer(times: times, formatter: formatter, now: now)

                prayerTimes = times.enumerated().map { index, item in
                    let cleanTime = String(item.1.prefix(5))
                    return PrayerTimeItem(
                        name: item.0,
                        time: cleanTime,
                        isActive: index == activePrayer
                    )
                }

                let hijri = data.date.hijri
                hijriDate = "\(hijri.day) \(hijri.month.en) \(hijri.year)"

                let greg = data.date.gregorian
                gregorianDate = "\(greg.day) \(greg.month.en) \(greg.year)"

                prayerTimesLoaded = true
                loadingState = .loaded

            } catch {
                print("❌ Prayer times error: \(error)")
                prayerTimesLoaded = true
                loadingState = .loaded
            }
        }
    }

    // Returns the index of the next upcoming prayer.
    // If all prayers for today have passed, wraps back to Fajr (0).
    private func findNextPrayer(times: [(String, String)], formatter: DateFormatter, now: Date) -> Int {
        let calendar = Calendar.current

        for (index, item) in times.enumerated() {
            let cleanTime = String(item.1.prefix(5))
            if let prayerDate = formatter.date(from: cleanTime) {
                let prayerToday = calendar.date(
                    bySettingHour: calendar.component(.hour, from: prayerDate),
                    minute: calendar.component(.minute, from: prayerDate),
                    second: 0,
                    of: now
                )!
                if now < prayerToday {
                    return index
                }
            }
        }
        // All prayers passed today — Fajr is next (tomorrow)
        return 0
    }
}

// MARK: - Last Read

extension HomeViewModel {

    private func loadLastRead() {
        guard let progress = StorageManager.shared.getReadingProgress(),
              progress.lastReadDate != nil else {
            lastReadPage = nil
            return
        }

        let page = progress.lastPage
        lastReadPage = page
        lastReadProgress = Double(page) / 604.0

        let surahs = QuranDatabase.shared.getSurahsForPage(page)
        if let surah = surahs.first {
            let isArabic = LocalizationManager.shared.currentLanguage == .Arabic
            lastReadSurahName = isArabic ? surah.arabicTitle : surah.englishTitle
        }
    }
}

// MARK: - Hadith of the Day

extension HomeViewModel {

    private func loadHadithOfTheDay() {
        let hadith = DailyHadithService.hadithForToday()
        hadithArabic = hadith.arabicText
        hadithTranslation = hadith.translation
        hadithReference = hadith.reference
    }
}

// MARK: - Navigation

extension HomeViewModel {

    func onQuickAccessTapped(_ item: QuickAccessItem) {
        switch item.type {
        case .quran:
            coordinator.coordinateToQuran(startPage: nil)
        case .adhkar:
            coordinator.coordinateToAdhkar()
        case .hadith:
            coordinator.coordinateToHadith()
        case .lessons:
            break
        }
    }

    func onResumeTapped() {
        coordinator.coordinateToQuran(startPage: lastReadPage)
    }
}
