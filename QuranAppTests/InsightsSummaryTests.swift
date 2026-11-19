//
//  InsightsSummaryTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import XCTest
import Core
@testable import QuranApp

private final class InsightsCoordinatorSpy: InsightsCoordinating {

    private(set) var backCount = 0

    func coordinateBack() {
        backCount += 1
    }
}

private final class InsightsDateProbe {

    private(set) var readCount = 0

    private let fixedDate: Date

    init(fixedDate: Date) {
        self.fixedDate = fixedDate
    }

    func nextDate() -> Date {
        readCount += 1
        return fixedDate
    }
}

@MainActor
final class InsightsSummaryTests: XCTestCase {

    private var suiteNames: [String] = []
    private var prayerCompletion: PrayerCompletionStore = PrayerCompletionStore(defaults: .standard)
    private var worshipTracker: WorshipTrackerStore = WorshipTrackerStore(defaults: .standard)
    private var readingLog: QuranReadingLogStore = QuranReadingLogStore(defaults: .standard)
    private var khatmahStore: KhatmahPlanStore = KhatmahPlanStore(defaults: .standard)
    private var builder: InsightsSummaryBuilder = InsightsSummaryBuilder()

    override func setUp() {
        super.setUp()
        suiteNames = []
        prayerCompletion = PrayerCompletionStore(defaults: freshDefaults())
        worshipTracker = WorshipTrackerStore(defaults: freshDefaults(),
                                             prayerCompletion: prayerCompletion)
        readingLog = QuranReadingLogStore(defaults: freshDefaults())
        khatmahStore = KhatmahPlanStore(defaults: freshDefaults())
        builder = InsightsSummaryBuilder(worshipTracker: worshipTracker,
                                         prayerCompletion: prayerCompletion,
                                         readingLog: readingLog,
                                         khatmahStore: khatmahStore)
    }

    override func tearDown() {
        for name in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        super.tearDown()
    }

    // MARK: - Window shape

    func testSummaryReturnsOnePointPerDayInTheRange() {
        for range in InsightsRange.allCases {
            let summary = builder.summary(range: range, endingAt: today)

            XCTAssertEqual(summary.dayPoints.count, range.dayCount)
            XCTAssertEqual(summary.range, range)
        }
    }

