//
//  HijriCalendarTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import XCTest
import Core
@testable import QuranApp

// MARK: - Coordinator Double

final class HijriCalendarCoordinatorDouble: HijriCalendarCoordinating {

    private(set) var backCallCount = 0

    func coordinateBack() {
        backCallCount += 1
    }
}

// MARK: - Occasion Catalog

final class IslamicOccasionCatalogTests: XCTestCase {

    private let catalog = IslamicOccasionCatalog.shared

    private func identifiers(month: Int, day: Int, weekday: Int = 1) -> [String] {
        catalog.occasions(hijriMonth: month, hijriDay: day, weekday: weekday).map { $0.id }
    }

    func testMuharramOpeningDaysCarryTheirOccasions() {
        XCTAssertTrue(identifiers(month: 1, day: 1).contains("hijri-new-year"))
        XCTAssertTrue(identifiers(month: 1, day: 9).contains("tasua"))
        XCTAssertTrue(identifiers(month: 1, day: 10).contains("ashura"))
    }

    func testRamadanStartAndLastTenNights() {
        XCTAssertTrue(identifiers(month: 9, day: 1).contains("ramadan-start"))
        XCTAssertTrue(identifiers(month: 9, day: 21).contains("ramadan-last-ten"))
        XCTAssertTrue(identifiers(month: 9, day: 27).contains("ramadan-last-ten"))
        XCTAssertFalse(identifiers(month: 9, day: 20).contains("ramadan-last-ten"))
    }

    func testEidDaysAreCelebrations() {
        let fitr = catalog.occasions(hijriMonth: 10, hijriDay: 1, weekday: 1)
        XCTAssertEqual(fitr.first { $0.id == "eid-al-fitr" }?.kind, .celebration)

        let adha = catalog.occasions(hijriMonth: 12, hijriDay: 10, weekday: 1)
        XCTAssertEqual(adha.first { $0.id == "eid-al-adha" }?.kind, .celebration)
    }

    func testDhulHijjahRangesOverlapCorrectly() {
        let arafah = identifiers(month: 12, day: 9)
        XCTAssertTrue(arafah.contains("dhul-hijjah-first-ten"))
        XCTAssertTrue(arafah.contains("day-of-arafah"))

        XCTAssertTrue(identifiers(month: 12, day: 12).contains("days-of-tashriq"))
        XCTAssertFalse(identifiers(month: 12, day: 14).contains("days-of-tashriq"))
    }

    func testWhiteDaysAppearInOrdinaryMonthsOnly() {
        for day in 13 ... 15 {
            XCTAssertTrue(identifiers(month: 2, day: day).contains("white-days"))
            XCTAssertFalse(identifiers(month: 9, day: day).contains("white-days"))
            XCTAssertFalse(identifiers(month: 12, day: day).contains("white-days"))
        }
        XCTAssertFalse(identifiers(month: 2, day: 12).contains("white-days"))
        XCTAssertFalse(identifiers(month: 2, day: 16).contains("white-days"))
    }

    func testVoluntaryFastDayIsSuppressedWhenFastingIsForbidden() {
        XCTAssertTrue(identifiers(month: 2, day: 5, weekday: 2).contains("voluntary-fast-day"))
        XCTAssertTrue(identifiers(month: 2, day: 5, weekday: 5).contains("voluntary-fast-day"))
        XCTAssertFalse(identifiers(month: 2, day: 5, weekday: 4).contains("voluntary-fast-day"))

        XCTAssertFalse(identifiers(month: 9, day: 5, weekday: 2).contains("voluntary-fast-day"))
        XCTAssertFalse(identifiers(month: 10, day: 1, weekday: 2).contains("voluntary-fast-day"))
        XCTAssertFalse(identifiers(month: 12, day: 11, weekday: 2).contains("voluntary-fast-day"))
    }

    func testFridayRemembranceSurvivesEveryMonth() {
        for month in 1 ... 12 {
            XCTAssertTrue(identifiers(month: month, day: 5, weekday: 6)
                .contains("friday-surah-al-kahf"))
        }
    }

