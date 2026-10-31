//
//  EgyptianRadioTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import XCTest
import Core
@testable import QuranApp

// MARK: - EgyptianRadioCatalogTests

final class EgyptianRadioCatalogTests: XCTestCase {

    // MARK: - Bundled Seed

    func testCairoStationIsPresentInTheBundledSeed() throws {
        let station = try XCTUnwrap(catalogStation)
        XCTAssertEqual(station.id, EgyptianRadioStationReference.identifier)
    }

    func testCairoStationCarriesTheExactStreamURL() throws {
        let station = try XCTUnwrap(catalogStation)
        XCTAssertEqual(station.url, "https://stream.radiojar.com/8s5u5tpdtwzuv")
    }

    func testCairoStationIsNotFlaggedLiveSoItRoutesThroughRadioPlayer() throws {
        let station = try XCTUnwrap(catalogStation)
        XCTAssertFalse(station.isLive)
    }

    func testCairoStationCarriesBothArabicAndEnglishNames() throws {
        let station = try XCTUnwrap(catalogStation)
        XCTAssertEqual(station.nameAr, "إذاعة القرآن الكريم من القاهرة")
        XCTAssertEqual(station.nameEn, "Holy Quran Radio from Cairo")
    }

    func testCairoStationStreamURLParsesOverHTTPS() throws {
        let station = try XCTUnwrap(catalogStation)
        let url = try XCTUnwrap(station.streamURL)
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "stream.radiojar.com")
    }

    func testCairoStationCarriesNoThumbnailSoTheScreenDrawsItsOwnArtwork() throws {
        let station = try XCTUnwrap(catalogStation)
        XCTAssertNil(station.thumbnail)
    }

    func testCairoStationLeadsTheCatalogBecauseFileOrderIsDisplayOrder() throws {
        let first = try XCTUnwrap(stations.first)
        XCTAssertEqual(first.id, EgyptianRadioStationReference.identifier)
    }

    func testCairoStationAppearsExactlyOnceInTheCatalog() {
        let matches = stations.filter { $0.id == EgyptianRadioStationReference.identifier }
        XCTAssertEqual(matches.count, 1)
    }

    func testCatalogStationIdentifiersAreUnique() {
        XCTAssertEqual(Set(stations.map(\.id)).count, stations.count)
    }

    // MARK: - No Regression

    func testHaramLiveChannelsStayFlaggedLiveAfterAddingCairo() throws {
        let makkah = try XCTUnwrap(stations.first { $0.id == 900_001 })
        let madinah = try XCTUnwrap(stations.first { $0.id == 900_002 })
        XCTAssertTrue(makkah.isLive)
        XCTAssertTrue(madinah.isLive)
        XCTAssertTrue(makkah.url.hasSuffix(".m3u8"))
        XCTAssertTrue(madinah.url.hasSuffix(".m3u8"))
    }

    func testSaudiQuranRadioStillShipsOnTheSameStreamHost() throws {
        let saudi = try XCTUnwrap(stations.first { $0.id == 109_082 })
        XCTAssertEqual(saudi.url, "https://stream.radiojar.com/0tpy1h0kxtzuv")
        XCTAssertFalse(saudi.isLive)
    }

    func testCatalogKeepsTheFullStationBrowserPopulated() {
        XCTAssertGreaterThan(stations.count, 100)
    }

    // MARK: - Station Reference

    func testReferenceResolvesTheCatalogEntry() {
        let resolved = EgyptianRadioStationReference.station(in: stations)
        XCTAssertEqual(resolved.id, EgyptianRadioStationReference.identifier)
        XCTAssertEqual(resolved.url, "https://stream.radiojar.com/8s5u5tpdtwzuv")
    }

    func testReferenceFallsBackWhenTheCatalogIsEmpty() {
        XCTAssertEqual(EgyptianRadioStationReference.station(in: []),
                       EgyptianRadioStationReference.fallback)
    }

    func testReferenceFallsBackWhenTheCatalogOmitsTheStation() {
        let others = stations.filter { $0.id != EgyptianRadioStationReference.identifier }
        XCTAssertEqual(EgyptianRadioStationReference.station(in: others),
                       EgyptianRadioStationReference.fallback)
    }

    func testFallbackMatchesTheBundledSeedSoTheScreenNeverDrifts() throws {
        let station = try XCTUnwrap(catalogStation)
        let fallback = EgyptianRadioStationReference.fallback
        XCTAssertEqual(fallback.id, station.id)
        XCTAssertEqual(fallback.url, station.url)
        XCTAssertEqual(fallback.nameAr, station.nameAr)
        XCTAssertEqual(fallback.nameEn, station.nameEn)
        XCTAssertEqual(fallback.isLive, station.isLive)
    }
}

