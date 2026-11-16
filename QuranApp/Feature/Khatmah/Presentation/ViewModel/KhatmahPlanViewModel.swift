//
//  KhatmahPlanViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Combine
import Core
import UIKit

struct KhatmahMetric: Identifiable {
    let id: Int
    let value: String
    let title: String
}

struct KhatmahDayItem: Identifiable {
    let id: Int
    let dayNumber: Int
    let title: String
    let pageRange: String
    let verseRange: String
    let statusTitle: String
    let statusAccent: ColorStyle
    let isCompleted: Bool
    let isToday: Bool
    let isMissed: Bool

    var accessibilityLabel: String {
        [title, statusTitle, verseRange, pageRange]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

@MainActor
final class KhatmahPlanViewModel: MainViewModel {

    @Published private(set) var hasPlan: Bool = false
    @Published private(set) var todayDayNumber: Int = 1
    @Published private(set) var todayPageCount: String = ""
    @Published private(set) var todayWorkloadText: String = ""
    @Published private(set) var todayPortionText: String = ""
    @Published private(set) var todayPageRangeText: String = ""
    @Published private(set) var isTodayCompleted: Bool = false
    @Published private(set) var hasStarted: Bool = true
    @Published private(set) var startsOnText: String = ""
    @Published private(set) var dayOfTotalText: String = ""
    @Published private(set) var daysRemainingText: String = ""
    @Published private(set) var percentText: String = ""
    @Published private(set) var progressFraction: Double = 0
    @Published private(set) var remainingPagesText: String = ""
    @Published private(set) var expectedCompletionText: String = ""
    @Published private(set) var driftText: String = ""
    @Published private(set) var driftAccent: ColorStyle = .primary
    @Published private(set) var isBehindSchedule: Bool = false
    @Published private(set) var metrics: [KhatmahMetric] = []
    @Published private(set) var metricsAccessibilityLabel: String = ""
    @Published private(set) var completedCountText: String = ""
    @Published private(set) var allDaysText: String = ""
    @Published private(set) var isPlanCompleted: Bool = false
    @Published private(set) var isReminderEnabled: Bool = false
    @Published private(set) var reminderTime: Date = Date()
    @Published private(set) var isAuthorizationDenied: Bool = false

    @Published var isSetupPresented: Bool = false
    @Published var isDeleteConfirmationPresented: Bool = false

    private let store: KhatmahPlanStore
    private let scheduler: KhatmahReminderScheduler
    private weak var coordinator: KhatmahCoordinating?
    private var cancellables = Set<AnyCancellable>()
    private var verseRangeTask: Task<Void, Never>?

    var isTabBarVisible: Bool { false }

    init(coordinator: KhatmahCoordinating,
         store: KhatmahPlanStore? = nil,
         scheduler: KhatmahReminderScheduler? = nil) {
        self.coordinator = coordinator
        self.store = store ?? KhatmahPlanStore.shared
        self.scheduler = scheduler ?? KhatmahReminderScheduler.shared
        observeStores()
        reloadPlanState()
    }

    func onAppear() {
        reloadPlanState()
        Task { await scheduler.refreshAuthorizationStatus() }
    }

    func onDisappear() {
        verseRangeTask?.cancel()
        verseRangeTask = nil
    }
}

// MARK: - Labels

extension KhatmahPlanViewModel {

    var screenTitle: String { AppLocalizedKeys.khatmahTitle.value }
    var todayTitle: String { AppLocalizedKeys.khatmahTodayTitle.value }
    var captionTracking: CGFloat { KhatmahLocalizedFormatting.isArabic ? 0 : 1.5 }
    var todayDoneTitle: String { AppLocalizedKeys.khatmahTodayDoneTitle.value }
    var readActionTitle: String { AppLocalizedKeys.khatmahReadAction.value }
    var markCompleteActionTitle: String { AppLocalizedKeys.khatmahMarkCompleteAction.value }
    var expectedCompletionTitle: String { AppLocalizedKeys.khatmahExpectedCompletionTitle.value }
    var daysLeftTitle: String { AppLocalizedKeys.khatmahDaysLeftTitle.value }
    var pagesLeftTitle: String { AppLocalizedKeys.khatmahPagesLeftTitle.value }
    var reminderToggleTitle: String { AppLocalizedKeys.khatmahReminderToggle.value }
    var reminderTimeTitle: String { AppLocalizedKeys.khatmahReminderTimeTitle.value }
    var deleteActionTitle: String { AppLocalizedKeys.khatmahDeleteAction.value }
    var deleteConfirmationTitle: String { AppLocalizedKeys.khatmahDeleteTitle.value }
    var deleteConfirmationMessage: String { AppLocalizedKeys.khatmahDeleteMessage.value }
    var cancelActionTitle: String { AppLocalizedKeys.cancel.value }
    var backActionTitle: String { AppLocalizedKeys.khatmahBackAction.value }
    var emptyTitle: String { AppLocalizedKeys.khatmahEmptyTitle.value }
    var emptyMessage: String { AppLocalizedKeys.khatmahEmptyMessage.value }
    var newPlanActionTitle: String { AppLocalizedKeys.khatmahNewPlanAction.value }
    var completedTitle: String { AppLocalizedKeys.khatmahCompletedTitle.value }
    var completedMessage: String { AppLocalizedKeys.khatmahCompletedMessage.value }
    var authorizationDeniedBody: String { AppLocalizedKeys.khatmahNotificationsDeniedBody.value }
    var openSystemSettingsTitle: String { AppLocalizedKeys.prayerNotificationsOpenSystemSettings.value }
    var howItWorksTitle: String { AppLocalizedKeys.khatmahHowItWorksTitle.value }

    func stepNumberText(_ number: Int) -> String {
        KhatmahLocalizedFormatting.number(number)
    }

    var howItWorksSteps: [String] {
        [
            AppLocalizedKeys.khatmahHowItWorksPace.value,
            AppLocalizedKeys.khatmahHowItWorksPortion.value,
            AppLocalizedKeys.khatmahHowItWorksReminder.value
        ]
    }

    var pickerLocale: Locale { KhatmahLocalizedFormatting.locale }

    var pickerTimeZone: TimeZone { store.dayCalendar.timeZone }
}

// MARK: - Actions

extension KhatmahPlanViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func onStartPlanTapped() {
        isSetupPresented = true
    }

    func onSetupFinished() {
        isSetupPresented = false
        reloadPlanState()
    }

    func onReadTodayTapped() {
        guard let schedule = store.activeSchedule else { return }
        coordinator?.coordinateToQuranPage(schedule.resumePage)
    }

    func onMarkTodayCompleteTapped() {
        store.markDayCompleted(todayDayNumber)
        reloadPlanState()
    }

    func onAllDaysTapped() {
        coordinator?.coordinateToSchedule()
    }

    func onDeleteTapped() {
        isDeleteConfirmationPresented = true
    }

    func onDeleteConfirmed() {
        isDeleteConfirmationPresented = false
        store.archiveActivePlan()
        reloadPlanState()
    }

    func onReminderToggled(_ isEnabled: Bool) {
        guard var reminder = store.activePlan?.reminder else { return }
        reminder.isEnabled = isEnabled
        store.updateReminder(reminder)

        guard isEnabled else { return }
        Task { await scheduler.requestAuthorization() }
    }

    func onReminderTimeChanged(_ date: Date) {
        guard var reminder = store.activePlan?.reminder else { return }
        let components = store.dayCalendar.dateComponents([.hour, .minute], from: date)
        reminder.hour = components.hour ?? reminder.hour
        reminder.minute = components.minute ?? reminder.minute
        store.updateReminder(reminder)
    }

    func onOpenSystemSettingsTapped() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - State

private extension KhatmahPlanViewModel {

    func observeStores() {
        store.$activePlan
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadPlanState()
            }
            .store(in: &cancellables)

        scheduler.$authorizationStatus
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isAuthorizationDenied = status.isDenied
            }
            .store(in: &cancellables)
    }