    func testFastingForbiddenTruthTable() {
        XCTAssertTrue(IslamicOccasionCatalog.isVoluntaryFastingForbidden(hijriMonth: 9, hijriDay: 1))
        XCTAssertTrue(IslamicOccasionCatalog.isVoluntaryFastingForbidden(hijriMonth: 10, hijriDay: 1))
        XCTAssertFalse(IslamicOccasionCatalog.isVoluntaryFastingForbidden(hijriMonth: 10, hijriDay: 2))
        XCTAssertTrue(IslamicOccasionCatalog.isVoluntaryFastingForbidden(hijriMonth: 12, hijriDay: 10))
        XCTAssertTrue(IslamicOccasionCatalog.isVoluntaryFastingForbidden(hijriMonth: 12, hijriDay: 13))
        XCTAssertFalse(IslamicOccasionCatalog.isVoluntaryFastingForbidden(hijriMonth: 12, hijriDay: 9))
        XCTAssertFalse(IslamicOccasionCatalog.isVoluntaryFastingForbidden(hijriMonth: 2, hijriDay: 14))
    }
}

// MARK: - Month Grid

final class HijriMonthGridBuilderTests: XCTestCase {

    private let timeZone = TimeZone(identifier: "Asia/Riyadh") ?? .current
    private var builder = HijriMonthGridBuilder()
    private var calendar = Calendar(identifier: .islamicUmmAlQura)

    override func setUp() {
        super.setUp()
        builder = HijriMonthGridBuilder(timeZone: timeZone)
        calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    func testMonthMatchesCalendarDayRange() {
        let anchor = date(year: 1448, month: 1, day: 1)
        let month = builder.month(containing: anchor, today: anchor)

        let expectedCount = calendar.range(of: .day, in: .month, for: anchor)?.count
        XCTAssertEqual(month.days.count, expectedCount)
        XCTAssertEqual(month.hijriMonth, 1)
        XCTAssertEqual(month.hijriYear, 1448)
        XCTAssertEqual(month.days.first?.hijriDay, 1)
        XCTAssertEqual(month.days.last?.hijriDay, expectedCount)
    }

    func testLeadingBlankCountMatchesFirstWeekday() {
        let anchor = date(year: 1448, month: 3, day: 1)
        let month = builder.month(containing: anchor, today: anchor)

        let firstWeekday = calendar.component(.weekday, from: anchor)
        XCTAssertEqual(month.leadingBlankCount, firstWeekday - 1)
        XCTAssertTrue((0 ... 6).contains(month.leadingBlankCount))
    }

    func testCellsPadLeadingBlanksThenDays() {
        let anchor = date(year: 1448, month: 5, day: 1)
        let month = builder.month(containing: anchor, today: anchor)
        let cells = month.cells

        XCTAssertEqual(cells.count, month.leadingBlankCount + month.days.count)
        XCTAssertEqual(cells.prefix(month.leadingBlankCount).filter { $0.isBlank }.count,
                       month.leadingBlankCount)
        XCTAssertFalse(cells[month.leadingBlankCount].isBlank)
        XCTAssertEqual(Set(cells.map { $0.id }).count, cells.count)
    }

    func testTodayMarkerOnlyAppearsInTheMatchingMonth() {
        let anchor = date(year: 1448, month: 2, day: 7)
        let sameMonth = builder.month(containing: anchor, today: anchor)
        XCTAssertEqual(sameMonth.todayDay?.hijriDay, 7)
        XCTAssertEqual(sameMonth.days.filter { $0.isToday }.count, 1)

        let otherMonth = builder.month(offsetBy: 1, from: anchor, today: anchor)
        XCTAssertNil(otherMonth.todayDay)
    }

    func testMonthOffsetMovesForwardAndBackward() {
        let anchor = date(year: 1448, month: 6, day: 10)

        let next = builder.month(offsetBy: 1, from: anchor, today: anchor)
        XCTAssertEqual(next.hijriMonth, 7)
        XCTAssertEqual(next.hijriYear, 1448)

        let previous = builder.month(offsetBy: -1, from: anchor, today: anchor)
        XCTAssertEqual(previous.hijriMonth, 5)
        XCTAssertEqual(previous.hijriYear, 1448)
    }

    func testMonthOffsetRollsOverTheHijriYear() {
        let muharram = date(year: 1448, month: 1, day: 1)
        let back = builder.month(offsetBy: -1, from: muharram, today: muharram)
        XCTAssertEqual(back.hijriMonth, 12)
        XCTAssertEqual(back.hijriYear, 1447)

        let dhulHijjah = date(year: 1448, month: 12, day: 1)
        let forward = builder.month(offsetBy: 1, from: dhulHijjah, today: dhulHijjah)
        XCTAssertEqual(forward.hijriMonth, 1)
        XCTAssertEqual(forward.hijriYear, 1449)
    }

    func testOccasionsReachTheGridDays() {
        let dhulHijjah = date(year: 1448, month: 12, day: 1)
        let month = builder.month(containing: dhulHijjah, today: dhulHijjah)

        XCTAssertTrue(month.day(numbered: 9)?.occasions.contains { $0.id == "day-of-arafah" } ?? false)
        XCTAssertTrue(month.day(numbered: 10)?.hasOccasion ?? false)
        XCTAssertFalse(month.day(numbered: 14)?.occasions.contains { $0.id == "white-days" } ?? true)
    }

    func testWeekdayTitlesAlwaysCoverTheWholeWeek() {
        XCTAssertEqual(builder.weekdayTitles(languageCode: "ar").count, 7)
        XCTAssertEqual(builder.weekdayTitles(languageCode: "en").count, 7)
        XCTAssertEqual(Set(builder.weekdayTitles(languageCode: "en")).count, 7)
    }

    func testEmptyMonthFallbackIsIdentifiable() {
        XCTAssertTrue(HijriCalendarMonth.empty.isEmpty)
        XCTAssertNil(HijriCalendarMonth.empty.firstDate)
        XCTAssertTrue(HijriCalendarMonth.empty.cells.isEmpty)
    }
}

// MARK: - View Model

@MainActor
final class HijriCalendarViewModelTests: XCTestCase {

