//
//  HijriCalendarViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation
import Combine
import Core

@MainActor
final class HijriCalendarViewModel: MainViewModel {

    @Published private(set) var month: HijriCalendarMonth = .empty
    @Published private(set) var monthTitle: String = ""
    @Published private(set) var weekdayTitles: [String] = []
    @Published private(set) var cells: [HijriCalendarCell] = []
    @Published private(set) var selectedDay: HijriCalendarDay?

    var isTabBarVisible: Bool { false }

    weak var coordinator: HijriCalendarCoordinating?

    private let gridBuilder: HijriMonthGridBuilder
    private let localizationManager: LocalizationManager
    private let today: Date
    private var monthOffset = 0

    init(coordinator: HijriCalendarCoordinating,
         gridBuilder: HijriMonthGridBuilder = HijriMonthGridBuilder(),
         localizationManager: LocalizationManager = .shared,
         today: Date = Date()) {
        self.coordinator = coordinator
        self.gridBuilder = gridBuilder
        self.localizationManager = localizationManager
        self.today = today
    }

    func onAppear() {
        guard month.isEmpty else { return }
        loadMonth()
    }

    // MARK: - Month navigation

    func showPreviousMonth() {
        monthOffset -= 1
        loadMonth()
    }

    func showNextMonth() {
        monthOffset += 1
        loadMonth()
    }

    func returnToCurrentMonth() {
        guard monthOffset != 0 else { return }
        monthOffset = 0
        loadMonth()
    }

    func selectDay(_ day: HijriCalendarDay) {
        selectedDay = day
    }

    func coordinateBack() {
        coordinator?.coordinateBack()
    }

    var isCurrentMonth: Bool { monthOffset == 0 }

    private func loadMonth() {
        let loaded = gridBuilder.month(offsetBy: monthOffset, from: today, today: today)
        month = loaded
        monthTitle = Self.monthTitle(of: loaded, languageCode: languageCode)
        weekdayTitles = gridBuilder.weekdayTitles(languageCode: languageCode)
        cells = loaded.cells
        selectedDay = loaded.todayDay ?? loaded.days.first
    }

    private static func monthTitle(of month: HijriCalendarMonth, languageCode: String) -> String {
        guard let firstDate = month.firstDate else { return "" }
        let name = HijriCalendarDateTextFormatter.text(for: firstDate,
                                                       identifier: .islamicUmmAlQura,
                                                       languageCode: languageCode,
                                                       format: AppLocalizedKeys.hijriCalendarMonthFormat.value)
        return "\(name) \(AppLocalizedKeys.hijriEraSuffix.value)"
    }

    // MARK: - Labels

    var navigationTitle: String { AppLocalizedKeys.hijriCalendarTitle.value }

    var todayTitle: String { AppLocalizedKeys.today.value }

    var occasionsSectionTitle: String { AppLocalizedKeys.hijriCalendarOccasionsTitle.value }

    var noOccasionMessage: String { AppLocalizedKeys.hijriCalendarNoOccasionMessage.value }

    var previousMonthAccessibilityLabel: String { AppLocalizedKeys.hijriCalendarPreviousMonth.value }

    var nextMonthAccessibilityLabel: String { AppLocalizedKeys.hijriCalendarNextMonth.value }

    var selectedHijriDateText: String {
        guard let day = selectedDay else { return "" }
        let text = HijriCalendarDateTextFormatter.text(for: day.gregorianDate,
                                                       identifier: .islamicUmmAlQura,
                                                       languageCode: languageCode,
                                                       format: AppLocalizedKeys.homeHijriFormat.value)
        return "\(text) \(AppLocalizedKeys.hijriEraSuffix.value)"
    }

    var selectedGregorianDateText: String {
        guard let day = selectedDay else { return "" }
        return HijriCalendarDateTextFormatter.text(for: day.gregorianDate,
                                                   identifier: .gregorian,
                                                   languageCode: languageCode,
                                                   format: AppLocalizedKeys.hijriCalendarGregorianDayFormat.value)
    }

    var selectedOccasions: [IslamicOccasion] { selectedDay?.occasions ?? [] }

    func occasionTitle(_ occasion: IslamicOccasion) -> String {
        occasion.titleKey.value
    }

    func dayNumberText(_ day: HijriCalendarDay) -> String {
        number(day.hijriDay)
    }

    func dayAccessibilityLabel(_ day: HijriCalendarDay) -> String {
        let titles = day.occasions.map { $0.titleKey.value }
        let date = HijriCalendarDateTextFormatter.text(for: day.gregorianDate,
                                                       identifier: .islamicUmmAlQura,
                                                       languageCode: languageCode,
                                                       format: AppLocalizedKeys.homeHijriFormat.value)
        guard !titles.isEmpty else { return date }
        return "\(date) · \(titles.joined(separator: " · "))"
    }

    // MARK: - Formatting

    private var isArabic: Bool { localizationManager.currentLanguage == .Arabic }

    private var languageCode: String { isArabic ? "ar" : "en" }

    private func number(_ value: Int) -> String {
        isArabic ? value.arabicNumerals : String(value)
    }
}