    func reloadPlanState() {
        let completedCount = store.completedKhatmahCount
        completedCountText = completedCount > 0
            ? String(format: AppLocalizedKeys.khatmahCompletedCountFormat.value,
                     KhatmahLocalizedFormatting.khatmahCount(completedCount))
            : ""

        guard let schedule = store.activeSchedule else {
            applyEmptyState()
            return
        }

        let now = Date()
        let plan = schedule.plan
        let today = schedule.today(on: now)

        hasPlan = true
        hasStarted = schedule.hasStarted(on: now)
        todayDayNumber = today.dayNumber
        isTodayCompleted = plan.isDayCompleted(today.dayNumber)
        isPlanCompleted = plan.isCompleted
        progressFraction = schedule.completionFraction
        percentText = KhatmahLocalizedFormatting.percent(schedule.completionFraction)
        todayPageCount = KhatmahLocalizedFormatting.pageCount(today.pageCount)
        todayWorkloadText = KhatmahWorkload.forPagesPerDay(today.pageCount).localizedLabel
        dayOfTotalText = String(format: AppLocalizedKeys.khatmahDayOfTotalFormat.value,
                                KhatmahLocalizedFormatting.number(today.dayNumber),
                                KhatmahLocalizedFormatting.number(plan.totalDays))
        daysRemainingText = daysRemainingLabel(schedule: schedule, on: now)
        remainingPagesText = String(format: AppLocalizedKeys.khatmahRemainingPagesFormat.value,
                                    KhatmahLocalizedFormatting.pageCount(schedule.remainingPages))
        expectedCompletionText = schedule.expectedCompletionDate.map(dateLabel) ?? ""
        startsOnText = schedule.startDate.map {
            String(format: AppLocalizedKeys.khatmahStartsOnFormat.value, dateLabel($0))
        } ?? ""
        allDaysText = String(format: AppLocalizedKeys.khatmahAllDaysFormat.value,
                             KhatmahLocalizedFormatting.number(plan.totalDays))
        applyDrift(schedule.drift(on: now))
        applyMetrics(schedule: schedule, on: now)
        isReminderEnabled = plan.reminder.isEnabled
        reminderTime = reminderDate(for: plan.reminder)
        resolveTodayPortion(firstPage: today.firstPage, lastPage: today.lastPage)
    }

