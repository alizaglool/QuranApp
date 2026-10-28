//
//  HomeViewModelTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 14/10/2026.
//

import XCTest
import Core
@testable import QuranApp

final class HomeCoordinatorSpy: HomeCoordinating {

    enum Call: Equatable {
        case surahDetail
        case search
        case quran(startPage: Int?)
        case adhkar
        case hadith
        case lessons
        case radio
        case recitations
        case reciterSurahs
        case sheikhDetail(id: String)
    }

    private(set) var calls: [Call] = []

    // MARK: - HomeCoordinating

    func coordinateToSurahDetail(surah: SurahEntity) {
        calls.append(.surahDetail)
    }

    func coordinateToSearch() {
        calls.append(.search)
    }

    func coordinateToQuran(startPage: Int?) {
        calls.append(.quran(startPage: startPage))
    }

    func coordinateToAdhkar() {
        calls.append(.adhkar)
    }

    func coordinateToHadith() {
        calls.append(.hadith)
    }

    func coordinateToLessons() {
        calls.append(.lessons)
    }

    func coordinateToRadio() {
        calls.append(.radio)
    }

    func coordinateToRecitations() {
        calls.append(.recitations)
    }

    func coordinateToReciterSurahs(reciter: ReciterInfo) {
        calls.append(.reciterSurahs)
    }

    func coordinateToSheikhDetail(sheikh: Sheikh) {
        calls.append(.sheikhDetail(id: sheikh.id))
    }
}

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var coordinator: HomeCoordinatorSpy!
    private var viewModel: HomeViewModel!

    override func setUp() {
        super.setUp()
        coordinator = HomeCoordinatorSpy()
        viewModel = HomeViewModel(coordinator: coordinator)
    }

    override func tearDown() {
        viewModel = nil
        coordinator = nil
        super.tearDown()
    }
}

// MARK: - Reading Card Start State

extension HomeViewModelTests {

    func testInitAppliesReadingStartState() {
        XCTAssertFalse(viewModel.hasReadingProgress)
        XCTAssertNil(viewModel.lastReadPage)
        XCTAssertEqual(viewModel.lastReadProgress, 0)
        XCTAssertEqual(viewModel.readingPercentText, "")
    }

    func testStartStateCopyIsPresent() {
        XCTAssertFalse(viewModel.readingTitle.isEmpty)
        XCTAssertFalse(viewModel.readingSubtitle.isEmpty)
        XCTAssertFalse(viewModel.readingCTATitle.isEmpty)
    }

    func testStartStateCopyIsLocalizedNotRawKeys() {
        XCTAssertNotEqual(viewModel.readingTitle, AppLocalizedKeys.readingStartTitle.rawValue)
        XCTAssertNotEqual(viewModel.readingSubtitle, AppLocalizedKeys.readingStartSubtitle.rawValue)
        XCTAssertNotEqual(viewModel.readingCTATitle, AppLocalizedKeys.readingStartAction.rawValue)
    }

    func testInitPerformsNoNavigation() {
        XCTAssertTrue(coordinator.calls.isEmpty)
    }
}

// MARK: - Quick Access Grid

extension HomeViewModelTests {

    func testQuickAccessItemsOrderAndCount() {
        let types: [QuickAccessType] = viewModel.quickAccessItems.map { $0.type }
        XCTAssertEqual(types, [.quran, .recitations, .radio, .adhkar, .hadith, .lessons])
    }

    func testQuickAccessItemsCarryTitleAndIcon() {
        for item in viewModel.quickAccessItems {
            XCTAssertFalse(item.title.isEmpty)
            XCTAssertFalse(item.icon.isEmpty)
        }
    }

    func testQuickAccessTitlesAreLocalizedNotRawKeys() {
        let keys: [AppLocalizedKeys] = [.quran, .recitations, .radio, .adhkar, .hadith, .lessons]
        for (item, key) in zip(viewModel.quickAccessItems, keys) {
            XCTAssertNotEqual(item.title, key.rawValue)
        }
    }

