//
//  PrayerTimesViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import Foundation
import Combine
import Core

struct PrayerTimeRowItem: Identifiable {
    let id: String
    let title: String
    let iconName: String
    let clock: String
    let isNextPrayer: Bool
    let isPrayed: Bool
    let prayerCompletionIndex: Int?

    var isTrackable: Bool { prayerCompletionIndex != nil }
}

private struct DailyPrayerAnchor {
    let localizedKey: AppLocalizedKeys
    let iconName: String
    let minutesSinceMidnight: Int
    let prayerCompletionIndex: Int?
}

@MainActor
final class PrayerTimesViewModel: MainViewModel {

    @Published private(set) var rows: [PrayerTimeRowItem] = []
    @Published private(set) var otherRows: [PrayerTimeRowItem] = []
    @Published private(set) var isOtherTimesExpanded: Bool = false
    @Published private(set) var gregorianDateText: String = ""
    @Published private(set) var hijriDateText: String = ""
    @Published private(set) var calculationMethodText: String = ""
    @Published private(set) var locationLabel: String = ""
    @Published private(set) var isUsingDeviceLocation: Bool = false
    @Published private(set) var nextPrayerTitle: String = ""
    @Published private(set) var timeLeftDescription: String = ""
    @Published private(set) var prayedPrayerCount: Int = 0
    @Published private(set) var hasLoadedPrayerTimes: Bool = false
    @Published private(set) var hasFailedToLoadPrayerTimes: Bool = false

    private let prayerTimesStore = PrayerTimesStore.shared
    private let locationStore = SelectedLocationStore.shared
    private let completionStore = PrayerCompletionStore.shared
    private let locationLabelFormatter = SelectedLocationLabelFormatter()
    private weak var coordinator: PrayerTimesCoordinating?
    private var cancellables = Set<AnyCancellable>()
    private var currentDay: DayPrayerTimes?
    private var nextPrayerIdentifier: String = ""
    private var nextPrayerStartSeconds: Int = -1
    private var lastRefreshedMinute: Int = -1
    private var isRefreshingPrayerTimes: Bool = false
    private var lastDateTextsDayKey: String = ""

    var isTabBarVisible: Bool { false }

    init(coordinator: PrayerTimesCoordinating) {
        self.coordinator = coordinator
        locationLabel = locationLabelFormatter.displayLabel(for: locationStore.selectedLocation)
        isUsingDeviceLocation = locationStore.selectedLocation.isResolvedFromDevice
        loadDateTexts()
        bindPrayerTimes()
        bindSelectedLocation()
        bindRefreshState()
    }

    func onAppear() {
        prayerTimesStore.loadTodayForSelectedLocation()
        refreshSchedule()
    }
}

// MARK: - Titles

extension PrayerTimesViewModel {

    var screenTitle: String { AppLocalizedKeys.prayerTimesTitle.value }
    var screenSubtitle: String { AppLocalizedKeys.prayerTimesSubtitle.value }
    var nextPrayerLabel: String { AppLocalizedKeys.nextPrayerLabel.value }
    var changeLocationTitle: String { AppLocalizedKeys.locationChangeAction.value }
    var automaticLocationBadge: String { AppLocalizedKeys.locationAutomaticBadge.value }
    var errorTitle: String { AppLocalizedKeys.prayerTimesUnavailable.value }
    var retryTitle: String { AppLocalizedKeys.tryAgainAction.value }
    var scheduleSectionTitle: String { AppLocalizedKeys.prayerTimesScheduleTitle.value }
    var otherTimesTitle: String { AppLocalizedKeys.prayerTimesOtherTimes.value }

    var prayedSummary: String {
        String(format: AppLocalizedKeys.prayersCompletedFormat.value,
               prayedPrayerCount,
               PrayerTimesViewModel.trackablePrayerCount)
    }

    func prayerToggleAccessibilityLabel(for item: PrayerTimeRowItem) -> String {
        let key: AppLocalizedKeys = item.isPrayed ? .markNotPrayedAccessibility : .markPrayedAccessibility
        return String(format: key.value, item.title)
    }
}

// MARK: - Actions