    func testDayPointsRunOldestToNewest() {
        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.dayPoints.last?.dayKey, readingLog.dayKey(for: today))
        XCTAssertEqual(summary.dayPoints.first?.dayKey,
                       readingLog.dayKey(for: readingLog.date(byAddingDays: -6, to: today)))
        XCTAssertEqual(summary.dayPoints.map(\.dayKey), summary.dayPoints.map(\.dayKey).sorted())
    }

    func testAnEmptyHistoryHasNoActivity() {
        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertFalse(summary.hasAnyActivity)
        XCTAssertEqual(summary.readPageCount, 0)
        XCTAssertEqual(summary.readingDayCount, 0)
        XCTAssertEqual(summary.prayedPrayerCount, 0)
        XCTAssertEqual(summary.trackedPrayerDayCount, 0)
        XCTAssertEqual(summary.activeWorshipDayCount, 0)
        XCTAssertNil(summary.khatmah)
    }

    // MARK: - Reading

    func testReadingTotalsCountDistinctPagesAcrossTheWindow() {
        readingLog.recordPageVisit(1, on: today)
        readingLog.recordPageVisit(2, on: today)
        readingLog.recordPageVisit(3, on: readingLog.date(byAddingDays: -2, to: today))

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.readPageCount, 3)
        XCTAssertEqual(summary.readingDayCount, 2)
        XCTAssertEqual(summary.peakReadPageCount, 2)
        XCTAssertTrue(summary.hasAnyActivity)
    }

    func testReadingOutsideTheWindowIsExcluded() {
        readingLog.recordPageVisit(1, on: readingLog.date(byAddingDays: -30, to: today))

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.readPageCount, 0)
        XCTAssertEqual(summary.averageReadPageCount, 0)
    }

    func testAverageReadPagesSpreadsOverEveryDayInTheRange() {
        for page in 1...7 {
            readingLog.recordPageVisit(page, on: today)
        }

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.averageReadPageCount, 1, accuracy: 0.0001)
    }

    // MARK: - Prayers

    func testPrayedPrayersAreTotalledAndTheirDaysCounted() {
        let todayKey = readingLog.dayKey(for: today)
        let earlierKey = readingLog.dayKey(for: readingLog.date(byAddingDays: -1, to: today))

        _ = prayerCompletion.toggle(index: 0, on: todayKey)
        _ = prayerCompletion.toggle(index: 1, on: todayKey)
        _ = prayerCompletion.toggle(index: 0, on: earlierKey)

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.prayedPrayerCount, 3)
        XCTAssertEqual(summary.trackedPrayerDayCount, 2)
    }

    func testPrayerConsistencyCoversEveryDailyPrayer() {
        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.prayerConsistency.count, WorshipCategory.prayers.acts.count)
        XCTAssertEqual(summary.prayerConsistency.map(\.prayerIndex), [0, 1, 2, 3, 4])
    }

    func testConsistencyFractionsUseOnlyTrackedDays() {
        let todayKey = readingLog.dayKey(for: today)
        let earlierKey = readingLog.dayKey(for: readingLog.date(byAddingDays: -1, to: today))

        _ = prayerCompletion.toggle(index: 0, on: todayKey)
        _ = prayerCompletion.toggle(index: 0, on: earlierKey)
        _ = prayerCompletion.toggle(index: 4, on: todayKey)

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.prayerConsistency.first { $0.prayerIndex == 0 }?.fraction, 1)
        XCTAssertEqual(summary.prayerConsistency.first { $0.prayerIndex == 4 }?.fraction, 0.5)
        XCTAssertEqual(summary.prayerConsistency.first { $0.prayerIndex == 2 }?.fraction, 0)
    }

    func testStrongestAndWeakestPrayersFollowTheLoggedDays() {
        let todayKey = readingLog.dayKey(for: today)
        let earlierKey = readingLog.dayKey(for: readingLog.date(byAddingDays: -1, to: today))

        _ = prayerCompletion.toggle(index: 0, on: todayKey)
        _ = prayerCompletion.toggle(index: 0, on: earlierKey)
        _ = prayerCompletion.toggle(index: 3, on: todayKey)

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.strongestPrayer?.prayerIndex, 0)
        XCTAssertEqual(summary.weakestPrayer?.fraction, 0)
    }

    func testPrayerCompletionFractionIsZeroWithoutTrackedDays() {
        XCTAssertEqual(builder.summary(range: .week, endingAt: today).prayerCompletionFraction, 0)
    }

    func testPrayerCompletionFractionComparesAgainstTheFivePrayersOfTrackedDays() {
        let todayKey = readingLog.dayKey(for: today)

        for index in 0...4 {
            _ = prayerCompletion.toggle(index: index, on: todayKey)
        }

        XCTAssertEqual(builder.summary(range: .week, endingAt: today).prayerCompletionFraction,
                       1,
                       accuracy: 0.0001)
    }

    // MARK: - Worship

    func testActiveWorshipDaysCountAnyLoggedAct() {
        let todayKey = readingLog.dayKey(for: today)

        worshipTracker.markCompleted(.tasbih, on: todayKey)

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.activeWorshipDayCount, 1)
        XCTAssertTrue(summary.hasAnyActivity)
    }

    func testWorshipFractionRisesWithEachLoggedAct() {
        let todayKey = readingLog.dayKey(for: today)

        worshipTracker.markCompleted(.tasbih, on: todayKey)
        worshipTracker.markCompleted(.morningAthkar, on: todayKey)

        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertEqual(summary.dayPoints.last?.worshipFraction ?? 0,
                       2 / Double(WorshipAct.allCases.count),
                       accuracy: 0.0001)
    }

    func testALoggedPrayerAlsoCountsAsWorshipActivity() {
        let todayKey = readingLog.dayKey(for: today)

        _ = prayerCompletion.toggle(index: 0, on: todayKey)

        XCTAssertEqual(builder.summary(range: .week, endingAt: today).activeWorshipDayCount, 1)
    }

    // MARK: - Khatmah

    func testKhatmahProgressIsAbsentWithoutAPlan() {
        let summary = builder.summary(range: .week, endingAt: today)

        XCTAssertNil(summary.khatmah)
        XCTAssertEqual(summary.completedKhatmahCount, 0)
    }

    func testKhatmahProgressMirrorsTheActivePlan() {
        let plan = khatmahStore.createPlan(totalDays: 30, startDate: today)
        khatmahStore.markDayCompleted(1)

        let khatmah = builder.summary(range: .week, endingAt: today).khatmah

        XCTAssertEqual(khatmah?.totalDayCount, plan.totalDays)
        XCTAssertEqual(khatmah?.totalPageCount, plan.pageCount)
        XCTAssertEqual(khatmah?.completedDayCount, 1)
        XCTAssertGreaterThan(khatmah?.readPageCount ?? 0, 0)
        XCTAssertGreaterThan(khatmah?.fraction ?? 0, 0)
    }

    func testKhatmahFractionIsZeroForAFreshPlan() {
        _ = khatmahStore.createPlan(totalDays: 30, startDate: today)

        XCTAssertEqual(builder.summary(range: .week, endingAt: today).khatmah?.fraction, 0)
    }

    // MARK: - Empty value

    func testTheEmptySummaryHasNoActivity() {
        XCTAssertFalse(InsightsSummary.empty.hasAnyActivity)
        XCTAssertEqual(InsightsSummary.empty.peakReadPageCount, 0)
        XCTAssertEqual(InsightsSummary.empty.averageReadPageCount, 0)
        XCTAssertEqual(InsightsSummary.empty.worshipCompletionFraction, 0)
        XCTAssertNil(InsightsSummary.empty.strongestPrayer)
    }
}

