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

struct KhatmahDayItem: Identifiable {
    let id: Int
    let dayNumber: Int
    let title: String
    let pageRange: String
    let statusTitle: String
    let statusAccent: ColorStyle
    let isCompleted: Bool
}

@MainActor
final class KhatmahPlanViewModel: MainViewModel {

    @Published private(set) var hasPlan: Bool = false
    @Published private(set) var dayItems: [KhatmahDayItem] = []
    @Published private(set) var todayDayNumber: Int = 1
    @Published private(set) var todayPageRange: String = ""
    @Published private(set) var todayPageCount: String = ""
    @Published private(set) var todaySurahNames: String = ""
    @Published private(set) var isTodayCompleted: Bool = false
    @Published private(set) var hasStarted: Bool = true
    @Published private(set) var startsOnText: String = ""
    @Published private(set) var dayOfTotalText: String = ""
    @Published private(set) var percentText: String = ""
    @Published private(set) var progressFraction: Double = 0
    @Published private(set) var remainingPagesText: String = ""
    @Published private(set) var expectedCompletionText: String = ""
    @Published private(set) var driftText: String = ""
    @Published private(set) var driftAccent: ColorStyle = .success
    @Published private(set) var completedCountText: String = ""
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
    private var surahNameTask: Task<Void, Never>?

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
        surahNameTask?.cancel()
        surahNameTask = nil
    }
}

// MARK: - Labels

extension KhatmahPlanViewModel {

    var screenTitle: String { AppLocalizedKeys.khatmahTitle.value }
    var todayTitle: String { AppLocalizedKeys.khatmahTodayTitle.value }
    var todayDoneTitle: String { AppLocalizedKeys.khatmahTodayDoneTitle.value }
    var readActionTitle: String { AppLocalizedKeys.khatmahReadAction.value }
    var markCompleteActionTitle: String { AppLocalizedKeys.khatmahMarkCompleteAction.value }
    var progressTitle: String { AppLocalizedKeys.khatmahProgressTitle.value }
    var expectedCompletionTitle: String { AppLocalizedKeys.khatmahExpectedCompletionTitle.value }
    var daysSectionTitle: String { AppLocalizedKeys.khatmahDaysSectionTitle.value }
    var reminderSectionTitle: String { AppLocalizedKeys.khatmahReminderSection.value }
    var reminderToggleTitle: String { AppLocalizedKeys.khatmahReminderToggle.value }
    var reminderTimeTitle: String { AppLocalizedKeys.khatmahReminderTimeTitle.value }
    var deleteActionTitle: String { AppLocalizedKeys.khatmahDeleteAction.value }
    var deleteConfirmationTitle: String { AppLocalizedKeys.khatmahDeleteTitle.value }
    var deleteConfirmationMessage: String { AppLocalizedKeys.khatmahDeleteMessage.value }
    var cancelActionTitle: String { AppLocalizedKeys.cancel.value }
    var emptyTitle: String { AppLocalizedKeys.khatmahEmptyTitle.value }
    var emptyMessage: String { AppLocalizedKeys.khatmahEmptyMessage.value }
    var newPlanActionTitle: String { AppLocalizedKeys.khatmahNewPlanAction.value }
    var completedTitle: String { AppLocalizedKeys.khatmahCompletedTitle.value }
    var completedMessage: String { AppLocalizedKeys.khatmahCompletedMessage.value }
    var authorizationDeniedTitle: String { AppLocalizedKeys.prayerNotificationsAuthorizationDeniedTitle.value }
    var authorizationDeniedBody: String { AppLocalizedKeys.khatmahNotificationsDeniedBody.value }
    var openSystemSettingsTitle: String { AppLocalizedKeys.prayerNotificationsOpenSystemSettings.value }
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

    func onDayTapped(_ item: KhatmahDayItem) {
        store.toggleDayCompletion(item.dayNumber)
        reloadPlanState()
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
        completedCountText = String(
            format: AppLocalizedKeys.khatmahCompletedCountFormat.value,
            localizedNumber(store.completedKhatmahCount)
        )

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
        percentText = percentLabel(schedule.completionFraction)
        todayPageRange = pageRangeLabel(firstPage: today.firstPage, lastPage: today.lastPage)
        todayPageCount = String(format: AppLocalizedKeys.khatmahPagesCountFormat.value,
                                localizedNumber(today.pageCount))
        dayOfTotalText = String(format: AppLocalizedKeys.khatmahDayOfTotalFormat.value,
                                localizedNumber(today.dayNumber),
                                localizedNumber(plan.totalDays))
        remainingPagesText = String(format: AppLocalizedKeys.khatmahRemainingPagesFormat.value,
                                    localizedNumber(schedule.remainingPages))
        expectedCompletionText = schedule.expectedCompletionDate.map(dateLabel) ?? ""
        startsOnText = schedule.startDate.map {
            String(format: AppLocalizedKeys.khatmahStartsOnFormat.value, dateLabel($0))
        } ?? ""
        applyDrift(schedule.drift(on: now))
        isReminderEnabled = plan.reminder.isEnabled
        reminderTime = reminderDate(for: plan.reminder)
        dayItems = schedule.days(on: now).map(dayItem)
        resolveTodaySurahNames(firstPage: today.firstPage, lastPage: today.lastPage)
    }

