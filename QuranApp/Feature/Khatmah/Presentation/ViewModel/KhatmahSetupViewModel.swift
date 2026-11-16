//
//  KhatmahSetupViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Core

// MARK: - KhatmahPaceMode

enum KhatmahPaceMode: Int, CaseIterable, Identifiable {
    case duration
    case targetDate

    var id: Int { rawValue }
}

// MARK: - KhatmahSetupStep

enum KhatmahSetupStep: Int, CaseIterable, Identifiable {
    case pace
    case startingPoint

    var id: Int { rawValue }
}

// MARK: - KhatmahStartOption

struct KhatmahStartOption: Identifiable, Equatable {

    let page: Int
    let title: String
    let detail: String

    var id: Int { page }
}

// MARK: - KhatmahSetupViewModel

@MainActor
final class KhatmahSetupViewModel: MainViewModel {

    @Published private(set) var step: KhatmahSetupStep = .pace
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

    @Published private(set) var startPage: Int = KhatmahPageBounds.firstPage
    @Published private(set) var startOptions: [KhatmahStartOption] = []
    @Published var isJuzPickerExpanded: Bool = false
    @Published var isCustomPageExpanded: Bool = false
    @Published var isReminderEnabled: Bool = KhatmahReminder.default.isEnabled
    @Published var reminderTime: Date

    private let store: KhatmahPlanStore
    private var startOptionsTask: Task<Void, Never>?

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
        resolveStartOptions()
    }

    func onDisappear() {
        startOptionsTask?.cancel()
        startOptionsTask = nil
    }
}

// MARK: - Reads

extension KhatmahSetupViewModel {

    var calendar: Calendar { store.dayCalendar }

    var pickerLocale: Locale { KhatmahLocalizedFormatting.locale }

    var pickerTimeZone: TimeZone { store.dayCalendar.timeZone }

    var earliestStartDate: Date { calendar.startOfDay(for: Date()) }

    var earliestTargetDate: Date { startDate }

    var selectedPreset: KhatmahDurationPreset? {
        KhatmahDurationPreset.allCases.first { $0.dayCount == totalDays }
    }

    var pageCount: Int { KhatmahPageBounds.lastPage - startPage + 1 }

    var maximumDays: Int { pageCount }

    var pagesPerDay: Int { pagesPerDay(forDays: totalDays) }

    var canAdvance: Bool { totalDays >= 1 && totalDays <= maximumDays }

    var isFinalStep: Bool { step == .startingPoint }

    var isCustomPageSelected: Bool {
        !startOptions.contains { $0.page == startPage }
    }

    var isJuzSelected: Bool { !isCustomPageSelected }

    var selectedJuzOption: KhatmahStartOption? {
        startOptions.last { $0.page <= startPage } ?? startOptions.first
    }

    func pagesPerDay(forDays days: Int) -> Int {
        guard days > 0 else { return pageCount }
        return Int((Double(pageCount) / Double(days)).rounded())
    }
}

// MARK: - Labels

extension KhatmahSetupViewModel {

    var screenTitle: String { AppLocalizedKeys.khatmahSetupTitle.value }
    var paceSegmentTitle: String { AppLocalizedKeys.khatmahSetupPaceTitle.value }
    var durationSectionTitle: String { AppLocalizedKeys.khatmahSetupDurationSection.value }
    var targetDateSectionTitle: String { AppLocalizedKeys.khatmahSetupTargetDateSection.value }
    var lastDayTitle: String { AppLocalizedKeys.khatmahLastDayLabel.value }
    var captionTracking: CGFloat { KhatmahLocalizedFormatting.isArabic ? 0 : 1.5 }
    var startDateTitle: String { AppLocalizedKeys.khatmahSetupStartDate.value }
    var startPageTitle: String { AppLocalizedKeys.khatmahSetupStartPage.value }
    var customPageTitle: String { AppLocalizedKeys.khatmahStartCustomPage.value }
    var juzPickerTitle: String { AppLocalizedKeys.juz.value }
    var reminderToggleTitle: String { AppLocalizedKeys.khatmahReminderToggle.value }
    var reminderTimeTitle: String { AppLocalizedKeys.khatmahReminderTimeTitle.value }
    var backActionTitle: String { AppLocalizedKeys.khatmahBackAction.value }
    var cancelActionTitle: String { AppLocalizedKeys.cancel.value }

