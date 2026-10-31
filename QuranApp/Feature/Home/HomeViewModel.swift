//
//  HomeViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import Foundation
import Combine
import Core
import SwiftUI
import os

struct PrayerTimeItem: Identifiable {
    let id: Int
    let name: String
    let time: String
    let isActive: Bool
    let isPrayed: Bool
}

struct QuickAccessItem: Identifiable {
    let id: Int
    let title: String
    let icon: String
    let accent: ColorStyle
    let type: QuickAccessType
}

enum QuickAccessType {
    case quran, recitations, radio, egyptianRadio, adhkar, khatmah, hadith, lessons, worship, content
}

private struct PrayerAnchor {
    let chipTitle: String
    let title: String
    let minutes: Int
    let clock: String
}


final class HomeViewModel: MainViewModel {

    @Published var prayerTimes: [PrayerTimeItem] = []
    @Published var prayerTimesLoaded: Bool = false
    @Published var prayerTimesFailed: Bool = false
    @Published var nextPrayerName: String = ""
    @Published var nextPrayerClock: String = ""
    @Published var leftUntilText: String = ""
    @Published var prayedCount: Int = 0
    @Published var athkarNowTitle: String = ""
    @Published var hasAthkarNow: Bool = false
    @Published var dateLine: String = ""
    @Published var hadithArabic: String = ""
    @Published var hadithReference: String = ""
    @Published var hijriDate: String = ""
    @Published var gregorianDate: String = ""
    @Published var loadingState: LoadingState = .loading
    @Published var featuredSheikhs: [Sheikh] = []
    @Published var featuredReciters: [FeaturedReciter] = []
    @Published var featuredSheikhsLoading: Bool = false
    @Published var featuredSheikhsFailed: Bool = false
    @Published var featuredRecitersLoading: Bool = false
    @Published var featuredRecitersFailed: Bool = false

    @Published var lastReadSurahName: String = ""

    @Published var lastReadPage: Int? = nil
    @Published var lastReadProgress: Double = 0.0

    @Published private(set) var locationLabel: String = ""
    @Published private(set) var liveStations: [RadioStation] = []

    private let prayerStore = PrayerTimesStore.shared
    private let locationStore = SelectedLocationStore.shared
    private let locationLabelFormatter = SelectedLocationLabelFormatter()
    private var didBindSelectedLocation = false
    private var coordinator: HomeCoordinating
    private var cancellables = Set<AnyCancellable>()
    private let completionStore = PrayerCompletionStore.shared
    private var currentDay: DayPrayerTimes?
    private var activePrayerIndex: Int = -1
    private var nextPrayerTargetSeconds: Int = -1
    private var lastTickMinute: Int = -1
    private var didRequestReciterRefresh = false
    private var isLoadingFeaturedSheikhs = false
    private var isLoadingFeaturedReciters = false

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.Quran.wird",
        category: "Home"
    )
    private var didBindPrayerTimes = false

    let quickAccessItems: [QuickAccessItem] = [
        QuickAccessItem(id: 0, title: AppLocalizedKeys.quran.value, icon: "book.fill",
                        accent: .quickAccentQuran, type: .quran),
        QuickAccessItem(id: 1, title: AppLocalizedKeys.recitations.value, icon: "waveform",
                        accent: .quickAccentRecitations, type: .recitations),
        QuickAccessItem(id: 2, title: AppLocalizedKeys.radio.value, icon: "dot.radiowaves.left.and.right",
                        accent: .quickAccentRadio, type: .radio),
        QuickAccessItem(id: 3, title: AppLocalizedKeys.egyptianRadioHomeTile.value, icon: "antenna.radiowaves.left.and.right",
                        accent: .quickAccentRadio, type: .egyptianRadio),
        QuickAccessItem(id: 4, title: AppLocalizedKeys.adhkar.value, icon: "sparkles",
                        accent: .quickAccentAdhkar, type: .adhkar),
        QuickAccessItem(id: 5, title: AppLocalizedKeys.khatmahHomeTile.value, icon: "book.closed.fill",
                        accent: .quickAccentKhatmah, type: .khatmah),
        QuickAccessItem(id: 6, title: AppLocalizedKeys.hadith.value, icon: "text.book.closed.fill",
                        accent: .quickAccentHadith, type: .hadith),
        QuickAccessItem(id: 7, title: AppLocalizedKeys.lessons.value, icon: "play.rectangle.fill",
                        accent: .quickAccentLessons, type: .lessons),
        QuickAccessItem(id: 8, title: AppLocalizedKeys.worshipHomeTile.value, icon: "checkmark.seal.fill",
                        accent: .quickAccentWorship, type: .worship),
        QuickAccessItem(id: 9, title: AppLocalizedKeys.contentHomeTile.value, icon: "signpost.right.fill",
                        accent: .quickAccentContent, type: .content)
    ]

    init(coordinator: HomeCoordinating) {
        self.coordinator = coordinator
        locationLabel = locationLabelFormatter.displayLabel(for: locationStore.selectedLocation)
        applyReadingStartState()
    }
}