// MARK: - View model

@MainActor
final class InsightsViewModelTests: XCTestCase {

    private var suiteNames: [String] = []
    private var coordinator: InsightsCoordinatorSpy = InsightsCoordinatorSpy()
    private var prayerCompletion: PrayerCompletionStore = PrayerCompletionStore(defaults: .standard)
    private var worshipTracker: WorshipTrackerStore = WorshipTrackerStore(defaults: .standard)
    private var readingLog: QuranReadingLogStore = QuranReadingLogStore(defaults: .standard)
    private var khatmahStore: KhatmahPlanStore = KhatmahPlanStore(defaults: .standard)
    private var dateProbe: InsightsDateProbe = InsightsDateProbe(fixedDate: Date())
    private var bookmarkCount = 0

    override func setUp() {
        super.setUp()
        suiteNames = []
        bookmarkCount = 0
        coordinator = InsightsCoordinatorSpy()
        prayerCompletion = PrayerCompletionStore(defaults: freshDefaults())
        worshipTracker = WorshipTrackerStore(defaults: freshDefaults(),
                                             prayerCompletion: prayerCompletion)
        readingLog = QuranReadingLogStore(defaults: freshDefaults())
        khatmahStore = KhatmahPlanStore(defaults: freshDefaults())
        dateProbe = InsightsDateProbe(fixedDate: today)
    }

    override func tearDown() {
        for name in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        LocalizationManager.shared.currentLanguage = .Arabic
        super.tearDown()
    }

    // MARK: - Loading