    func applyEmptyState() {
        hasPlan = false
        todayPageCount = ""
        todayWorkloadText = ""
        todayPortionText = ""
        todayPageRangeText = ""
        isTodayCompleted = false
        isPlanCompleted = false
        hasStarted = true
        startsOnText = ""
        dayOfTotalText = ""
        daysRemainingText = ""
        percentText = ""
        progressFraction = 0
        remainingPagesText = ""
        expectedCompletionText = ""
        driftText = ""
        driftAccent = .primary
        isBehindSchedule = false
        metrics = []
        metricsAccessibilityLabel = ""
        allDaysText = ""
        isReminderEnabled = false
    }

    func applyDrift(_ drift: KhatmahDrift) {
        switch drift {
        case .onSchedule:
            driftText = AppLocalizedKeys.khatmahOnScheduleStatus.value
            driftAccent = .primary
            isBehindSchedule = false
        case .ahead(let pages):
            driftText = String(format: AppLocalizedKeys.khatmahPagesAheadFormat.value,
                               KhatmahLocalizedFormatting.pageCount(pages))
            driftAccent = .primary
            isBehindSchedule = false
        case .behind(let pages):
            driftText = String(format: AppLocalizedKeys.khatmahPagesBehindFormat.value,
                               KhatmahLocalizedFormatting.pageCount(pages))
            driftAccent = .warning
            isBehindSchedule = true
        }
    }