    func testQuickAccessRoutesEachTypeToItsDestination() {
        let expected: [HomeCoordinatorSpy.Call] = [
            .quran(startPage: nil),
            .recitations,
            .radio,
            .adhkar,
            .hadith,
            .lessons
        ]

        for item in viewModel.quickAccessItems {
            viewModel.onQuickAccessTapped(item)
        }

        XCTAssertEqual(coordinator.calls, expected)
    }
}

// MARK: - Navigation

extension HomeViewModelTests {

    func testSearchTapRoutesToSearchOnce() {
        viewModel.onSearchTapped()

        XCTAssertEqual(coordinator.calls, [.search])
    }

    func testResumeTapPassesLastReadPageThrough() {
        viewModel.onResumeTapped()

        XCTAssertEqual(coordinator.calls, [.quran(startPage: nil)])
    }

    func testSeeAllLessonsRoutesToLessons() {
        viewModel.onSeeAllLessonsTapped()

        XCTAssertEqual(coordinator.calls, [.lessons])
    }

    func testSeeAllRecitersRoutesToRecitations() {
        viewModel.onSeeAllRecitersTapped()

        XCTAssertEqual(coordinator.calls, [.recitations])
    }

    func testSheikhTapRoutesToThatSheikh() {
        let sheikh = Sheikh(id: "UC-test",
                            name: "Test Sheikh",
                            thumbnailUrl: "",
                            subscriberCount: 1,
                            videoCount: 1,
                            channelHandle: "@test",
                            channelDescription: "")

        viewModel.onSheikhTapped(sheikh)

        XCTAssertEqual(coordinator.calls, [.sheikhDetail(id: "UC-test")])
    }
}

// MARK: - Prayer Times Failure Path

extension HomeViewModelTests {

    func testCountdownTickWithoutCachedDayReportsFailure() {
        viewModel.onCountdownTick()

        XCTAssertTrue(viewModel.prayerTimesFailed)
        XCTAssertFalse(viewModel.prayerTimesLoaded)
        XCTAssertEqual(viewModel.loadingState, .failed)
        XCTAssertTrue(viewModel.prayerTimes.isEmpty)
        XCTAssertEqual(viewModel.nextPrayerName, "")
        XCTAssertEqual(viewModel.countdownText, "")
        XCTAssertEqual(viewModel.leftUntilText, "")
    }

    func testFailureStateDoesNotNavigate() {
        viewModel.onCountdownTick()

        XCTAssertTrue(coordinator.calls.isEmpty)
    }
}

// MARK: - Labels

extension HomeViewModelTests {

    func testHeaderAndPrayerLabelsArePresent() {
        XCTAssertFalse(viewModel.heroTitle.isEmpty)
        XCTAssertFalse(viewModel.searchAccessibilityLabel.isEmpty)
        XCTAssertFalse(viewModel.locationLabel.isEmpty)
        XCTAssertFalse(viewModel.nextPrayerLabel.isEmpty)
        XCTAssertFalse(viewModel.prayerTimesErrorTitle.isEmpty)
        XCTAssertFalse(viewModel.retryTitle.isEmpty)
    }

    func testLabelsAreLocalizedNotRawKeys() {
        XCTAssertNotEqual(viewModel.heroTitle, AppLocalizedKeys.homeHeroTitle.rawValue)
        XCTAssertNotEqual(viewModel.searchAccessibilityLabel, AppLocalizedKeys.homeSearchAction.rawValue)
        XCTAssertNotEqual(viewModel.locationLabel, AppLocalizedKeys.homeLocation.rawValue)
        XCTAssertNotEqual(viewModel.nextPrayerLabel, AppLocalizedKeys.nextPrayerLabel.rawValue)
        XCTAssertNotEqual(viewModel.prayerTimesErrorTitle, AppLocalizedKeys.prayerTimesUnavailable.rawValue)
        XCTAssertNotEqual(viewModel.retryTitle, AppLocalizedKeys.tryAgainAction.rawValue)
    }

    func testLocationAccessibilityLabelEmbedsLocation() {
        XCTAssertTrue(viewModel.locationAccessibilityLabel.contains(viewModel.locationLabel))
    }

    func testDatesAreEmptyBeforeOnAppear() {
        XCTAssertEqual(viewModel.hijriDate, "")
        XCTAssertEqual(viewModel.gregorianDate, "")
    }
}