    func testTheViewModelStartsOnTheWeekRangeWithAnEmptySummary() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.range, .week)
        XCTAssertEqual(viewModel.summary, .empty)
        XCTAssertFalse(viewModel.isTabBarVisible)
    }

    func testOnAppearLoadsTheSummaryAndTheBookmarkCount() {
        bookmarkCount = 4
        readingLog.recordPageVisit(1, on: today)

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertEqual(viewModel.summary.dayPoints.count, InsightsRange.week.dayCount)
        XCTAssertEqual(viewModel.summary.readPageCount, 1)
        XCTAssertEqual(viewModel.bookmarkCount, 4)
        XCTAssertEqual(dateProbe.readCount, 1)
    }

    func testSelectingAnotherRangeReloadsTheSummary() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.selectRange(.quarter)

        XCTAssertEqual(viewModel.range, .quarter)
        XCTAssertEqual(viewModel.summary.dayPoints.count, InsightsRange.quarter.dayCount)
        XCTAssertEqual(dateProbe.readCount, 2)
    }

    func testSelectingTheCurrentRangeDoesNotReload() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        viewModel.selectRange(.week)

        XCTAssertEqual(dateProbe.readCount, 1)
    }

    func testBackNavigationReachesTheCoordinator() {
        let viewModel = makeViewModel()

        viewModel.coordinateBack()

        XCTAssertEqual(coordinator.backCount, 1)
    }

    // MARK: - Empty state

    func testTheEmptyStateShowsUntilSomethingIsLogged() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertTrue(viewModel.isEmptyStateVisible)
        XCTAssertFalse(viewModel.isConsistencyVisible)
        XCTAssertFalse(viewModel.isKhatmahPlanActive)
        XCTAssertFalse(viewModel.emptyStateMessage.isEmpty)
    }

    func testLoggingAPageHidesTheEmptyState() {
        readingLog.recordPageVisit(1, on: today)

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertFalse(viewModel.isEmptyStateVisible)
    }

    // MARK: - Charts

    func testReadingBarsAreNormalisedToThePeakDay() {
        readingLog.recordPageVisit(1, on: today)
        readingLog.recordPageVisit(2, on: today)
        readingLog.recordPageVisit(3, on: readingLog.date(byAddingDays: -1, to: today))

        let viewModel = makeViewModel()
        viewModel.onAppear()

        let bars = viewModel.readingBars

        XCTAssertEqual(bars.count, InsightsRange.week.dayCount)
        XCTAssertEqual(bars.last?.fraction, 1)
        XCTAssertEqual(bars[bars.count - 2].fraction, 0.5)
        XCTAssertEqual(bars.first?.fraction, 0)
    }

    func testOnlyTheLastBarIsFlaggedAsToday() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertEqual(viewModel.readingBars.filter(\.isLastDay).count, 1)
        XCTAssertEqual(viewModel.worshipBars.filter(\.isLastDay).count, 1)
        XCTAssertTrue(viewModel.readingBars.last?.isLastDay == true)
    }

    func testBarsNeverExceedTheirTrack() {
        readingLog.recordPageVisit(1, on: today)

        let viewModel = makeViewModel()
        viewModel.onAppear()

        for bar in viewModel.readingBars + viewModel.worshipBars {
            XCTAssertGreaterThanOrEqual(bar.fraction, 0)
            XCTAssertLessThanOrEqual(bar.fraction, 1)
        }
    }

    // MARK: - Consistency

    func testConsistencyRowsAppearOnceAPrayerIsLogged() {
        _ = prayerCompletion.toggle(index: 0, on: readingLog.dayKey(for: today))

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertTrue(viewModel.isConsistencyVisible)
        XCTAssertEqual(viewModel.consistencyItems.count, WorshipCategory.prayers.acts.count)
        XCTAssertFalse(viewModel.consistencyItems.contains { $0.title.isEmpty })
        XCTAssertFalse(viewModel.consistencyItems.contains { $0.value.isEmpty })
    }

    func testTheStrongestPrayerIsNamedAndTheWeakestDiffers() {
        _ = prayerCompletion.toggle(index: 0, on: readingLog.dayKey(for: today))

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertFalse(viewModel.strongestPrayerText.isEmpty)
        XCTAssertNotEqual(viewModel.strongestPrayerText, viewModel.weakestPrayerText)
    }

    func testTheWeakestPrayerIsBlankWhenEveryPrayerMatches() {
        let todayKey = readingLog.dayKey(for: today)

        for index in 0...4 {
            _ = prayerCompletion.toggle(index: index, on: todayKey)
        }

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertTrue(viewModel.weakestPrayerText.isEmpty)
    }

    // MARK: - Khatmah

    func testKhatmahTextsAreBlankWithoutAPlan() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertFalse(viewModel.isKhatmahPlanActive)
        XCTAssertTrue(viewModel.khatmahPagesText.isEmpty)
        XCTAssertTrue(viewModel.khatmahDaysText.isEmpty)
        XCTAssertTrue(viewModel.khatmahDriftText.isEmpty)
        XCTAssertFalse(viewModel.khatmahNoPlanMessage.isEmpty)
    }

    func testKhatmahTextsAreFilledForAnActivePlan() {
        _ = khatmahStore.createPlan(totalDays: 30, startDate: today)

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertTrue(viewModel.isKhatmahPlanActive)
        XCTAssertFalse(viewModel.khatmahPagesText.isEmpty)
        XCTAssertFalse(viewModel.khatmahDaysText.isEmpty)
        XCTAssertFalse(viewModel.khatmahDriftText.isEmpty)
        XCTAssertFalse(viewModel.khatmahPercentText.isEmpty)
    }

    // MARK: - Labels

    func testEveryLabelResolvesInBothLanguages() {
        for language in [LocalizationManager.Language.Arabic, .English] {
            LocalizationManager.shared.currentLanguage = language

            let viewModel = makeViewModel()
            viewModel.onAppear()

            let labels = [viewModel.navigationTitle,
                          viewModel.overviewTitle,
                          viewModel.readingTrendTitle,
                          viewModel.worshipTrendTitle,
                          viewModel.consistencyTitle,
                          viewModel.strongestPrayerTitle,
                          viewModel.weakestPrayerTitle,
                          viewModel.khatmahTitle,
                          viewModel.khatmahNoPlanMessage,
                          viewModel.libraryTitle,
                          viewModel.emptyStateMessage,
                          viewModel.readingAverageText,
                          viewModel.worshipAverageText,
                          viewModel.trackedDaysNote]
                + viewModel.ranges.map(viewModel.rangeTitle)
                + viewModel.overviewMetrics.map(\.title)
                + viewModel.overviewMetrics.map(\.value)
                + viewModel.libraryMetrics.map(\.title)

            for label in labels {
                XCTAssertFalse(label.isEmpty, "empty label in \(language.rawValue)")
                XCTAssertFalse(label.hasPrefix("insights"), "unresolved key \(label)")
            }
        }
    }

    func testOverviewAndLibraryTilesHaveStableIdentities() {
        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertEqual(viewModel.overviewMetrics.map(\.id),
                       ["activeDays", "pagesRead", "prayersLogged"])
        XCTAssertEqual(viewModel.libraryMetrics.map(\.id), ["bookmarks", "completedKhatmah"])
        XCTAssertFalse(viewModel.overviewMetrics.contains { $0.icon.isEmpty })
    }

    func testArabicRendersArabicIndicDigits() {
        LocalizationManager.shared.currentLanguage = .Arabic
        bookmarkCount = 12

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertEqual(viewModel.libraryMetrics.first?.value, 12.arabicNumerals)
    }

    func testEnglishRendersWesternDigits() {
        LocalizationManager.shared.currentLanguage = .English
        bookmarkCount = 12

        let viewModel = makeViewModel()
        viewModel.onAppear()

        XCTAssertEqual(viewModel.libraryMetrics.first?.value, "12")
    }
}

// MARK: - Fixtures

private extension InsightsSummaryTests {

    var today: Date {
        KhatmahFixture.date(dayKey: KhatmahFixture.startDayKey, hour: 9)
    }

    func freshDefaults() -> UserDefaults {
        let name = UUID().uuidString
        suiteNames.append(name)
        return PrayerNotificationFixture.defaults(name)
    }
}

private extension InsightsViewModelTests {

    var today: Date {
        KhatmahFixture.date(dayKey: KhatmahFixture.startDayKey, hour: 9)
    }

    func freshDefaults() -> UserDefaults {
        let name = UUID().uuidString
        suiteNames.append(name)
        return PrayerNotificationFixture.defaults(name)
    }

    func makeViewModel() -> InsightsViewModel {
        let builder = InsightsSummaryBuilder(worshipTracker: worshipTracker,
                                            prayerCompletion: prayerCompletion,
                                            readingLog: readingLog,
                                            khatmahStore: khatmahStore)
        let probe = dateProbe

        return InsightsViewModel(coordinator: coordinator,
                                 summaryBuilder: builder,
                                 localizationManager: .shared,
                                 bookmarkCountProvider: { [weak self] in self?.bookmarkCount ?? 0 },
                                 currentDate: { probe.nextDate() })
    }
}