// MARK: - Lifecycle

extension HomeViewModel {

    func onAppear() {
        bindPrayerTimes()
        bindSelectedLocation()
        loadDates()
        loadPrayerTimes()
        loadHadithOfTheDay()
        loadLastRead()
        loadFeaturedReciters()
        loadLiveStations()
        resolveDeviceLocationIfNeeded()
        guard featuredSheikhs.isEmpty else { return }
        Task { await loadFeaturedSheikhs() }
    }

    func onRefresh() {
        loadDates()
        loadPrayerTimes()
    }
}

// MARK: - Prayer Times

extension HomeViewModel {

    private func bindPrayerTimes() {
        guard !didBindPrayerTimes else { return }
        didBindPrayerTimes = true

        prayerStore.$today
            .sink { [weak self] day in
                Task { @MainActor in
                    self?.apply(day: day)
                }
            }
            .store(in: &cancellables)
    }

    private func loadPrayerTimes() {
        prayerStore.loadTodayForSelectedLocation()
    }

    private func bindSelectedLocation() {
        guard !didBindSelectedLocation else { return }
        didBindSelectedLocation = true

        locationStore.$selectedLocation
            .sink { [weak self] location in
                guard let self else { return }
                self.locationLabel = self.locationLabelFormatter.displayLabel(for: location)
            }
            .store(in: &cancellables)
    }

    private func apply(day: DayPrayerTimes?) {
        currentDay = day
        activePrayerIndex = -1
        lastTickMinute = -1
        refreshCountdown()
    }

    func onCountdownTick() {
        let minute = Int(Date().timeIntervalSince1970 / 60)
        guard minute != lastTickMinute else { return }
        lastTickMinute = minute
        refreshCountdown()
    }

    func onRetryPrayerTimes() {
        prayerTimesFailed = false
        loadingState = .loading
        loadPrayerTimes()
    }

    func countdownText(at date: Date) -> String {
        guard let day = currentDay, nextPrayerTargetSeconds >= 0 else { return "" }
        var remaining = nextPrayerTargetSeconds - day.seconds(at: date)
        if remaining <= 0 { remaining += HomeViewModel.secondsPerDay }
        return HomeViewModel.countdownString(forSecondsRemaining: remaining)
    }

    func resolveDeviceLocationIfNeeded() {
        let hasNeverChosenLocation = locationStore.isUsingFallbackLocation
        let isFollowingDeviceLocation = locationStore.selectedLocation.isResolvedFromDevice
        guard hasNeverChosenLocation || isFollowingDeviceLocation else { return }

        let locationService = DeviceLocationService.shared
        let canPrompt = hasNeverChosenLocation && !locationService.isAuthorizationDenied
        guard canPrompt || locationService.isAuthorized else { return }

        Task { [weak self] in
            guard let self else { return }
            guard let resolved = try? await locationService.resolveCurrentLocation() else { return }
            let current = self.locationStore.selectedLocation
            let hasMovedCity = resolved.prayerTimesCacheIdentifier != current.prayerTimesCacheIdentifier
            let hasLateCityName = resolved.hasResolvedCityName && !current.hasResolvedCityName
            guard hasMovedCity || hasLateCityName else { return }

            self.locationStore.updateSelectedLocation(resolved)
            guard hasMovedCity else { return }
            self.prayerStore.reloadAfterSelectedLocationChange()
        }
    }