extension PrayerTimesViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func onChangeLocationTapped() {
        coordinator?.coordinateToLocationPicker()
    }

    func onRetryTapped() {
        hasFailedToLoadPrayerTimes = false
        prayerTimesStore.reloadAfterSelectedLocationChange()
    }

    func onCountdownTick() {
        let minute = Int(Date().timeIntervalSince1970 / 60)
        guard minute != lastRefreshedMinute else { return }
        lastRefreshedMinute = minute
        prayerTimesStore.loadTodayForSelectedLocation()
        loadDateTextsIfDayChanged()
        refreshSchedule()
    }

    func countdownText(at date: Date) -> String {
        guard let day = currentDay, nextPrayerStartSeconds >= 0 else { return "" }

        var remaining = nextPrayerStartSeconds - day.seconds(at: date)
        if remaining <= 0 { remaining += PrayerTimesViewModel.secondsPerDay }
        return PrayerTimesViewModel.countdownString(forSecondsRemaining: remaining)
    }

    func toggleOtherTimes() {
        isOtherTimesExpanded.toggle()
    }

    func togglePrayed(for item: PrayerTimeRowItem) {
        guard let index = item.prayerCompletionIndex, let day = currentDay else { return }
        completionStore.toggle(index: index, on: day.dayKey)
        rebuildRows(anchors: PrayerTimesViewModel.anchors(of: day), dayKey: day.dayKey)
        rebuildOtherRows(of: day)
    }
}

// MARK: - Bindings

private extension PrayerTimesViewModel {

    func bindPrayerTimes() {
        prayerTimesStore.$today
            .receive(on: DispatchQueue.main)
            .sink { [weak self] day in
                self?.currentDay = day
                self?.lastRefreshedMinute = -1
                self?.refreshSchedule()
            }
            .store(in: &cancellables)
    }

    func bindRefreshState() {
        prayerTimesStore.$isRefreshing
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRefreshing in
                self?.isRefreshingPrayerTimes = isRefreshing
                self?.refreshSchedule()
            }
            .store(in: &cancellables)
    }

    func bindSelectedLocation() {
        locationStore.$selectedLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                self.locationLabel = self.locationLabelFormatter.displayLabel(for: location)
                self.isUsingDeviceLocation = location.isResolvedFromDevice
            }
            .store(in: &cancellables)
    }
}

// MARK: - Schedule

private extension PrayerTimesViewModel {

    func refreshSchedule() {
        guard let day = currentDay else {
            clearSchedule()
            return
        }

        let anchors = PrayerTimesViewModel.anchors(of: day)
        guard let nextPrayer = PrayerTimesViewModel.nextPrayer(in: anchors,
                                                               nowMinutes: day.minutes(at: Date()))
        else {
            clearSchedule()
            return
        }

        nextPrayerIdentifier = nextPrayer.localizedKey.rawValue
        nextPrayerStartSeconds = nextPrayer.minutesSinceMidnight * 60
        nextPrayerTitle = nextPrayer.localizedKey.value.capitalized
        timeLeftDescription = String(format: AppLocalizedKeys.leftUntilPrayer.value, nextPrayerTitle)

        rebuildRows(anchors: anchors, dayKey: day.dayKey)
        rebuildOtherRows(of: day)
        calculationMethodText = PrayerTimesViewModel.calculationMethodName(of: day)
        hasLoadedPrayerTimes = true
        hasFailedToLoadPrayerTimes = false
    }

    func clearSchedule() {
        rows = []
        otherRows = []
        nextPrayerIdentifier = ""
        nextPrayerStartSeconds = -1
        nextPrayerTitle = ""
        timeLeftDescription = ""
        prayedPrayerCount = 0
        hasLoadedPrayerTimes = false
        hasFailedToLoadPrayerTimes = !isRefreshingPrayerTimes
    }

    func rebuildRows(anchors: [DailyPrayerAnchor], dayKey: String) {
        let prayedIndices = completionStore.prayed(on: dayKey)

        rows = anchors.map { anchor in
            PrayerTimeRowItem(id: anchor.localizedKey.rawValue,
                              title: anchor.localizedKey.value.capitalized,
                              iconName: anchor.iconName,
                              clock: PrayerClockFormatter.twelveHourClock(fromMinutesSinceMidnight: anchor.minutesSinceMidnight),
                              isNextPrayer: anchor.localizedKey.rawValue == nextPrayerIdentifier,
                              isPrayed: anchor.prayerCompletionIndex.map(prayedIndices.contains) ?? false,
                              prayerCompletionIndex: anchor.prayerCompletionIndex)
        }
        prayedPrayerCount = prayedIndices.count
    }