// MARK: - Catalog Helpers

private extension EgyptianRadioCatalogTests {

    var stations: [RadioStation] { RadioCatalogService.shared.currentStations() }

    var catalogStation: RadioStation? {
        stations.first { $0.id == EgyptianRadioStationReference.identifier }
    }
}

// MARK: - EgyptianRadioViewModelTests

@MainActor
final class EgyptianRadioViewModelTests: XCTestCase {

    private var player: EgyptianRadioPlaybackSourceDouble = EgyptianRadioPlaybackSourceDouble()
    private var coordinator: RadioCoordinatorSpy = RadioCoordinatorSpy()
    private var viewModel: EgyptianRadioViewModel =
        EgyptianRadioViewModel(player: EgyptianRadioPlaybackSourceDouble())

    override func setUp() {
        super.setUp()
        player = EgyptianRadioPlaybackSourceDouble()
        coordinator = RadioCoordinatorSpy()
        viewModel = EgyptianRadioViewModel(coordinator: coordinator, player: player)
    }

    // MARK: - Playback State

    func testStateIsIdleBeforePlaybackStarts() {
        XCTAssertEqual(viewModel.playbackState, .idle)
        XCTAssertFalse(viewModel.isPlaying)
        XCTAssertFalse(viewModel.isConnecting)
        XCTAssertFalse(viewModel.isCurrentStation)
    }

    func testStateIsIdleWhileADifferentStationPlays() {
        player.currentStation = otherStation
        player.isPlaying = true
        XCTAssertEqual(viewModel.playbackState, .idle)
        XCTAssertFalse(viewModel.isPlaying)
    }

    func testStateIsConnectingWhileTheStreamLoads() {
        makeCurrent()
        player.isLoading = true
        XCTAssertEqual(viewModel.playbackState, .connecting)
        XCTAssertTrue(viewModel.isConnecting)
        XCTAssertFalse(viewModel.isPlaying)
    }

    func testStateIsPlayingOnceTheStreamStarts() {
        makeCurrent()
        player.isPlaying = true
        XCTAssertEqual(viewModel.playbackState, .playing)
        XCTAssertTrue(viewModel.isPlaying)
        XCTAssertFalse(viewModel.isConnecting)
    }

    func testStateIsPausedWhenTheCurrentStationIsNeitherLoadingNorPlaying() {
        makeCurrent()
        XCTAssertEqual(viewModel.playbackState, .paused)
        XCTAssertFalse(viewModel.isPlaying)
    }

    func testStateIsFailedAndTakesPrecedenceOverLoading() {
        makeCurrent()
        player.isLoading = true
        player.failure = .streamFailed
        XCTAssertEqual(viewModel.playbackState, .failed)
        XCTAssertFalse(viewModel.isConnecting)
    }

    func testStopIsAvailableOnlyForTheCurrentStation() {
        XCTAssertFalse(viewModel.isStopAvailable)
        makeCurrent()
        XCTAssertTrue(viewModel.isStopAvailable)
    }

    // MARK: - Failure Messages

    func testOfflineFailureSurfacesTheConnectionMessage() {
        makeCurrent()
        player.failure = .offline
        XCTAssertEqual(viewModel.failureMessage, AppLocalizedKeys.radioOfflineMessage.value)
        XCTAssertNotEqual(viewModel.failureMessage, AppLocalizedKeys.radioOfflineMessage.rawValue)
    }

    func testTimedOutFailureSurfacesTheTimeoutMessage() {
        makeCurrent()
        player.failure = .timedOut
        XCTAssertEqual(viewModel.failureMessage, AppLocalizedKeys.radioTimedOut.value)
        XCTAssertNotEqual(viewModel.failureMessage, AppLocalizedKeys.radioTimedOut.rawValue)
    }

    func testStreamFailedFailureSurfacesTheStreamMessage() {
        makeCurrent()
        player.failure = .streamFailed
        XCTAssertEqual(viewModel.failureMessage, AppLocalizedKeys.radioStreamFailed.value)
        XCTAssertNotEqual(viewModel.failureMessage, AppLocalizedKeys.radioStreamFailed.rawValue)
    }