    func heroScene(at date: Date) -> HomeHeroScene {
        HomeHeroScene.current(for: currentDay, at: date)
    }

    func togglePrayed(_ item: PrayerTimeItem) {
        guard let day = currentDay else { return }
        completionStore.toggle(index: item.id, on: day.dayKey)
        rebuildPrayerTimes(anchors: HomeViewModel.anchors(of: day),
                           activeIndex: activePrayerIndex,
                           dayKey: day.dayKey)
    }

    private func refreshCountdown() {
        guard let day = currentDay else {
            if !prayerTimes.isEmpty { prayerTimes = [] }
            assign(&prayerTimesLoaded, false)
            assign(&prayerTimesFailed, true)
            assign(&nextPrayerName, "")
            assign(&nextPrayerClock, "")
            assign(&leftUntilText, "")
            assign(&prayedCount, 0)
            refreshAthkarNow(day: nil)
            nextPrayerTargetSeconds = -1
            return
        }

        let anchors = HomeViewModel.anchors(of: day)
        let nowMinutes = day.minutes(at: Date())
        let index = HomeViewModel.nextPrayerIndex(in: anchors, nowMinutes: nowMinutes)
        let anchor = anchors[index]

        assign(&nextPrayerName, anchor.title)
        assign(&nextPrayerClock, anchor.clock)
        assign(&leftUntilText, String(format: AppLocalizedKeys.leftUntilPrayer.value, anchor.title))
        nextPrayerTargetSeconds = anchor.minutes * 60

        if index != activePrayerIndex || prayerTimes.isEmpty {
            activePrayerIndex = index
            rebuildPrayerTimes(anchors: anchors, activeIndex: index, dayKey: day.dayKey)
        }

        refreshAthkarNow(day: day)
        assign(&prayerTimesLoaded, true)
        assign(&prayerTimesFailed, false)
    }

    private func rebuildPrayerTimes(anchors: [PrayerAnchor], activeIndex: Int, dayKey: String) {
        let prayed = completionStore.prayed(on: dayKey)
        prayerTimes = anchors.enumerated().map { offset, item in
            PrayerTimeItem(id: offset,
                           name: item.chipTitle,
                           time: item.clock,
                           isActive: offset == activeIndex,
                           isPrayed: prayed.contains(offset))
        }
        assign(&prayedCount, prayed.count)
    }

    private func assign<T: Equatable>(_ target: inout T, _ value: T) {
        guard target != value else { return }
        target = value
    }

    private static func anchors(of day: DayPrayerTimes) -> [PrayerAnchor] {
        let entries: [(AppLocalizedKeys, Int)] = [
            (.fajr, day.fajr),
            (.dhuhr, day.dhuhr),
            (.asr, day.asr),
            (.maghrib, day.maghrib),
            (.isha, day.isha)
        ]

        return entries.map { key, minutes in
            let chipTitle = key.value
            return PrayerAnchor(
                chipTitle: chipTitle,
                title: chipTitle.capitalized,
                minutes: minutes,
                clock: PrayerClockFormatter.twelveHourClock(fromMinutesSinceMidnight: minutes)
            )
        }
    }

    private static func nextPrayerIndex(in anchors: [PrayerAnchor], nowMinutes: Int) -> Int {
        anchors.firstIndex { $0.minutes > nowMinutes } ?? 0
    }

    private static func countdownString(forSecondsRemaining remaining: Int) -> String {
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        guard hours > 0 else { return String(format: "%d:%02d", minutes, seconds) }
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    private static let secondsPerDay = 24 * 60 * 60
}

// MARK: - Athkar Now

extension HomeViewModel {