    func applyEmptyState() {
        hasPlan = false
        dayItems = []
        todayPageRange = ""
        todayPageCount = ""
        todaySurahNames = ""
        isTodayCompleted = false
        isPlanCompleted = false
        hasStarted = true
        startsOnText = ""
        dayOfTotalText = ""
        percentText = ""
        progressFraction = 0
        remainingPagesText = ""
        expectedCompletionText = ""
        driftText = ""
        isReminderEnabled = false
    }

    func applyDrift(_ drift: KhatmahDrift) {
        switch drift {
        case .onSchedule:
            driftText = AppLocalizedKeys.khatmahOnScheduleStatus.value
            driftAccent = .success
        case .ahead(let pages):
            driftText = String(format: AppLocalizedKeys.khatmahPagesAheadFormat.value,
                               localizedNumber(pages))
            driftAccent = .primary
        case .behind(let pages):
            driftText = String(format: AppLocalizedKeys.khatmahPagesBehindFormat.value,
                               localizedNumber(pages))
            driftAccent = .warning
        }
    }

    func dayItem(_ day: KhatmahDay) -> KhatmahDayItem {
        KhatmahDayItem(
            id: day.dayNumber,
            dayNumber: day.dayNumber,
            title: String(format: AppLocalizedKeys.khatmahDayLabelFormat.value,
                          localizedNumber(day.dayNumber)),
            pageRange: pageRangeLabel(firstPage: day.firstPage, lastPage: day.lastPage),
            statusTitle: statusTitle(day.status),
            statusAccent: statusAccent(day.status),
            isCompleted: day.status == .completed
        )
    }

    func statusTitle(_ status: KhatmahDayStatus) -> String {
        switch status {
        case .completed: return AppLocalizedKeys.khatmahDayStatusCompleted.value
        case .today: return AppLocalizedKeys.khatmahDayStatusToday.value
        case .missed: return AppLocalizedKeys.khatmahDayStatusMissed.value
        case .upcoming: return AppLocalizedKeys.khatmahDayStatusUpcoming.value
        }
    }

    func statusAccent(_ status: KhatmahDayStatus) -> ColorStyle {
        switch status {
        case .completed: return .success
        case .today: return .primary
        case .missed: return .warning
        case .upcoming: return .onSurfaceVariant
        }
    }

    func resolveTodaySurahNames(firstPage: Int, lastPage: Int) {
        surahNameTask?.cancel()
        let isArabic = LocalizationManager.shared.currentLanguage == .Arabic

        surahNameTask = Task.detached(priority: .userInitiated) { [weak self] in
            let database = QuranDatabase.shared
            var names: [String] = []

            for page in [firstPage, lastPage] {
                for surah in database.getSurahsForPage(page) {
                    let name = isArabic ? surah.arabicTitle : surah.englishTitle
                    guard !name.isEmpty, !names.contains(name) else { continue }
                    names.append(name)
                }
            }

            guard !Task.isCancelled, let self else { return }
            await self.applyTodaySurahNames(names.joined(separator: " · "))
        }
    }

    func applyTodaySurahNames(_ names: String) {
        todaySurahNames = names
    }

    func pageRangeLabel(firstPage: Int, lastPage: Int) -> String {
        String(format: AppLocalizedKeys.khatmahPageRangeFormat.value,
               localizedNumber(firstPage),
               localizedNumber(lastPage))
    }

    func percentLabel(_ fraction: Double) -> String {
        let percent = Int((fraction * 100).rounded())
        return LocalizationManager.shared.currentLanguage == .Arabic
            ? "\(percent.arabicNumerals)٪"
            : "\(percent)%"
    }

    func dateLabel(_ date: Date) -> String {
        let isArabic = LocalizationManager.shared.currentLanguage == .Arabic
        let locale = Locale(identifier: isArabic ? "ar" : "en")
        var calendar = store.dayCalendar
        calendar.locale = locale

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "d MMMM yyyy"
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

    func localizedNumber(_ value: Int) -> String {
        LocalizationManager.shared.currentLanguage == .Arabic ? value.arabicNumerals : "\(value)"
    }
}
