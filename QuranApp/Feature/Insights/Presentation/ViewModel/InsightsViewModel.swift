//
//  InsightsViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import Foundation
import Core

struct InsightsMetricItem: Identifiable {
    let id: String
    let title: String
    let value: String
    let caption: String
    let icon: String
    let accent: ColorStyle
}

struct InsightsBarItem: Identifiable, Equatable {
    let id: String
    let fraction: Double
    let isLastDay: Bool
}

struct InsightsConsistencyItem: Identifiable {
    let id: Int
    let title: String
    let value: String
    let fraction: Double
    let accent: ColorStyle
}

@MainActor
final class InsightsViewModel: MainViewModel {

    @Published private(set) var range: InsightsRange = .week
    @Published private(set) var summary: InsightsSummary = .empty
    @Published private(set) var bookmarkCount: Int = 0

    var isTabBarVisible: Bool { false }

    weak var coordinator: InsightsCoordinating?

    private let summaryBuilder: InsightsSummaryBuilder
    private let localizationManager: LocalizationManager
    private let bookmarkCountProvider: @MainActor () -> Int
    private let currentDate: () -> Date

    init(coordinator: InsightsCoordinating) {
        self.coordinator = coordinator
        self.summaryBuilder = InsightsSummaryBuilder()
        self.localizationManager = .shared
        self.bookmarkCountProvider = { StorageManager.shared.getAllBookmarks().count }
        self.currentDate = { Date() }
    }

    init(coordinator: InsightsCoordinating,
         summaryBuilder: InsightsSummaryBuilder,
         localizationManager: LocalizationManager,
         bookmarkCountProvider: @escaping @MainActor () -> Int,
         currentDate: @escaping () -> Date) {
        self.coordinator = coordinator
        self.summaryBuilder = summaryBuilder
        self.localizationManager = localizationManager
        self.bookmarkCountProvider = bookmarkCountProvider
        self.currentDate = currentDate
    }

    func onAppear() {
        reloadSummary()
    }

    func selectRange(_ range: InsightsRange) {
        guard range != self.range else { return }
        self.range = range
        reloadSummary()
    }

    func coordinateBack() {
        coordinator?.coordinateBack()
    }

    private func reloadSummary() {
        summary = summaryBuilder.summary(range: range, endingAt: currentDate())
        bookmarkCount = bookmarkCountProvider()
    }
}

// MARK: - Overview

extension InsightsViewModel {

    var overviewMetrics: [InsightsMetricItem] {
        [
            InsightsMetricItem(id: "activeDays",
                               title: AppLocalizedKeys.insightsActiveDaysTitle.value,
                               value: number(summary.activeWorshipDayCount),
                               caption: outOfDaysText,
                               icon: "flame.fill",
                               accent: .primary),
            InsightsMetricItem(id: "pagesRead",
                               title: AppLocalizedKeys.insightsPagesReadTitle.value,
                               value: number(summary.readPageCount),
                               caption: readingDaysText,
                               icon: "book.fill",
                               accent: .secondary),
            InsightsMetricItem(id: "prayersLogged",
                               title: AppLocalizedKeys.insightsPrayersLoggedTitle.value,
                               value: number(summary.prayedPrayerCount),
                               caption: percent(summary.prayerCompletionFraction),
                               icon: "checkmark.seal.fill",
                               accent: .success)
        ]
    }

    private var outOfDaysText: String {
        String(format: AppLocalizedKeys.insightsOutOfDaysFormat.value,
               KhatmahLocalizedFormatting.dayCount(range.dayCount))
    }

    private var readingDaysText: String {
        String(format: AppLocalizedKeys.insightsOnDaysFormat.value,
               KhatmahLocalizedFormatting.dayCount(summary.readingDayCount))
    }
}

// MARK: - Trends

extension InsightsViewModel {

    var readingBars: [InsightsBarItem] {
        let peak = max(summary.peakReadPageCount, 1)
        return summary.dayPoints.enumerated().map { index, point in
            InsightsBarItem(id: point.dayKey,
                            fraction: Double(point.readPageCount) / Double(peak),
                            isLastDay: index == summary.dayPoints.count - 1)
        }
    }

    var worshipBars: [InsightsBarItem] {
        summary.dayPoints.enumerated().map { index, point in
            InsightsBarItem(id: point.dayKey,
                            fraction: point.worshipFraction,
                            isLastDay: index == summary.dayPoints.count - 1)
        }
    }

    var readingAverageText: String {
        String(format: AppLocalizedKeys.insightsDailyAverageFormat.value,
               decimal(summary.averageReadPageCount))
    }

    var worshipAverageText: String {
        percent(summary.worshipCompletionFraction)
    }
}

// MARK: - Prayer Consistency

extension InsightsViewModel {

    var consistencyItems: [InsightsConsistencyItem] {
        let strongest = summary.strongestPrayer
        let weakest = summary.weakestPrayer

        return summary.prayerConsistency.map { entry in
            InsightsConsistencyItem(id: entry.prayerIndex,
                                    title: prayerTitle(entry.prayerIndex),
                                    value: percent(entry.fraction),
                                    fraction: entry.fraction,
                                    accent: consistencyAccent(entry,
                                                              strongest: strongest,
                                                              weakest: weakest))
        }
    }

    var strongestPrayerText: String {
        guard let strongest = summary.strongestPrayer else { return "" }
        return prayerTitle(strongest.prayerIndex)
    }

    var weakestPrayerText: String {
        guard let weakest = summary.weakestPrayer,
              weakest.prayerIndex != summary.strongestPrayer?.prayerIndex else { return "" }
        return prayerTitle(weakest.prayerIndex)
    }

