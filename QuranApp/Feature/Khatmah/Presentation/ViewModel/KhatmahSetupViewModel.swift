//
//  KhatmahSetupViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

enum KhatmahPaceMode: Int, CaseIterable, Identifiable {
    case duration
    case targetDate

    var id: Int { rawValue }
}

@MainActor
final class KhatmahSetupViewModel: MainViewModel {

    @Published var paceMode: KhatmahPaceMode = .duration

    @Published var totalDays: Int = KhatmahDurationPreset.month.dayCount {
        didSet {
            guard totalDays != oldValue else { return }
            alignTargetDateWithDuration()
        }
    }

    @Published var targetDate: Date {
        didSet {
            guard !calendar.isDate(targetDate, inSameDayAs: oldValue) else { return }
            alignDurationWithTargetDate()
        }
    }

    @Published var startDate: Date {
        didSet {
            guard !calendar.isDate(startDate, inSameDayAs: oldValue) else { return }
            alignTargetDateWithDuration()
        }
    }

    @Published var startPage: Int = KhatmahPageBounds.firstPage
    @Published var isReminderEnabled: Bool = KhatmahReminder.default.isEnabled
    @Published var reminderTime: Date
    @Published private(set) var startPageSurahName: String = ""

    private let store: KhatmahPlanStore
    private var surahNameTask: Task<Void, Never>?

    var isTabBarVisible: Bool { false }

    init(store: KhatmahPlanStore? = nil) {
        let store = store ?? KhatmahPlanStore.shared
        self.store = store

        let calendar = store.dayCalendar
        let today = calendar.startOfDay(for: Date())
        let presetDays = KhatmahDurationPreset.month.dayCount

        self.startDate = today
        self.targetDate = calendar.date(byAdding: .day, value: presetDays - 1, to: today) ?? today
        self.reminderTime = calendar.date(
            bySettingHour: KhatmahReminder.default.hour,
            minute: KhatmahReminder.default.minute,
            second: 0,
            of: today
        ) ?? today
    }

    func onAppear() {
        resolveStartPageSurahName()
    }

    func onDisappear() {
        surahNameTask?.cancel()
        surahNameTask = nil
    }
}

// MARK: - Reads

extension KhatmahSetupViewModel {

    var calendar: Calendar { store.dayCalendar }

    var earliestStartDate: Date { calendar.startOfDay(for: Date()) }

    var earliestTargetDate: Date { startDate }

    var selectedPreset: KhatmahDurationPreset? {
        KhatmahDurationPreset.allCases.first { $0.dayCount == totalDays }
    }

    var pageCount: Int { KhatmahPageBounds.lastPage - startPage + 1 }

    var maximumDays: Int { pageCount }

    var pagesPerDay: Int {
        guard totalDays > 0 else { return pageCount }
        return Int((Double(pageCount) / Double(totalDays)).rounded())
    }

    var canAdvance: Bool { totalDays >= 1 && totalDays <= maximumDays }
}

// MARK: - Labels

extension KhatmahSetupViewModel {

    var screenTitle: String { AppLocalizedKeys.khatmahSetupTitle.value }
    var paceTitle: String { AppLocalizedKeys.khatmahSetupPaceTitle.value }
    var paceCaption: String { AppLocalizedKeys.khatmahSetupPaceCaption.value }
    var durationSectionTitle: String { AppLocalizedKeys.khatmahSetupDurationSection.value }
    var targetDateSectionTitle: String { AppLocalizedKeys.khatmahSetupTargetDateSection.value }
    var startTitle: String { AppLocalizedKeys.khatmahSetupStartTitle.value }
    var startCaption: String { AppLocalizedKeys.khatmahSetupStartCaption.value }
    var startDateTitle: String { AppLocalizedKeys.khatmahSetupStartDate.value }
    var startPageTitle: String { AppLocalizedKeys.khatmahSetupStartPage.value }
    var reminderSectionTitle: String { AppLocalizedKeys.khatmahReminderSection.value }
    var reminderToggleTitle: String { AppLocalizedKeys.khatmahReminderToggle.value }
    var reminderTimeTitle: String { AppLocalizedKeys.khatmahReminderTimeTitle.value }
    var createActionTitle: String { AppLocalizedKeys.khatmahSetupCreateAction.value }
    var cancelActionTitle: String { AppLocalizedKeys.cancel.value }

    var pagesPerDayText: String {
        String(format: AppLocalizedKeys.khatmahPagesPerDayFormat.value, localizedNumber(pagesPerDay))
    }

    var totalDaysText: String {
        String(format: AppLocalizedKeys.khatmahDaysFormat.value, localizedNumber(totalDays))
    }

    var startPageText: String {
        let page = String(format: AppLocalizedKeys.khatmahPageRangeFormat.value,
                          localizedNumber(startPage),
                          localizedNumber(KhatmahPageBounds.lastPage))
        guard !startPageSurahName.isEmpty else { return page }
        return "\(page) · \(startPageSurahName)"
    }

    func durationTitle(for preset: KhatmahDurationPreset) -> String {
        String(format: AppLocalizedKeys.khatmahDaysFormat.value, localizedNumber(preset.dayCount))
    }

    func pageNumberText(for page: Int) -> String {
        localizedNumber(page)
    }
}

// MARK: - Actions

extension KhatmahSetupViewModel {

    func selectPreset(_ preset: KhatmahDurationPreset) {
        totalDays = min(preset.dayCount, maximumDays)
    }

    func selectStartPage(_ page: Int) {
        let clamped = min(max(page, KhatmahPageBounds.firstPage), KhatmahPageBounds.lastPage)
        guard clamped != startPage else { return }
        startPage = clamped
        totalDays = min(totalDays, maximumDays)
        resolveStartPageSurahName()
    }

    @discardableResult
    func createPlan() -> KhatmahPlan? {
        guard canAdvance else { return nil }

        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let reminder = KhatmahReminder(
            isEnabled: isReminderEnabled,
            hour: components.hour ?? KhatmahReminder.default.hour,
            minute: components.minute ?? KhatmahReminder.default.minute
        )

        return store.createPlan(
            totalDays: totalDays,
            startDate: startDate,
            startPage: startPage,
            reminder: reminder
        )
    }
}

// MARK: - Pace Binding

private extension KhatmahSetupViewModel {

    func alignTargetDateWithDuration() {
        let aligned = calendar.date(byAdding: .day, value: totalDays - 1, to: startDate) ?? startDate
        targetDate = aligned
    }

    func alignDurationWithTargetDate() {
        let span = store.dayCount(from: startDate, to: targetDate)
        totalDays = min(max(span, 1), maximumDays)
    }

    func resolveStartPageSurahName() {
        surahNameTask?.cancel()
        let page = startPage
        let isArabic = LocalizationManager.shared.currentLanguage == .Arabic

        surahNameTask = Task.detached(priority: .userInitiated) { [weak self] in
            let surahs = QuranDatabase.shared.getSurahsForPage(page)
            let name = surahs.first.map { isArabic ? $0.arabicTitle : $0.englishTitle } ?? ""

            guard !Task.isCancelled, let self else { return }
            await self.applyStartPageSurahName(name, forPage: page)
        }
    }

    func applyStartPageSurahName(_ name: String, forPage page: Int) {
        guard page == startPage else { return }
        startPageSurahName = name
    }

    func localizedNumber(_ value: Int) -> String {
        LocalizationManager.shared.currentLanguage == .Arabic ? value.arabicNumerals : "\(value)"
    }
}
