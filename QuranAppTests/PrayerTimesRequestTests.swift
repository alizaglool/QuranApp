//
//  PrayerTimesRequestTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import XCTest
@testable import QuranApp

@MainActor
final class PrayerTimesRequestTests: XCTestCase {

    private let latitude = 24.7136
    private let longitude = 46.6753
    private let dayTimestamp = 1_793_404_800

    private func urlString(method: PrayerCalculationMethod,
                           school: PrayerJurisprudenceSchool) -> String {
        QuranService.prayerTimesURLString(latitude: latitude,
                                          longitude: longitude,
                                          methodId: method.rawValue,
                                          schoolId: school.rawValue,
                                          dayTimestamp: dayTimestamp)
    }

    private func location(latitude: Double, longitude: Double) -> SelectedLocation {
        SelectedLocation(cityName: "Riyadh",
                         countryCode: "SA",
                         latitude: latitude,
                         longitude: longitude,
                         timeZoneIdentifier: PrayerNotificationFixture.timeZoneIdentifier,
                         isResolvedFromDevice: false,
                         altitudeMeters: nil)
    }

    // MARK: - Aladhan URL

    func testRequestURLCarriesTheConfiguredMethodAndSchool() throws {
        let string = urlString(method: .moonsightingCommittee, school: .hanafi)
        let components = try XCTUnwrap(URLComponents(string: string))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

        XCTAssertEqual(components.host, "api.aladhan.com")
        XCTAssertEqual(components.path, "/v1/timings/\(dayTimestamp)")
        XCTAssertEqual(query["method"], "15")
        XCTAssertEqual(query["school"], "1")
        XCTAssertEqual(query["latitude"], "24.7136")
        XCTAssertEqual(query["longitude"], "46.6753")
    }

    func testRequestURLSendsTheDefaultMethodAndSchoolUnchanged() throws {
        let string = urlString(method: .default, school: .default)
        let components = try XCTUnwrap(URLComponents(string: string))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value) })

        XCTAssertEqual(PrayerCalculationMethod.default, .ummAlQuraUniversity)
        XCTAssertEqual(query["method"], "4")
        XCTAssertEqual(query["school"], "0")
    }

    func testEveryCalculationMethodProducesADistinctRequestURL() {
        let urls = PrayerCalculationMethod.allCases.map { urlString(method: $0, school: .default) }

        XCTAssertEqual(Set(urls).count, PrayerCalculationMethod.allCases.count)
        XCTAssertTrue(urls.allSatisfy { URL(string: $0) != nil })
    }

    func testEverySchoolProducesADistinctRequestURL() {
        let urls = PrayerJurisprudenceSchool.allCases.map { urlString(method: .default, school: $0) }

        XCTAssertEqual(Set(urls).count, PrayerJurisprudenceSchool.allCases.count)
    }

    // MARK: - Cache Identity

    func testCacheIdentifierSeparatesMethodAndSchool() {
        let riyadh = location(latitude: latitude, longitude: longitude)
        let ummAlQura = PrayerTimesStore.cacheIdentifier(
            for: riyadh,
            preferences: PrayerNotificationFixture.preferences(method: .ummAlQuraUniversity, school: .standard)
        )
        let moonsighting = PrayerTimesStore.cacheIdentifier(
            for: riyadh,
            preferences: PrayerNotificationFixture.preferences(method: .moonsightingCommittee, school: .standard)
        )
        let hanafi = PrayerTimesStore.cacheIdentifier(
            for: riyadh,
            preferences: PrayerNotificationFixture.preferences(method: .ummAlQuraUniversity, school: .hanafi)
        )

        XCTAssertEqual(ummAlQura, "24.714,46.675|m4|s0")
        XCTAssertNotEqual(ummAlQura, moonsighting)
        XCTAssertNotEqual(ummAlQura, hanafi)
        XCTAssertNotEqual(moonsighting, hanafi)
    }

    func testCacheIdentifierStillSeparatesLocations() {
        let preferences = PrayerNotificationFixture.preferences()
        let riyadh = PrayerTimesStore.cacheIdentifier(for: location(latitude: latitude, longitude: longitude),
                                                      preferences: preferences)
        let makkah = PrayerTimesStore.cacheIdentifier(for: location(latitude: 21.3891, longitude: 39.8579),
                                                      preferences: preferences)

        XCTAssertNotEqual(riyadh, makkah)
    }

    func testCacheIdentifierIsStableForTheSameInputs() {
        let preferences = PrayerNotificationFixture.preferences(method: .qatar, school: .hanafi)
        let first = PrayerTimesStore.cacheIdentifier(for: location(latitude: latitude, longitude: longitude),
                                                     preferences: preferences)
        let second = PrayerTimesStore.cacheIdentifier(for: location(latitude: latitude, longitude: longitude),
                                                      preferences: preferences)

        XCTAssertEqual(first, second)
    }

    // MARK: - Method Names

    func testEveryCalculationMethodHasALocalizationKey() {
        for method in PrayerCalculationMethod.allCases {
            XCTAssertNotNil(AppLocalizedKeys.prayerCalculationMethodKey(forMethodId: method.rawValue),
                            "missing key for method \(method.rawValue)")
        }
    }
}