    func applyMetrics(schedule: KhatmahPlanSchedule, on date: Date) {
        var items: [KhatmahMetric] = [
            KhatmahMetric(id: 0,
                          value: KhatmahLocalizedFormatting.number(remainingDays(schedule: schedule, on: date)),
                          title: daysLeftTitle),
            KhatmahMetric(id: 1,
                          value: KhatmahLocalizedFormatting.number(schedule.remainingPages),
                          title: pagesLeftTitle)
        ]

        if let completionDate = schedule.expectedCompletionDate {
            items.append(KhatmahMetric(id: 2,
                                       value: shortDateLabel(completionDate),
                                       title: expectedCompletionTitle))
        }

        metrics = items
        metricsAccessibilityLabel = [daysRemainingText,
                                     remainingPagesText,
                                     expectedCompletionText.isEmpty
                                        ? ""
                                        : "\(expectedCompletionTitle) \(expectedCompletionText)"]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }

    func resolveTodayPortion(firstPage: Int, lastPage: Int) {
        verseRangeTask?.cancel()
        let isArabic = KhatmahLocalizedFormatting.isArabic
        let pageRange = pageRangeLabel(firstPage: firstPage, lastPage: lastPage)
        let pageCount = todayPageCount

        todayPortionText = pageRange
        todayPageRangeText = pageCount

        verseRangeTask = Task.detached(priority: .userInitiated) { [weak self] in
            let range = await KhatmahVerseRangeIndex.shared.range(fromPage: firstPage,
                                                                  toPage: lastPage,
                                                                  isArabic: isArabic)
            guard !Task.isCancelled, let self, let range else { return }
            await self.applyTodayPortion(range, pageRange: pageRange, pageCount: pageCount)
        }
    }

    func applyTodayPortion(_ range: KhatmahVerseRange, pageRange: String, pageCount: String) {
        todayPortionText = String(format: AppLocalizedKeys.khatmahVerseRangeFormat.value,
                                  versePointLabel(range.start),
                                  versePointLabel(range.end))
        todayPageRangeText = "\(pageRange) \u{00B7} \(pageCount)"
    }

    func pageRangeLabel(firstPage: Int, lastPage: Int) -> String {
        String(format: AppLocalizedKeys.khatmahPageRangeFormat.value,
               KhatmahLocalizedFormatting.number(firstPage),
               KhatmahLocalizedFormatting.number(lastPage))
    }

    func versePointLabel(_ point: KhatmahVersePoint) -> String {
        String(format: AppLocalizedKeys.khatmahVersePointFormat.value,
               point.surahName,
               KhatmahLocalizedFormatting.number(point.verseNumber))
    }

    func remainingDays(schedule: KhatmahPlanSchedule, on date: Date) -> Int {
        let elapsed = max(schedule.elapsedDayNumber(on: date), 1)
        return max(schedule.plan.totalDays - elapsed + 1, 0)
    }

    func daysRemainingLabel(schedule: KhatmahPlanSchedule, on date: Date) -> String {
        let remaining = remainingDays(schedule: schedule, on: date)
        guard remaining > 1 else { return AppLocalizedKeys.khatmahLastDayLabel.value }
        return String(format: AppLocalizedKeys.khatmahDaysRemainingFormat.value,
                      KhatmahLocalizedFormatting.dayCount(remaining))
    }

    func dateLabel(_ date: Date) -> String {
        formattedDate(date, format: "d MMMM yyyy")
    }

    func shortDateLabel(_ date: Date) -> String {
        formattedDate(date, format: "d MMM")
    }

    func formattedDate(_ date: Date, format: String) -> String {
        let locale = KhatmahLocalizedFormatting.locale
        var calendar = store.dayCalendar
        calendar.locale = locale

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    func reminderDate(for reminder: KhatmahReminder) -> Date {
        let calendar = store.dayCalendar
        let today = calendar.startOfDay(for: Date())
        return calendar.date(bySettingHour: reminder.clampedHour,
                             minute: reminder.clampedMinute,
                             second: 0,
                             of: today) ?? today
    }
}