    func rebuildOtherRows(of day: DayPrayerTimes) {
        otherRows = PrayerTimesViewModel.otherAnchors(of: day).map { anchor in
            PrayerTimeRowItem(id: anchor.localizedKey.rawValue,
                              title: anchor.localizedKey.value,
                              iconName: anchor.iconName,
                              clock: PrayerClockFormatter.twelveHourClock(fromMinutesSinceMidnight: anchor.minutesSinceMidnight),
                              isNextPrayer: false,
                              isPrayed: false,
                              prayerCompletionIndex: nil)
        }
    }

    func loadDateTextsIfDayChanged() {
        let dayKey = PrayerTimesViewModel.dateTextsDayKey()
        guard dayKey != lastDateTextsDayKey else { return }
        loadDateTexts()
    }

    static func dateTextsDayKey() -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    func loadDateTexts() {
        lastDateTextsDayKey = PrayerTimesViewModel.dateTextsDayKey()
        let languageCode = LocalizationManager.shared.currentLanguage == .Arabic ? "ar" : "en"
        let today = Date()

        gregorianDateText = PrayerTimesViewModel.dateText(for: today,
                                                          identifier: .gregorian,
                                                          languageCode: languageCode,
                                                          format: AppLocalizedKeys.prayerTimesGregorianFormat.value)
        hijriDateText = PrayerTimesViewModel.dateText(for: today,
                                                      identifier: .islamicUmmAlQura,
                                                      languageCode: languageCode,
                                                      format: AppLocalizedKeys.homeHijriFormat.value)
    }

    static func dateText(for date: Date,
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

    static func calculationMethodName(of day: DayPrayerTimes) -> String {
        guard let methodId = day.calculationMethodId,
              let localizedKey = AppLocalizedKeys.prayerCalculationMethodKey(forMethodId: methodId)
        else { return day.calculationMethodName ?? "" }

        return localizedKey.value
    }
}

// MARK: - Anchors

private extension PrayerTimesViewModel {

    static let trackablePrayerCount = 5
    static let secondsPerDay = 24 * 60 * 60

    static func anchors(of day: DayPrayerTimes) -> [DailyPrayerAnchor] {
        [
            DailyPrayerAnchor(localizedKey: .fajr,
                              iconName: "moon.stars.fill",
                              minutesSinceMidnight: day.fajr,
                              prayerCompletionIndex: 0),
            DailyPrayerAnchor(localizedKey: .sunrise,
                              iconName: "sunrise.fill",
                              minutesSinceMidnight: day.sunrise,
                              prayerCompletionIndex: nil),
            DailyPrayerAnchor(localizedKey: .dhuhr,
                              iconName: "sun.max.fill",
                              minutesSinceMidnight: day.dhuhr,
                              prayerCompletionIndex: 1),
            DailyPrayerAnchor(localizedKey: .asr,
                              iconName: "sun.min.fill",
                              minutesSinceMidnight: day.asr,
                              prayerCompletionIndex: 2),
            DailyPrayerAnchor(localizedKey: .maghrib,
                              iconName: "sunset.fill",
                              minutesSinceMidnight: day.maghrib,
                              prayerCompletionIndex: 3),
            DailyPrayerAnchor(localizedKey: .isha,
                              iconName: "moon.fill",
                              minutesSinceMidnight: day.isha,
                              prayerCompletionIndex: 4)
        ]
    }

    static func otherAnchors(of day: DayPrayerTimes) -> [DailyPrayerAnchor] {
        [
            DailyPrayerAnchor(localizedKey: .duha,
                              iconName: "sun.and.horizon.fill",
                              minutesSinceMidnight: day.duha,
                              prayerCompletionIndex: nil),
            DailyPrayerAnchor(localizedKey: .islamicMidnight,
                              iconName: "moon.zzz.fill",
                              minutesSinceMidnight: day.midnight,
                              prayerCompletionIndex: nil),
            DailyPrayerAnchor(localizedKey: .lastThirdOfNight,
                              iconName: "moon.haze.fill",
                              minutesSinceMidnight: day.lastThird,
                              prayerCompletionIndex: nil)
        ]
    }

    static func nextPrayer(in anchors: [DailyPrayerAnchor], nowMinutes: Int) -> DailyPrayerAnchor? {
        let trackablePrayers = anchors.filter { $0.prayerCompletionIndex != nil }
        return trackablePrayers.first { $0.minutesSinceMidnight > nowMinutes } ?? trackablePrayers.first
    }

    static func countdownString(forSecondsRemaining remaining: Int) -> String {
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let seconds = remaining % 60

        guard hours > 0 else { return String(format: "%d:%02d", minutes, seconds) }
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
}