    var stepText: String {
        String(format: AppLocalizedKeys.khatmahStepFormat.value,
               KhatmahLocalizedFormatting.number(step.rawValue + 1),
               KhatmahLocalizedFormatting.number(KhatmahSetupStep.allCases.count))
    }

    var stepTitle: String {
        switch step {
        case .pace:          return AppLocalizedKeys.khatmahSetupPaceTitle.value
        case .startingPoint: return AppLocalizedKeys.khatmahSetupStartTitle.value
        }
    }

    var stepCaption: String {
        switch step {
        case .pace:          return AppLocalizedKeys.khatmahSetupPaceCaption.value
        case .startingPoint: return AppLocalizedKeys.khatmahSetupStartCaption.value
        }
    }

    var primaryActionTitle: String {
        isFinalStep
            ? AppLocalizedKeys.khatmahSetupCreateAction.value
            : AppLocalizedKeys.khatmahNextAction.value
    }

    var totalDaysText: String {
        KhatmahLocalizedFormatting.dayCount(totalDays)
    }

    var workloadText: String {
        KhatmahWorkload.forPagesPerDay(pagesPerDay).localizedLabel
    }

    var paceSummaryText: String {
        "\(totalDaysText) \u{00B7} \(workloadText)"
    }

    var customPageDetailText: String {
        guard isCustomPageSelected else { return "" }
        return String(format: AppLocalizedKeys.khatmahPageNumberFormat.value,
                      KhatmahLocalizedFormatting.number(startPage))
    }

    var juzSelectionTitle: String { selectedJuzOption?.title ?? juzPickerTitle }

    var juzSelectionDetailText: String { selectedJuzOption?.detail ?? "" }

    func durationTitle(for preset: KhatmahDurationPreset) -> String {
        KhatmahLocalizedFormatting.dayCount(preset.dayCount)
    }

    func workloadText(for preset: KhatmahDurationPreset) -> String {
        KhatmahWorkload.forPagesPerDay(pagesPerDay(forDays: min(preset.dayCount, maximumDays))).localizedLabel
    }

    func pageNumberText(for page: Int) -> String {
        KhatmahLocalizedFormatting.number(page)
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
    }

    func toggleJuzPicker() {
        isCustomPageExpanded = false

        if isCustomPageSelected, let page = selectedJuzOption?.page {
            selectStartPage(page)
        }

        isJuzPickerExpanded.toggle()
    }

    func toggleCustomPage() {
        isJuzPickerExpanded = false
        isCustomPageExpanded.toggle()
    }

    func onBackTapped() {
        step = .pace
    }

    @discardableResult
    func onPrimaryTapped() -> KhatmahPlan? {
        guard isFinalStep else {
            step = .startingPoint
            return nil
        }
        return createPlan()
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
}

// MARK: - Start Options

private extension KhatmahSetupViewModel {

    func resolveStartOptions() {
        if startOptions.isEmpty {
            applyStartOptions([:])
        }

        startOptionsTask?.cancel()
        let isArabic = KhatmahLocalizedFormatting.isArabic
        let pages = QuranDatabase.juzStartPages

        startOptionsTask = Task.detached(priority: .userInitiated) { [weak self] in
            let points = await KhatmahVerseRangeIndex.shared.startPoints(ofPages: pages, isArabic: isArabic)

            guard !Task.isCancelled, let self, !points.isEmpty else { return }
            await self.applyStartOptions(points)
        }
    }

    func applyStartOptions(_ points: [Int: KhatmahVersePoint]) {
        startOptions = QuranDatabase.juzStartPages.enumerated().map { index, page in
            let juzNumber = index + 1
            let title = juzNumber == 1
                ? AppLocalizedKeys.khatmahStartFromBeginning.value
                : AppLocalizedKeys.juzKey(juzNumber).value

            return KhatmahStartOption(page: page, title: title, detail: detailLabel(for: points[page], page: page))
        }
    }

    func detailLabel(for point: KhatmahVersePoint?, page: Int) -> String {
        let pageText = String(format: AppLocalizedKeys.khatmahPageNumberFormat.value, KhatmahLocalizedFormatting.number(page))
        guard let point, !point.surahName.isEmpty else { return pageText }

        let verseText = String(format: AppLocalizedKeys.khatmahVersePointFormat.value,
                               point.surahName,
                               KhatmahLocalizedFormatting.number(point.verseNumber))
        return "\(verseText) · \(pageText)"
    }
}