    private var coordinator: HijriCalendarCoordinatorDouble!
    private var viewModel: HijriCalendarViewModel!

    override func setUp() {
        super.setUp()
        coordinator = HijriCalendarCoordinatorDouble()
        viewModel = HijriCalendarViewModel(coordinator: coordinator,
                                           gridBuilder: HijriMonthGridBuilder(timeZone: TimeZone(identifier: "Asia/Riyadh") ?? .current))
    }

    override func tearDown() {
        viewModel = nil
        coordinator = nil
        super.tearDown()
    }

    func testOnAppearLoadsTheCurrentMonth() {
        viewModel.onAppear()

        XCTAssertFalse(viewModel.month.isEmpty)
        XCTAssertFalse(viewModel.cells.isEmpty)
        XCTAssertFalse(viewModel.monthTitle.isEmpty)
        XCTAssertEqual(viewModel.weekdayTitles.count, 7)
        XCTAssertNotNil(viewModel.selectedDay)
        XCTAssertTrue(viewModel.isCurrentMonth)
    }

    func testOnAppearSelectsTodayWhenAvailable() {
        viewModel.onAppear()
        XCTAssertEqual(viewModel.selectedDay?.isToday, true)
    }

    func testOnAppearDoesNotReloadAnAlreadyLoadedMonth() {
        viewModel.onAppear()
        viewModel.showNextMonth()
        let title = viewModel.monthTitle

        viewModel.onAppear()
        XCTAssertEqual(viewModel.monthTitle, title)
        XCTAssertFalse(viewModel.isCurrentMonth)
    }

    func testMonthNavigationMovesAwayAndReturns() {
        viewModel.onAppear()
        let currentTitle = viewModel.monthTitle

        viewModel.showNextMonth()
        XCTAssertNotEqual(viewModel.monthTitle, currentTitle)
        XCTAssertFalse(viewModel.isCurrentMonth)

        viewModel.showPreviousMonth()
        XCTAssertEqual(viewModel.monthTitle, currentTitle)
        XCTAssertTrue(viewModel.isCurrentMonth)

        viewModel.showPreviousMonth()
        viewModel.returnToCurrentMonth()
        XCTAssertEqual(viewModel.monthTitle, currentTitle)
        XCTAssertTrue(viewModel.isCurrentMonth)
    }

    func testNavigatingAwayDropsTheTodaySelection() {
        viewModel.onAppear()
        viewModel.showNextMonth()

        XCTAssertEqual(viewModel.selectedDay?.isToday, false)
        XCTAssertEqual(viewModel.selectedDay?.hijriDay, 1)
    }

    func testSelectDayUpdatesTheDetailTexts() {
        viewModel.onAppear()
        guard let target = viewModel.month.day(numbered: 1) else {
            return XCTFail("The loaded month has no first day")
        }

        viewModel.selectDay(target)
        XCTAssertEqual(viewModel.selectedDay?.id, target.id)
        XCTAssertFalse(viewModel.selectedHijriDateText.isEmpty)
        XCTAssertFalse(viewModel.selectedGregorianDateText.isEmpty)
        XCTAssertEqual(viewModel.selectedOccasions.map { $0.id }, target.occasions.map { $0.id })
    }

