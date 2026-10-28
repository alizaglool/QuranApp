//
//  WorshipTrackerViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import Foundation
import Core

struct WorshipActItem: Identifiable {
    let id: String
    let act: WorshipAct
    let title: String
    let icon: String
    let isDone: Bool
    let isLocked: Bool
}

struct WorshipCategorySection: Identifiable {
    let id: String
    let category: WorshipCategory
    let title: String
    let accent: ColorStyle
    let items: [WorshipActItem]
    let currentStreak: Int
    let bestStreak: Int
}

struct WorshipDayCell: Identifiable {
    let id: String
    let level: Int
    let isToday: Bool
}

@MainActor
final class WorshipTrackerViewModel: MainViewModel {

    @Published private(set) var sections: [WorshipCategorySection] = []
    @Published private(set) var completedText: String = ""
    @Published private(set) var fraction: Double = 0
    @Published private(set) var percentText: String = ""
    @Published private(set) var currentStreakText: String = ""
    @Published private(set) var bestStreakText: String = ""
    @Published private(set) var weekCells: [WorshipDayCell] = []
    @Published private(set) var yearCells: [WorshipDayCell] = []
    @Published private(set) var isShowingYesterday: Bool = false

    private let store = WorshipTrackerStore.shared
    private let prayerStore = PrayerTimesStore.shared
    private weak var coordinator: WorshipCoordinating?

    var isTabBarVisible: Bool { false }

    init(coordinator: WorshipCoordinating) {
        self.coordinator = coordinator
        reloadTrackerState()
    }

    func onAppear() {
        store.invalidateCompletionCache()
        reloadTrackerState()
    }
}

// MARK: - Titles

extension WorshipTrackerViewModel {

    var screenTitle: String { AppLocalizedKeys.worshipTracker.value }
    var todayTitle: String { AppLocalizedKeys.homeTodayTitle.value }
    var yesterdayTitle: String { AppLocalizedKeys.worshipYesterday.value }
    var currentStreakTitle: String { AppLocalizedKeys.worshipCurrentStreak.value }
    var bestStreakTitle: String { AppLocalizedKeys.worshipBestStreak.value }
    var streaksTitle: String { AppLocalizedKeys.worshipStreaksByCategory.value }
    var weekTitle: String { AppLocalizedKeys.worshipLastSevenDays.value }
    var yearTitle: String { AppLocalizedKeys.worshipYearOverview.value }
    var hintText: String { AppLocalizedKeys.worshipTapHint.value }
    var lockedText: String { AppLocalizedKeys.worshipNotOpenYet.value }
    var disclaimerTitle: String { AppLocalizedKeys.worshipDisclaimerTitle.value }
    var disclaimerBody: String { AppLocalizedKeys.worshipDisclaimerBody.value }
    var editYesterdayTitle: String { AppLocalizedKeys.worshipUpdateYesterday.value }
    var backToTodayTitle: String { AppLocalizedKeys.worshipBackToToday.value }

    var dayStreakUnit: String { AppLocalizedKeys.worshipDaysUnit.value }
}

// MARK: - Actions

extension WorshipTrackerViewModel {

    func toggleCompletion(for item: WorshipActItem) {
        guard !item.isLocked else { return }
        store.toggleCompletion(for: item.act, on: activeDayKey)
        reloadTrackerState()
    }

    func toggleYesterdayEditing() {
        isShowingYesterday.toggle()
        reloadTrackerState()
    }

    func onBackTapped() {
        coordinator?.coordinateBack()
    }
}

// MARK: - Loading

private extension WorshipTrackerViewModel {

    var activeDate: Date {
        isShowingYesterday ? store.date(byAddingDays: -1, to: Date()) : Date()
    }

    var activeDayKey: String {
        store.dayKey(for: activeDate)
    }

    func reloadTrackerState() {
        let now = Date()
        let key = activeDayKey
        let visibility = DhikrVisibilityService(prayerTimes: prayerStore.today)

        sections = WorshipCategory.allCases.map { category in
            WorshipCategorySection(
                id: category.rawValue,
                category: category,
                title: category.titleKey.value,
                accent: category.accent,
                items: category.acts.map { act in
                    WorshipActItem(
                        id: act.rawValue,
                        act: act,
                        title: act.titleKey.value,
                        icon: act.iconName,
                        isDone: store.isActCompleted(act, on: key),
                        isLocked: isActLocked(act, visibility: visibility, at: now)
                    )
                },
                currentStreak: store.currentStreak(for: category, endingAt: now),
                bestStreak: store.bestStreak(for: category, endingAt: now)
            )
        }

        let completed = store.completedActCount(on: key)
        let total = WorshipAct.allCases.count
        completedText = String(format: AppLocalizedKeys.prayersCompletedFormat.value, completed, total)
        fraction = store.completionFraction(on: key)
        percentText = "\(Int((fraction * 100).rounded()))%"

        currentStreakText = "\(store.currentOverallStreak(endingAt: now))"
        bestStreakText = "\(store.bestOverallStreak(endingAt: now))"

        weekCells = dayCells(dayCount: 7, endingAt: now)
        yearCells = dayCells(dayCount: 364, endingAt: now)
    }

    func isActLocked(_ act: WorshipAct, visibility: DhikrVisibilityService, at date: Date) -> Bool {
        guard !isShowingYesterday else { return false }
        guard let condition = act.openingCondition else { return false }
        return !visibility.isOpen(condition, on: date)
    }

    func dayCells(dayCount: Int, endingAt date: Date) -> [WorshipDayCell] {
        let todayKey = store.dayKey(for: date)
        return store.recentCompletionFractions(dayCount: dayCount, endingAt: date).map { entry in
            WorshipDayCell(id: entry.dayKey,
                           level: intensityLevel(for: entry.fraction),
                           isToday: entry.dayKey == todayKey)
        }
    }

    func intensityLevel(for fraction: Double) -> Int {
        switch fraction {
        case ..<0.001: return 0
        case ..<0.25: return 1
        case ..<0.5: return 2
        case ..<1.0: return 3
        default: return 4
        }
    }
}