    func testFailureMessageIsNilWithoutAFailure() {
        makeCurrent()
        XCTAssertNil(viewModel.failureMessage)
    }

    func testFailureMessageIsNilWhenAnotherStationFails() {
        player.currentStation = otherStation
        player.failure = .offline
        XCTAssertNil(viewModel.failureMessage)
    }

    // MARK: - Status Text

    func testStatusTextHintsAtPlaybackWhileIdle() {
        XCTAssertEqual(viewModel.statusText, AppLocalizedKeys.egyptianRadioIdleHint.value)
    }

    func testStatusTextReportsConnectingWhileTheStreamLoads() {
        makeCurrent()
        player.isLoading = true
        XCTAssertEqual(viewModel.statusText, AppLocalizedKeys.egyptianRadioConnecting.value)
    }

    func testStatusTextReportsNowPlayingWhilePlaying() {
        makeCurrent()
        player.isPlaying = true
        XCTAssertEqual(viewModel.statusText, AppLocalizedKeys.nowPlaying.value)
    }

    func testStatusTextRepeatsTheFailureMessageWhenPlaybackFails() {
        makeCurrent()
        player.failure = .timedOut
        XCTAssertEqual(viewModel.statusText, AppLocalizedKeys.radioTimedOut.value)
    }

    func testStatusTextFallsBackToTheIdleHintAfterPausing() {
        makeCurrent()
        player.isPlaying = true
        player.isPlaying = false
        XCTAssertEqual(viewModel.statusText, AppLocalizedKeys.egyptianRadioIdleHint.value)
    }

    // MARK: - Labels

    func testLabelsAreLocalizedNotRawKeys() {
        XCTAssertNotEqual(viewModel.screenTitle, AppLocalizedKeys.egyptianRadioTitle.rawValue)
        XCTAssertNotEqual(viewModel.screenSubtitle, AppLocalizedKeys.egyptianRadioSubtitle.rawValue)
        XCTAssertNotEqual(viewModel.liveBadgeTitle, AppLocalizedKeys.radioLive.rawValue)
        XCTAssertNotEqual(viewModel.liveNoteText, AppLocalizedKeys.egyptianRadioLiveNote.rawValue)
        XCTAssertNotEqual(viewModel.offlineBannerText, AppLocalizedKeys.radioOffline.rawValue)
        XCTAssertNotEqual(viewModel.stopActionTitle, AppLocalizedKeys.close.rawValue)
    }

    func testLabelsAreNeverEmpty() {
        XCTAssertFalse(viewModel.screenTitle.isEmpty)
        XCTAssertFalse(viewModel.screenSubtitle.isEmpty)
        XCTAssertFalse(viewModel.liveNoteText.isEmpty)
        XCTAssertFalse(viewModel.statusText.isEmpty)
        XCTAssertFalse(viewModel.stationName.isEmpty)
    }

    func testStationNameComesFromTheStationNotALocalizationKey() {
        XCTAssertTrue([viewModel.station.nameAr, viewModel.station.nameEn].contains(viewModel.stationName))
    }

    func testToggleActionOffersPlayWhileIdle() {
        XCTAssertEqual(viewModel.toggleActionIcon, "play.fill")
        XCTAssertEqual(viewModel.toggleActionTitle, AppLocalizedKeys.play.value)
    }

    func testToggleActionOffersPauseWhilePlaying() {
        makeCurrent()
        player.isPlaying = true
        XCTAssertEqual(viewModel.toggleActionIcon, "pause.fill")
        XCTAssertEqual(viewModel.toggleActionTitle, AppLocalizedKeys.pause.value)
    }

    func testToggleActionOffersPauseWhileConnecting() {
        makeCurrent()
        player.isLoading = true
        XCTAssertEqual(viewModel.toggleActionIcon, "pause.fill")
        XCTAssertEqual(viewModel.toggleActionTitle, AppLocalizedKeys.pause.value)
    }

    func testTabBarStaysHiddenOnTheRadioScreen() {
        XCTAssertFalse(viewModel.isTabBarVisible)
    }

    // MARK: - Actions

    func testInitPerformsNoNavigationOrPlayback() {
        XCTAssertTrue(coordinator.calls.isEmpty)
        XCTAssertTrue(player.playedStations.isEmpty)
        XCTAssertEqual(player.toggleCount, 0)
        XCTAssertEqual(player.stopCount, 0)
    }

