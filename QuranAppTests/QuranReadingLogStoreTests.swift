//
//  QuranReadingLogStoreTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import XCTest
import Core
@testable import QuranApp

@MainActor
final class QuranReadingLogStoreTests: XCTestCase {

    private var suiteName: String = ""
    private var defaults: UserDefaults = .standard
    private var store: QuranReadingLogStore = QuranReadingLogStore(defaults: .standard)

    override func setUp() {
        super.setUp()
        suiteName = UUID().uuidString
        defaults = PrayerNotificationFixture.defaults(suiteName)
        store = QuranReadingLogStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    // MARK: - Empty state

    func testNewStoreHasNoHistory() {
        XCTAssertTrue(store.pages(on: store.dayKey(for: today)).isEmpty)
        XCTAssertEqual(store.pageCount(on: store.dayKey(for: today)), 0)
    }

    func testRecentPageCountsReturnsOneZeroEntryPerRequestedDay() {
        let counts = store.recentPageCounts(dayCount: 7, endingAt: today)

        XCTAssertEqual(counts.count, 7)
        XCTAssertEqual(counts.map(\.pageCount), Array(repeating: 0, count: 7))
    }

    // MARK: - Recording

    func testRecordPageVisitStoresThePageOnItsOwnDay() {
        store.recordPageVisit(42, on: today)

        XCTAssertEqual(store.pages(on: store.dayKey(for: today)), [42])
        XCTAssertEqual(store.pageCount(on: store.dayKey(for: today)), 1)
    }

    func testRevisitingTheSamePageDoesNotCountTwice() {
        store.recordPageVisit(42, on: today)
        store.recordPageVisit(42, on: today)
        store.recordPageVisit(42, on: today)

        XCTAssertEqual(store.pageCount(on: store.dayKey(for: today)), 1)
    }

    func testTheSamePageCountsOncePerDay() {
        let yesterday = store.date(byAddingDays: -1, to: today)

        store.recordPageVisit(42, on: yesterday)
        store.recordPageVisit(42, on: today)

        XCTAssertEqual(store.pageCount(on: store.dayKey(for: yesterday)), 1)
        XCTAssertEqual(store.pageCount(on: store.dayKey(for: today)), 1)
    }

    func testDistinctPagesAccumulateOnTheSameDay() {
        for page in 1...5 {
            store.recordPageVisit(page, on: today)
        }

        XCTAssertEqual(store.pageCount(on: store.dayKey(for: today)), 5)
        XCTAssertEqual(store.pages(on: store.dayKey(for: today)), [1, 2, 3, 4, 5])
    }

    func testNonPositivePagesAreRejected() {
        store.recordPageVisit(0, on: today)
        store.recordPageVisit(-7, on: today)

        XCTAssertEqual(store.pageCount(on: store.dayKey(for: today)), 0)
    }

    // MARK: - Windows

    func testRecentPageCountsIsOrderedOldestToNewest() {
        store.recordPageVisit(1, on: store.date(byAddingDays: -2, to: today))
        store.recordPageVisit(2, on: today)
        store.recordPageVisit(3, on: today)

        let counts = store.recentPageCounts(dayCount: 3, endingAt: today)

        XCTAssertEqual(counts.map(\.pageCount), [1, 0, 2])
        XCTAssertEqual(counts.last?.dayKey, store.dayKey(for: today))
    }

    func testRecentPageCountsIgnoresDaysOutsideTheWindow() {
        store.recordPageVisit(1, on: store.date(byAddingDays: -9, to: today))

        let counts = store.recentPageCounts(dayCount: 7, endingAt: today)

        XCTAssertEqual(counts.reduce(0) { $0 + $1.pageCount }, 0)
    }

    func testRecentPageCountsRejectsANonPositiveWindow() {
        XCTAssertTrue(store.recentPageCounts(dayCount: 0, endingAt: today).isEmpty)
    }

    // MARK: - Persistence

    func testHistorySurvivesANewStoreOnTheSameDefaults() {
        store.recordPageVisit(42, on: today)

        let reloaded = QuranReadingLogStore(defaults: defaults)

        XCTAssertEqual(reloaded.pageCount(on: reloaded.dayKey(for: today)), 1)
    }

    func testClearHistoryRemovesEveryDay() {
        store.recordPageVisit(42, on: today)
        store.recordPageVisit(43, on: store.date(byAddingDays: -1, to: today))

        store.clearHistory()

        XCTAssertEqual(store.pageCount(on: store.dayKey(for: today)), 0)
        XCTAssertEqual(store.recentPageCounts(dayCount: 7, endingAt: today).reduce(0) { $0 + $1.pageCount }, 0)
    }

    // MARK: - Day keys

    func testDayKeyUsesTheSharedYearMonthDayShape() {
        let key = store.dayKey(for: today)

        XCTAssertEqual(key.count, 10)
        XCTAssertEqual(key.filter { $0 == "-" }.count, 2)
    }
}

// MARK: - Fixture

private extension QuranReadingLogStoreTests {

    var today: Date {
        KhatmahFixture.date(dayKey: KhatmahFixture.startDayKey, hour: 9)
    }
}
