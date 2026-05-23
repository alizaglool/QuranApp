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
    @Published var hadithArabic: String = ""
    @Published var hadithTranslation: String = ""
    @Published var hadithReference: String = ""
    @Published var hijriDate: String = ""
    @Published var gregorianDate: String = ""
    @Published var userName: String = "'Zaghloul'"
    @Published var loadingState: LoadingState = .loading
    
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
    }
    
    func onRefresh() {
        loadPrayerTimes()
    }
}

// MARK: - Prayer Times

extension HomeViewModel {
    
    private func loadPrayerTimes() {
        // TODO: Replace with user's actual location later
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
                
                let activePrayer = findActivePrayer(times: times, formatter: formatter, now: now)
                
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
                
                loadingState = .loaded
                
            } catch {
                print("❌ Prayer times error: \(error)")
                loadingState = .loaded
            }
        }
    }
    
    private func findActivePrayer(times: [(String, String)], formatter: DateFormatter, now: Date) -> Int {
        let calendar = Calendar.current
        
        for (index, item) in times.enumerated().reversed() {
            let cleanTime = String(item.1.prefix(5))
            if let prayerDate = formatter.date(from: cleanTime) {
                let prayerToday = calendar.date(
                    bySettingHour: calendar.component(.hour, from: prayerDate),
                    minute: calendar.component(.minute, from: prayerDate),
                    second: 0,
                    of: now
                )!
                if now >= prayerToday {
                    return index
                }
            }
        }
        return 0
    }
}

// MARK: - Hadith of the Day

extension HomeViewModel {
    
    private func loadHadithOfTheDay() {
        // TODO: Replace with real data later
        hadithArabic = "مَنْ سَلَكَ طَرِيقًا يَلْتَمِسُ فِيهِ عِلْمًا سَهَّلَ اللَّهُ لَهُ بِهِ طَرِيقًا إِلَى الْجَنَّةِ"
        hadithTranslation = "\"Whoever takes a path in search of knowledge, Allah will make easy for him a path to Paradise.\""
        hadithReference = "SAHIH MUSLIM 2699"
    }
}

// MARK: - Navigation

extension HomeViewModel {
    
    func onQuickAccessTapped(_ item: QuickAccessItem) {
        switch item.type {
        case .quran:
            coordinator.coordinateToQuran()
        case .adhkar, .hadith, .lessons:
            break // TODO
        }
    }
    
    func onResumeTapped() {
        // TODO: Navigate to last read
    }
}