    private func refreshAthkarNow(day: DayPrayerTimes?) {
        let service = DhikrVisibilityService(prayerTimes: day)
        let now = Date()
        let windows: [(DhikrCondition, AppLocalizedKeys)] = [
            (.morning, .athkarMorningTitle),
            (.evening, .athkarEveningTitle),
            (.afterIsha, .athkarAfterIshaTitle),
            (.lastThirdOfNight, .athkarLastThirdTitle)
        ]

        guard let open = windows.first(where: { service.isOpen($0.0, on: now) }) else {
            assign(&hasAthkarNow, false)
            assign(&athkarNowTitle, "")
            return
        }

        assign(&athkarNowTitle, open.1.value)
        assign(&hasAthkarNow, true)
    }

    var athkarNowSubtitle: String {
        AppLocalizedKeys.homeAthkarNowSubtitle.value
    }

    var nowBadgeTitle: String {
        AppLocalizedKeys.homeNowBadge.value
    }

    func onAthkarNowTapped() {
        coordinator.coordinateToAdhkar()
    }
}

// MARK: - Dates

extension HomeViewModel {

    private func loadDates() {
        let isArabic = LocalizationManager.shared.currentLanguage == .Arabic
        let languageCode = isArabic ? "ar" : "en"
        let now = Date()

        let hijri = HomeViewModel.dateString(for: now,
                                             identifier: .islamicUmmAlQura,
                                             languageCode: languageCode,
                                             format: AppLocalizedKeys.homeHijriFormat.value)
        hijriDate = "\(hijri) \(AppLocalizedKeys.hijriEraSuffix.value)"
        gregorianDate = HomeViewModel.dateString(for: now,
                                                 identifier: .gregorian,
                                                 languageCode: languageCode,
                                                 format: AppLocalizedKeys.homeGregorianFormat.value)
        dateLine = "\(gregorianDate) · \(hijriDate)"
    }