    var isConsistencyVisible: Bool { summary.trackedPrayerDayCount > 0 }

    var trackedDaysNote: String {
        String(format: AppLocalizedKeys.insightsTrackedDaysFormat.value,
               KhatmahLocalizedFormatting.dayCount(summary.trackedPrayerDayCount))
    }

    private func consistencyAccent(_ entry: InsightsPrayerConsistency,
                                   strongest: InsightsPrayerConsistency?,
                                   weakest: InsightsPrayerConsistency?) -> ColorStyle {
        if entry.prayerIndex == weakest?.prayerIndex,
           weakest?.prayerIndex != strongest?.prayerIndex {
            return .warning
        }
        if entry.prayerIndex == strongest?.prayerIndex { return .success }
        return .primary
    }

    private func prayerTitle(_ index: Int) -> String {
        WorshipAct.act(forPrayerIndex: index)?.titleKey.value ?? ""
    }
}

// MARK: - Khatmah

extension InsightsViewModel {

    var isKhatmahPlanActive: Bool { summary.khatmah != nil }

    var khatmahFraction: Double { summary.khatmah?.fraction ?? 0 }

    var khatmahPagesText: String {
        guard let khatmah = summary.khatmah else { return "" }
        return String(format: AppLocalizedKeys.insightsPagesOfTotalFormat.value,
                      number(khatmah.readPageCount),
                      KhatmahLocalizedFormatting.pageCount(khatmah.totalPageCount))
    }

    var khatmahDaysText: String {
        guard let khatmah = summary.khatmah else { return "" }
        return String(format: AppLocalizedKeys.insightsDaysOfTotalFormat.value,
                      number(khatmah.completedDayCount),
                      KhatmahLocalizedFormatting.dayCount(khatmah.totalDayCount))
    }

    var khatmahDriftText: String {
        guard let khatmah = summary.khatmah else { return "" }
        switch khatmah.drift {
        case .onSchedule:
            return AppLocalizedKeys.khatmahOnScheduleStatus.value
        case .ahead(let pages):
            return String(format: AppLocalizedKeys.khatmahPagesAheadFormat.value,
                          KhatmahLocalizedFormatting.pageCount(pages))
        case .behind(let pages):
            return String(format: AppLocalizedKeys.khatmahPagesBehindFormat.value,
                          KhatmahLocalizedFormatting.pageCount(pages))
        }
    }

    var khatmahDriftAccent: ColorStyle {
        guard let khatmah = summary.khatmah else { return .primary }
        if case .behind = khatmah.drift { return .warning }
        return .primary
    }

    var khatmahPercentText: String { percent(khatmahFraction) }
}

// MARK: - Library

extension InsightsViewModel {

    var libraryMetrics: [InsightsMetricItem] {
        [
            InsightsMetricItem(id: "bookmarks",
                               title: AppLocalizedKeys.insightsBookmarksTitle.value,
                               value: number(bookmarkCount),
                               caption: "",
                               icon: "bookmark.fill",
                               accent: .secondary),
            InsightsMetricItem(id: "completedKhatmah",
                               title: AppLocalizedKeys.insightsCompletedKhatmahTitle.value,
                               value: number(summary.completedKhatmahCount),
                               caption: "",
                               icon: "checkmark.circle.fill",
                               accent: .primary)
        ]
    }
}

// MARK: - Labels

extension InsightsViewModel {

    var navigationTitle: String { AppLocalizedKeys.insightsTitle.value }

    var overviewTitle: String { AppLocalizedKeys.insightsOverviewTitle.value }

    var readingTrendTitle: String { AppLocalizedKeys.insightsReadingTrendTitle.value }

    var worshipTrendTitle: String { AppLocalizedKeys.insightsWorshipTrendTitle.value }

    var consistencyTitle: String { AppLocalizedKeys.insightsPrayerConsistencyTitle.value }

    var strongestPrayerTitle: String { AppLocalizedKeys.insightsStrongestPrayerTitle.value }

    var weakestPrayerTitle: String { AppLocalizedKeys.insightsWeakestPrayerTitle.value }

    var khatmahTitle: String { AppLocalizedKeys.insightsKhatmahTitle.value }

    var khatmahNoPlanMessage: String { AppLocalizedKeys.insightsKhatmahNoPlanMessage.value }

    var libraryTitle: String { AppLocalizedKeys.insightsLibraryTitle.value }

    var emptyStateMessage: String { AppLocalizedKeys.insightsEmptyMessage.value }

    var isEmptyStateVisible: Bool { !summary.hasAnyActivity }

    var ranges: [InsightsRange] { InsightsRange.allCases }

    func rangeTitle(_ range: InsightsRange) -> String {
        switch range {
        case .week:    return AppLocalizedKeys.insightsRangeWeek.value
        case .month:   return AppLocalizedKeys.insightsRangeMonth.value
        case .quarter: return AppLocalizedKeys.insightsRangeQuarter.value
        }
    }

    func barAccessibilityLabel(_ item: InsightsBarItem) -> String {
        "\(item.id) \(percent(item.fraction))"
    }
}

// MARK: - Formatting

private extension InsightsViewModel {

    var isArabic: Bool { localizationManager.currentLanguage == .Arabic }

    func number(_ value: Int) -> String {
        isArabic ? value.arabicNumerals : String(value)
    }

    func percent(_ fraction: Double) -> String {
        KhatmahLocalizedFormatting.percent(fraction)
    }

    func decimal(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = KhatmahLocalizedFormatting.locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? number(Int(value))
    }
}