    func testTogglingPlaybackStartsTheStationWhenItIsNotCurrent() {
        viewModel.onPlaybackToggled()
        XCTAssertEqual(player.playedStations.map(\.id), [viewModel.station.id])
        XCTAssertEqual(player.playedTitles, [viewModel.stationName])
        XCTAssertEqual(player.toggleCount, 0)
    }

    func testTogglingPlaybackTogglesThePlayerWhenTheStationIsCurrent() {
        makeCurrent()
        viewModel.onPlaybackToggled()
        XCTAssertEqual(player.toggleCount, 1)
        XCTAssertTrue(player.playedStations.isEmpty)
    }

    func testTogglingPlaybackStartsTheCairoStationOverAnotherStation() {
        player.currentStation = otherStation
        player.isPlaying = true
        viewModel.onPlaybackToggled()
        XCTAssertEqual(player.playedStations.map(\.id), [viewModel.station.id])
        XCTAssertEqual(player.toggleCount, 0)
    }

    func testStoppingIsIgnoredWhenTheStationIsNotCurrent() {
        viewModel.onStopTapped()
        XCTAssertEqual(player.stopCount, 0)
    }

    func testStoppingLeavesAnotherStationPlaying() {
        player.currentStation = otherStation
        player.isPlaying = true
        viewModel.onStopTapped()
        XCTAssertEqual(player.stopCount, 0)
        XCTAssertEqual(player.currentStation?.id, otherStation.id)
    }

    func testStoppingStopsThePlayerWhenTheStationIsCurrent() {
        makeCurrent()
        player.isPlaying = true
        viewModel.onStopTapped()
        XCTAssertEqual(player.stopCount, 1)
        XCTAssertFalse(viewModel.isCurrentStation)
    }

    func testBackNavigationRoutesThroughTheCoordinator() {
        viewModel.onBackTapped()
        XCTAssertEqual(coordinator.calls, [.back])
    }

    func testAppearResolvesTheCairoStationWithoutStartingPlayback() async {
        viewModel.onAppear()
        await PrayerNotificationWait.until {
            self.viewModel.station.id == EgyptianRadioStationReference.identifier
        }
        XCTAssertEqual(viewModel.station.url, "https://stream.radiojar.com/8s5u5tpdtwzuv")
        XCTAssertFalse(viewModel.station.isLive)
        XCTAssertTrue(player.playedStations.isEmpty)
    }
}

// MARK: - ViewModel Helpers

private extension EgyptianRadioViewModelTests {

    var otherStation: RadioStation {
        RadioStation(id: 109_082,
                     nameAr: "إذاعة القرآن الكريم - السعودية",
                     nameEn: "Holy Quran from Saudia Arabia",
                     url: "https://stream.radiojar.com/0tpy1h0kxtzuv")
    }

    func makeCurrent() {
        player.currentStation = viewModel.station
    }
}

// MARK: - RadioCoordinatorSpy

final class RadioCoordinatorSpy: RadioCoordinating {

    enum Call: Equatable {
        case start
        case liveChannel(stationID: Int, title: String)
        case egyptianRadio
        case back
    }

    private(set) var calls: [Call] = []

    func start() {
        calls.append(.start)
    }

    func coordinateToLiveChannel(_ station: RadioStation, title: String) {
        calls.append(.liveChannel(stationID: station.id, title: title))
    }

    func coordinateToEgyptianRadio() {
        calls.append(.egyptianRadio)
    }

    func coordinateBack() {
        calls.append(.back)
    }
}

// MARK: - Live Broadcast Promise

extension EgyptianRadioViewModelTests {

    func testLiveNoteDoesNotPromiseOfflinePlayback() {
        XCTAssertFalse(viewModel.liveNoteText.lowercased().contains("offline"))
        XCTAssertFalse(viewModel.liveNoteText.contains("بدون اتصال"))
    }

    func testTogglingTwiceStartsTheStreamThenTogglesThePlayer() {
        viewModel.onPlaybackToggled()

        XCTAssertEqual(player.playedStations.map(\.id), [viewModel.station.id])
        XCTAssertEqual(player.toggleCount, 0)

        viewModel.onPlaybackToggled()

        XCTAssertEqual(player.playedStations.count, 1)
        XCTAssertEqual(player.toggleCount, 1)
    }
}