    private static func dateString(for date: Date,
                                   identifier: Calendar.Identifier,
                                   languageCode: String,
                                   format: String) -> String {
        let locale = Locale(identifier: languageCode)
        var calendar = Calendar(identifier: identifier)
        calendar.locale = locale

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

// MARK: - Last Read

extension HomeViewModel {

    private func loadLastRead() {
        guard let progress = StorageManager.shared.getReadingProgress(),
              progress.lastReadDate != nil else {
            applyReadingStartState()
            return
        }

        let page = progress.lastPage
        let isArabic = LocalizationManager.shared.currentLanguage == .Arabic

        Task.detached(priority: .userInitiated) { [weak self] in
            let database = QuranDatabase.shared
            let surahs = database.getSurahsForPage(page)
            let name = surahs.first.map { isArabic ? $0.arabicTitle : $0.englishTitle } ?? ""
            let juz = database.getJuz(forPage: page)
            let totalPages = database.totalPages

            guard let self else { return }
            await self.applyReadingProgressState(page: page, surahName: name, juz: juz, totalPages: totalPages)
        }
    }

    private func applyReadingStartState() {
        lastReadPage = nil
        lastReadProgress = 0
        lastReadSurahName = ""
    }

    private func applyReadingProgressState(page: Int, surahName: String, juz: Int, totalPages: Int) {
        let fraction = totalPages > 0 ? Double(page) / Double(totalPages) : 0

        lastReadPage = page
        lastReadProgress = min(max(fraction, 0), 1)
        lastReadSurahName = surahName
    }
}

// MARK: - Hadith of the Day

extension HomeViewModel {

    private func loadHadithOfTheDay() {
        let hadith = DailyHadithService.hadithForToday()
        hadithArabic = hadith.arabicText
        hadithReference = hadith.reference
    }
}

// MARK: - Featured Sheikhs

extension HomeViewModel {

    private func loadFeaturedSheikhs() async {
        guard !isLoadingFeaturedSheikhs else { return }
        isLoadingFeaturedSheikhs = true

        if featuredSheikhs.isEmpty {
            featuredSheikhs = FeaturedSheikhsCache.shared.storedSheikhs()
        }

        featuredSheikhsLoading = featuredSheikhs.isEmpty
        featuredSheikhsFailed = false

        do {
            let channels = try await RemoteConfigService.shared.fetchChannels()
            let all = try await BatchService.shared.fetchSheikhs(from: channels)
            let sorted = all.sorted { $0.subscriberCount > $1.subscriberCount }
            let featured = Array(sorted.prefix(5))

            if !featured.isEmpty {
                featuredSheikhs = featured
                FeaturedSheikhsCache.shared.store(featured)
            }
        } catch {
            HomeViewModel.log.error("Featured sheikhs failed to load: \(error.localizedDescription, privacy: .public)")
        }

        featuredSheikhsLoading = false
        featuredSheikhsFailed = featuredSheikhs.isEmpty
        isLoadingFeaturedSheikhs = false
    }

    func onRetryFeaturedSheikhs() {
        Task { await loadFeaturedSheikhs() }
    }
}

// MARK: - Featured Reciters

extension HomeViewModel {

    private func loadFeaturedReciters() {
        if featuredReciters.isEmpty {
            featuredReciters = ReciterLibrary.featured
        }

        guard !isLoadingFeaturedReciters else { return }
        guard !didRequestReciterRefresh || featuredReciters.isEmpty else { return }
        isLoadingFeaturedReciters = true
        didRequestReciterRefresh = true

        featuredRecitersLoading = featuredReciters.isEmpty
        featuredRecitersFailed = false

        Task { @MainActor in
            await ReciterLibrary.refreshFromRemote()
            let fresh = ReciterLibrary.featured
            if !fresh.isEmpty { featuredReciters = fresh }

            featuredRecitersLoading = false
            if featuredReciters.isEmpty {
                HomeViewModel.log.error("Featured reciters are empty after a remote refresh")
                featuredRecitersFailed = true
            }
            isLoadingFeaturedReciters = false
        }
    }

    func onRetryFeaturedReciters() {
        didRequestReciterRefresh = false
        loadFeaturedReciters()
    }
}

// MARK: - Labels

extension HomeViewModel {

    var heroTitle: String {
        AppLocalizedKeys.homeHeroTitle.value
    }

    var searchAccessibilityLabel: String {
        AppLocalizedKeys.homeSearchAction.value
    }

    var locationAccessibilityLabel: String {
        String(format: AppLocalizedKeys.homeLocationAccessibility.value, locationLabel)
    }

    var nextPrayerLabel: String {
        AppLocalizedKeys.nextPrayerLabel.value
    }

    var nextPrayerHeroLine: String {
        nextPrayerName.isEmpty ? "" : "\(nextPrayerName) \(nextPrayerClock)"
    }

    var heroDhikrLine: String {
        AppLocalizedKeys.homeHeroDhikr.value
    }

    var prayerScheduleTitle: String {
        AppLocalizedKeys.prayerTimesTitle.value
    }

    var sectionTitleTracking: CGFloat {
        LocalizationManager.shared.currentLanguage == .Arabic ? 0 : 1.5
    }

    var seeAllTracking: CGFloat {
        LocalizationManager.shared.currentLanguage == .Arabic ? 0 : 1
    }

    var seeAllTitle: String {
        AppLocalizedKeys.seeAll.value
    }

    var featuredRecitersTitle: String {
        AppLocalizedKeys.featuredReciters.value
    }

    var featuredRecitersErrorTitle: String {
        AppLocalizedKeys.recitersLoadError.value
    }

    var featuredLessonsTitle: String {
        AppLocalizedKeys.featuredLessons.value
    }

    var featuredLessonsErrorTitle: String {
        AppLocalizedKeys.lessonsLoadError.value
    }

    var todayTitle: String {
        AppLocalizedKeys.homeTodayTitle.value
    }

    var todayPrayersLabel: String {
        AppLocalizedKeys.homeTodayPrayersLabel.value
    }

    var todayQuranLabel: String {
        AppLocalizedKeys.homeTodayQuranLabel.value
    }

    var prayedCountText: String {
        String(format: AppLocalizedKeys.prayersCompletedFormat.value, prayedCount, prayerCountTotal)
    }

    var prayerCountTotal: Int {
        5
    }

    var prayedFraction: Double {
        Double(prayedCount) / Double(prayerCountTotal)
    }

    var quranProgressText: String {
        "\(Int((lastReadProgress * 100).rounded()))%"
    }

    func prayerToggleAccessibilityLabel(for item: PrayerTimeItem) -> String {
        let key = item.isPrayed ? AppLocalizedKeys.markNotPrayedAccessibility : AppLocalizedKeys.markPrayedAccessibility
        return String(format: key.value, item.name)
    }

    var prayerTimesErrorTitle: String {
        AppLocalizedKeys.prayerTimesUnavailable.value
    }

    var retryTitle: String {
        AppLocalizedKeys.tryAgainAction.value
    }

    var continueReadingTitle: String {
        AppLocalizedKeys.continueReading.value
    }

    var pageTitle: String {
        AppLocalizedKeys.page.value
    }

    var resumeTitle: String {
        AppLocalizedKeys.resume.value
    }

    func displayName(for reciter: FeaturedReciter) -> String {
        let isArabic = LocalizationManager.shared.currentLanguage == .Arabic
        let name = isArabic ? reciter.nameAr : reciter.name
        return name.isEmpty ? reciter.name : name
    }
}

// MARK: - Navigation

extension HomeViewModel {

    func onQuickAccessTapped(_ item: QuickAccessItem) {
        switch item.type {
        case .quran:
            coordinator.coordinateToQuran(startPage: nil)
        case .recitations:
            coordinator.coordinateToRecitations()
        case .radio:
            coordinator.coordinateToRadio()
        case .egyptianRadio:
            coordinator.coordinateToEgyptianRadio()
        case .adhkar:
            coordinator.coordinateToAdhkar()
        case .khatmah:
            coordinator.coordinateToKhatmah()
        case .hadith:
            coordinator.coordinateToHadith()
        case .lessons:
            coordinator.coordinateToLessons()
        case .worship:
            coordinator.coordinateToWorship()
        case .content:
            coordinator.coordinateToContent()
        }
    }

    func onSearchTapped() {
        coordinator.coordinateToSearch()
    }

    func onSeeAllLessonsTapped() {
        coordinator.coordinateToLessons()
    }

    func onSeeAllRecitersTapped() {
        coordinator.coordinateToRecitations()
    }

    func onFeaturedReciterTapped(_ featured: FeaturedReciter) {
        guard let reciter = ReciterLibrary.reciter(for: featured.everyayahSlug) else {
            coordinator.coordinateToRecitations()
            return
        }
        coordinator.coordinateToReciterSurahs(reciter: reciter)
    }

    func onSheikhTapped(_ sheikh: Sheikh) {
        coordinator.coordinateToSheikhDetail(sheikh: sheikh)
    }

    func onResumeTapped() {
        coordinator.coordinateToQuran(startPage: lastReadPage)
    }

    func onPrayerTimesTapped() {
        coordinator.coordinateToPrayerTimes()
    }

    func onLiveStationTapped(_ station: RadioStation) {
        coordinator.coordinateToLiveStream(station: station, title: name(for: station))
    }
}

// MARK: - Live Stream

extension HomeViewModel {

    var hasLiveStations: Bool {
        !liveStations.isEmpty
    }

    var liveStreamTitle: String {
        AppLocalizedKeys.liveStreamTitle.value
    }

    var liveBadge: String {
        AppLocalizedKeys.radioLive.value
    }

    func name(for station: RadioStation) -> String {
        LocalizationManager.shared.currentLanguage == .Arabic ? station.nameAr : station.nameEn
    }

    private func loadLiveStations() {
        liveStations = RadioCatalogService.shared.currentStations().filter(\.isLive)

        Task { [weak self] in
            _ = try? await RadioCatalogService.shared.refresh()
            guard let self else { return }
            let refreshed = RadioCatalogService.shared.currentStations().filter(\.isLive)
            guard refreshed != self.liveStations else { return }
            self.liveStations = refreshed
        }
    }
}