    func testDayAccessibilityLabelJoinsTheOccasionTitles() {
        let timeZone = TimeZone(identifier: "Asia/Riyadh") ?? .current
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone
        let arafah = calendar.date(from: DateComponents(year: 1448, month: 12, day: 9)) ?? Date()

        let model = HijriCalendarViewModel(coordinator: coordinator,
                                           gridBuilder: HijriMonthGridBuilder(timeZone: timeZone),
                                           today: arafah)
        model.onAppear()

        guard let day = model.month.day(numbered: 9) else {
            return XCTFail("Dhul-Hijjah 1448 has no ninth day")
        }
        let label = model.dayAccessibilityLabel(day)
        XCTAssertTrue(label.contains("·"))
        XCTAssertTrue(label.contains(model.occasionTitle(day.occasions[0])))

        guard let plainDay = model.month.day(numbered: 14) else {
            return XCTFail("Dhul-Hijjah 1448 has no fourteenth day")
        }
        if plainDay.occasions.isEmpty {
            XCTAssertFalse(model.dayAccessibilityLabel(plainDay).contains("·"))
        }
    }

    func testDayNumbersFollowTheActiveLanguage() {
        let manager = LocalizationManager.shared
        let original = manager.currentLanguage
        defer { manager.currentLanguage = original }

        let timeZone = TimeZone(identifier: "Asia/Riyadh") ?? .current

        manager.currentLanguage = .English
        let english = HijriCalendarViewModel(coordinator: coordinator,
                                             gridBuilder: HijriMonthGridBuilder(timeZone: timeZone))
        english.onAppear()
        guard let englishDay = english.month.day(numbered: 3) else {
            return XCTFail("The loaded month has no third day")
        }
        XCTAssertEqual(english.dayNumberText(englishDay), "3")

        manager.currentLanguage = .Arabic
        let arabic = HijriCalendarViewModel(coordinator: coordinator,
                                            gridBuilder: HijriMonthGridBuilder(timeZone: timeZone))
        arabic.onAppear()
        guard let arabicDay = arabic.month.day(numbered: 3) else {
            return XCTFail("The loaded month has no third day")
        }
        XCTAssertEqual(arabic.dayNumberText(arabicDay), 3.arabicNumerals)
    }

    func testMonthTitleCarriesTheHijriEraSuffix() {
        let manager = LocalizationManager.shared
        let original = manager.currentLanguage
        defer { manager.currentLanguage = original }

        manager.currentLanguage = .Arabic
        let model = HijriCalendarViewModel(coordinator: coordinator,
                                           gridBuilder: HijriMonthGridBuilder(timeZone: TimeZone(identifier: "Asia/Riyadh") ?? .current))
        model.onAppear()

        XCTAssertTrue(model.monthTitle.hasSuffix(AppLocalizedKeys.hijriEraSuffix.value))
        XCTAssertTrue(model.selectedHijriDateText.hasSuffix(AppLocalizedKeys.hijriEraSuffix.value))
    }

    func testLabelsResolveThroughLocalizedKeys() {
        XCTAssertEqual(viewModel.navigationTitle, AppLocalizedKeys.hijriCalendarTitle.value)
        XCTAssertEqual(viewModel.todayTitle, AppLocalizedKeys.today.value)
        XCTAssertEqual(viewModel.occasionsSectionTitle,
                       AppLocalizedKeys.hijriCalendarOccasionsTitle.value)
        XCTAssertEqual(viewModel.noOccasionMessage,
                       AppLocalizedKeys.hijriCalendarNoOccasionMessage.value)
        XCTAssertEqual(viewModel.previousMonthAccessibilityLabel,
                       AppLocalizedKeys.hijriCalendarPreviousMonth.value)
        XCTAssertEqual(viewModel.nextMonthAccessibilityLabel,
                       AppLocalizedKeys.hijriCalendarNextMonth.value)
    }

    func testScreenHidesTheTabBarAndPopsOnBack() {
        XCTAssertFalse(viewModel.isTabBarVisible)

        viewModel.coordinateBack()
        XCTAssertEqual(coordinator.backCallCount, 1)
    }

    func testDetailTextsStayEmptyWithoutASelection() {
        XCTAssertTrue(viewModel.selectedHijriDateText.isEmpty)
        XCTAssertTrue(viewModel.selectedGregorianDateText.isEmpty)
        XCTAssertTrue(viewModel.selectedOccasions.isEmpty)
    }
}
