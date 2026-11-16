//
//  KhatmahScheduleViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import Foundation
import Combine
import Core

@MainActor
final class KhatmahScheduleViewModel: MainViewModel {

    @Published private(set) var dayItems: [KhatmahDayItem] = []
    @Published private(set) var percentText: String = ""
    @Published private(set) var progressFraction: Double = 0
    @Published private(set) var completedDaysText: String = ""

    private let store: KhatmahPlanStore
    private weak var coordinator: KhatmahCoordinating?
    private var cancellables = Set<AnyCancellable>()
    private var verseRangeTask: Task<Void, Never>?
    private var verseRangesByDay: [Int: KhatmahVerseRange] = [:]
    private var verseRangeSignature: String?

    var isTabBarVisible: Bool { false }

    init(coordinator: KhatmahCoordinating, store: KhatmahPlanStore? = nil) {
        self.coordinator = coordinator
        self.store = store ?? KhatmahPlanStore.shared
        observeStore()
        reloadDays()
    }

    func onAppear() {
        reloadDays()
    }

    func onDisappear() {
        verseRangeTask?.cancel()
        verseRangeTask = nil
    }
}

// MARK: - Labels

extension KhatmahScheduleViewModel {

    var screenTitle: String { AppLocalizedKeys.khatmahScheduleTitle.value }
    var backActionTitle: String { AppLocalizedKeys.khatmahBackAction.value }
}

// MARK: - Actions

extension KhatmahScheduleViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func onDayTapped(_ item: KhatmahDayItem) {
        store.toggleDayCompletion(item.dayNumber)
        reloadDays()
    }
}

// MARK: - State

private extension KhatmahScheduleViewModel {

    func observeStore() {
        store.$activePlan
            .removeDuplicates()
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadDays()
            }
            .store(in: &cancellables)
    }

    func reloadDays() {
        guard let schedule = store.activeSchedule else {
            dayItems = []
            percentText = ""
            progressFraction = 0
            completedDaysText = ""
            return
        }

        let now = Date()
        let plan = schedule.plan
        let days = schedule.days(on: now)

        progressFraction = schedule.completionFraction
        percentText = KhatmahLocalizedFormatting.percent(schedule.completionFraction)
        completedDaysText = String(format: AppLocalizedKeys.khatmahScheduleCompletedFormat.value,
                                   KhatmahLocalizedFormatting.number(plan.completedDayCount),
                                   KhatmahLocalizedFormatting.dayCount(plan.totalDays))
        dayItems = days.map(dayItem)
        resolveVerseRanges(for: days, signature: "\(plan.startPage)-\(plan.endPage)-\(plan.totalDays)")
    }

    func resolveVerseRanges(for days: [KhatmahDay], signature: String) {
        guard verseRangeSignature != signature else { return }
        verseRangeSignature = signature
        verseRangesByDay = [:]
        verseRangeTask?.cancel()

        let isArabic = KhatmahLocalizedFormatting.isArabic
        var spans: [Int: ClosedRange<Int>] = [:]
        for day in days {
            spans[day.dayNumber] = day.firstPage...day.lastPage
        }

        verseRangeTask = Task.detached(priority: .userInitiated) { [weak self] in
            let ranges = await KhatmahVerseRangeIndex.shared.ranges(forPageSpans: spans, isArabic: isArabic)
            guard !Task.isCancelled, let self, !ranges.isEmpty else { return }
            await self.applyVerseRanges(ranges)
        }
    }

    func applyVerseRanges(_ ranges: [Int: KhatmahVerseRange]) {
        verseRangesByDay = ranges
        reloadDays()
    }

    func dayItem(_ day: KhatmahDay) -> KhatmahDayItem {
        KhatmahDayItem(
            id: day.dayNumber,
            dayNumber: day.dayNumber,
            title: String(format: AppLocalizedKeys.khatmahDayLabelFormat.value,
                          KhatmahLocalizedFormatting.number(day.dayNumber)),
            pageRange: pageRangeLabel(firstPage: day.firstPage, lastPage: day.lastPage),
            verseRange: verseRangeLabel(ofDay: day.dayNumber),
            statusTitle: statusTitle(day.status),
            statusAccent: statusAccent(day.status),
            isCompleted: day.status == .completed,
            isToday: day.status == .today,
            isMissed: day.status == .missed
        )
    }

    func verseRangeLabel(ofDay dayNumber: Int) -> String {
        guard let range = verseRangesByDay[dayNumber] else { return "" }
        return String(format: AppLocalizedKeys.khatmahVerseRangeFormat.value,
                      versePointLabel(range.start),
                      versePointLabel(range.end))
    }

    func versePointLabel(_ point: KhatmahVersePoint) -> String {
        String(format: AppLocalizedKeys.khatmahVersePointFormat.value,
               point.surahName,
               KhatmahLocalizedFormatting.number(point.verseNumber))
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
        case .completed: return .primary
        case .today: return .primary
        case .missed: return .warning
        case .upcoming: return .outline
        }
    }

    func pageRangeLabel(firstPage: Int, lastPage: Int) -> String {
        String(format: AppLocalizedKeys.khatmahPageRangeFormat.value,
               KhatmahLocalizedFormatting.number(firstPage),
               KhatmahLocalizedFormatting.number(lastPage))
    }
}
