//
//  PrayerNotificationContentTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import XCTest
import Core
@testable import QuranApp

@MainActor
final class PrayerNotificationContentTests: XCTestCase {

    private static let corpus: [String: String] = {
        guard let url = Bundle(for: PrayerNotificationContentTests.self).url(forResource: "quran_text",
                                                                            withExtension: "json")
                ?? Bundle.main.url(forResource: "quran_text", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }

        return decoded
    }()

    private let verses = PrayerNotificationContentCatalog.verses
    private let dayKey = PrayerNotificationFixture.mondayDayKey

    private var now: Date {
        PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey, minutesSinceMidnight: 30)
    }

    private func manager(center: LocalNotificationCenterDouble,
                         preferences: PrayerNotificationPreferences) -> PrayerNotificationManager {
        PrayerNotificationManagerBuilder.manager(center: center,
                                                 defaults: PrayerNotificationFixture.defaults(),
                                                 preferences: preferences,
                                                 now: now)
    }

    private func dayKey(of identifier: String) -> String? {
        let parts = identifier.components(separatedBy: ".")
        guard parts.count == 4, parts[0] == PrayerNotificationIdentifier.ownedPrefix else { return nil }
        return parts[1]
    }

    private func expectedBody(for identifier: String) -> String? {
        guard let dayKey = dayKey(of: identifier),
              let slot = PrayerNotificationIdentifier.slot(of: identifier),
              let kind = PrayerNotificationIdentifier.kind(of: identifier),
              let content = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind)
        else { return nil }

        return PrayerNotificationContentCatalog.localizedBody(for: content, isArabic: isArabic)
    }

    private var isArabic: Bool { LocalizationManager.shared.currentLanguage == .Arabic }

    // MARK: - Authenticity

    func testTheBundledQuranCorpusIsReadableInTests() {
        XCTAssertEqual(PrayerNotificationContentTests.corpus.count, 6236)
    }

    func testEveryCatalogVerseMatchesTheBundledQuranTextExactly() {
        XCTAssertFalse(PrayerNotificationContentTests.corpus.isEmpty)

        for verse in verses {
            let bundled = PrayerNotificationContentTests.corpus[verse.id]

            XCTAssertNotNil(bundled, "\(verse.id) is not a verse in quran_text.json")
            XCTAssertEqual(verse.arabicText,
                           bundled,
                           "\(verse.id) does not match the bundled Quran text verbatim")
        }
    }

    func testEveryCatalogEntryIsUniqueAndWellFormed() {
        XCTAssertEqual(Set(verses.map(\.id)).count, verses.count)

        for verse in verses {
            XCTAssertTrue((1...114).contains(verse.surah))
            XCTAssertGreaterThan(verse.ayah, 0)
            XCTAssertFalse(verse.arabicText.isEmpty)
            XCTAssertFalse(verse.englishText.isEmpty)
            XCTAssertFalse(verse.arabicSurahName.isEmpty)
            XCTAssertFalse(verse.englishSurahName.isEmpty)
        }
    }

    func testSurahNamesStayConsistentForTheSameSurah() {
        let arabicNames = Dictionary(grouping: verses, by: \.surah).mapValues { Set($0.map(\.arabicSurahName)) }
        let englishNames = Dictionary(grouping: verses, by: \.surah).mapValues { Set($0.map(\.englishSurahName)) }

        XCTAssertTrue(arabicNames.values.allSatisfy { $0.count == 1 })
        XCTAssertTrue(englishNames.values.allSatisfy { $0.count == 1 })
    }

    func testReferencesStayPairedWithTheirOwnVerse() {
        for verse in verses {
            XCTAssertEqual(verse.englishReference, "\(verse.englishSurahName) \(verse.surah):\(verse.ayah)")
            XCTAssertTrue(verse.arabicReference.hasPrefix(verse.arabicSurahName))
            XCTAssertTrue(verse.arabicReference.hasSuffix(verse.ayah.arabicNumerals))
        }
    }

    // MARK: - Selection

    func testTheCatalogHoldsEnoughVersesForAFullDayWithoutRepeating() {
        XCTAssertGreaterThanOrEqual(verses.count,
                                    PrayerSlot.allCases.count * PrayerNotificationKind.allCases.count)
    }

    func testOneDayNeverRepeatsAVerseAcrossPrayersOrKinds() {
        for dayKey in [PrayerNotificationFixture.mondayDayKey,
                       PrayerNotificationFixture.tuesdayDayKey,
                       PrayerNotificationFixture.fridayDayKey] {
            var identifiers: [String] = []

            for slot in PrayerSlot.allCases {
                for kind in PrayerNotificationKind.allCases {
                    let content = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind)

                    XCTAssertNotNil(content)
                    identifiers.append(content?.id ?? "")
                }
            }

            XCTAssertEqual(Set(identifiers).count, identifiers.count, "\(dayKey) repeats a verse")
        }
    }

    func testContentSelectionIsDeterministicForTheSameDayAndSlot() {
        for slot in PrayerSlot.allCases {
            for kind in PrayerNotificationKind.allCases {
                let first = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind)

                for _ in 0..<25 {
                    XCTAssertEqual(PrayerNotificationContentCatalog.content(dayKey: dayKey,
                                                                           slot: slot,
                                                                           kind: kind),
                                   first)
                }
            }
        }
    }

    func testContentVariesAcrossDays() {
        let dayKeys = (1...28).map { String(format: "2026-11-%02d", $0) }
        let selected = dayKeys.compactMap {
            PrayerNotificationContentCatalog.content(dayKey: $0, slot: .fajr, kind: .adhan)?.id
        }

        XCTAssertEqual(selected.count, dayKeys.count)
        XCTAssertGreaterThanOrEqual(Set(selected).count, 8)
    }

    // MARK: - Localized Bodies

    func testArabicBodyCarriesTheArabicVerseAndItsReference() {
        for verse in verses {
            let body = PrayerNotificationContentCatalog.localizedBody(for: verse, isArabic: true)

            XCTAssertTrue(body.hasPrefix("\u{FD3E}"))
            XCTAssertTrue(body.contains("\u{FD3F}"))
            XCTAssertTrue(body.contains(verse.arabicText))
            XCTAssertTrue(body.contains(verse.arabicReference))
            XCTAssertFalse(body.contains(verse.englishText))
        }
    }

    func testEnglishBodyCarriesTheTranslationAndItsReference() {
        for verse in verses {
            let body = PrayerNotificationContentCatalog.localizedBody(for: verse, isArabic: false)

            XCTAssertTrue(body.contains(verse.englishText))
            XCTAssertTrue(body.contains(verse.englishReference))
            XCTAssertFalse(body.contains(verse.arabicText))
        }
    }

    func testBodiesOfDifferentVersesNeverCollide() {
        let arabicBodies = verses.map { PrayerNotificationContentCatalog.localizedBody(for: $0, isArabic: true) }
        let englishBodies = verses.map { PrayerNotificationContentCatalog.localizedBody(for: $0, isArabic: false) }

        XCTAssertEqual(Set(arabicBodies).count, verses.count)
        XCTAssertEqual(Set(englishBodies).count, verses.count)
    }

    // MARK: - Drafts

    func testAdhanDraftCarriesTheSlotTitleTheAdhanSubtitleAndACatalogBody() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              preferences: PrayerNotificationFixture.preferences(slots: [.fajr]))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let draft = center.addedDrafts.first { PrayerNotificationIdentifier.kind(of: $0.identifier) == .adhan }

        XCTAssertNotNil(draft)
        XCTAssertEqual(draft?.title, PrayerSlot.fajr.localizedName)
        XCTAssertEqual(draft?.subtitle, AppLocalizedKeys.prayerNotificationAdhanSubtitle.value)
        XCTAssertEqual(draft?.body, draft.flatMap { expectedBody(for: $0.identifier) })
        XCTAssertNotEqual(draft?.body, AppLocalizedKeys.prayerNotificationsTestBody.value)
    }

    func testReminderDraftKeepsTheLeadMinutesInTheSubtitle() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              preferences: PrayerNotificationFixture.preferences(slots: [.fajr],
                                                                                 isReminderEnabled: true,
                                                                                 leadMinutes: 25))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let draft = center.addedDrafts.first { PrayerNotificationIdentifier.kind(of: $0.identifier) == .reminder }
        let minutes = isArabic ? 25.arabicNumerals : "25"

        XCTAssertNotNil(draft)
        XCTAssertEqual(draft?.title, PrayerSlot.fajr.localizedName)
        XCTAssertTrue(draft?.subtitle?.contains(minutes) ?? false)
        XCTAssertEqual(draft?.body, draft.flatMap { expectedBody(for: $0.identifier) })
    }

    func testEveryDraftOfTheSameDayCarriesADistinctBody() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              preferences: PrayerNotificationFixture.preferences(isReminderEnabled: true))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let grouped = Dictionary(grouping: center.addedDrafts) { dayKey(of: $0.identifier) ?? "" }

        XCTAssertFalse(grouped.isEmpty)

        for (dayKey, drafts) in grouped {
            let bodies = drafts.map(\.body)

            XCTAssertEqual(Set(bodies).count, bodies.count, "\(dayKey) repeats a body")
            XCTAssertTrue(bodies.allSatisfy { !$0.isEmpty })
        }
    }

    func testReschedulingReproducesTheSameBodies() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              preferences: PrayerNotificationFixture.preferences(isReminderEnabled: true))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let first = center.addedDrafts.reduce(into: [String: String]()) { $0[$1.identifier] = $1.body }
        center.resetLog()

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let second = center.addedDrafts.reduce(into: [String: String]()) { $0[$1.identifier] = $1.body }

        XCTAssertFalse(first.isEmpty)
        XCTAssertEqual(first, second)
    }

    func testDraftsCarryContentForEveryEnabledPrayer() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let slots = Set(PrayerSlot.obligatorySlots).union([.duha, .jumuah])
        let subject = manager(center: center,
                              preferences: PrayerNotificationFixture.preferences(slots: slots,
                                                                                 isReminderEnabled: true))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let covered = Set(center.addedDrafts.compactMap { PrayerNotificationIdentifier.slot(of: $0.identifier) })

        XCTAssertEqual(covered, slots)

        for draft in center.addedDrafts {
            XCTAssertEqual(draft.body, expectedBody(for: draft.identifier))
            XCTAssertFalse(draft.title.isEmpty)
            XCTAssertFalse(draft.subtitle?.isEmpty ?? true)
        }
    }

    func testFridayJumuahDraftSupersedesDhuhrAndKeepsItsOwnContent() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              preferences: PrayerNotificationFixture.preferences(slots: [.dhuhr, .jumuah]))

        await subject.reschedule(day: PrayerNotificationFixture.day())
        let friday = center.addedDrafts.filter {
            dayKey(of: $0.identifier) == PrayerNotificationFixture.nextFridayDayKey
        }

        XCTAssertEqual(friday.count, 1)
        XCTAssertEqual(friday.first.flatMap { PrayerNotificationIdentifier.slot(of: $0.identifier) }, .jumuah)
        XCTAssertEqual(friday.first?.title, PrayerSlot.jumuah.localizedName)
        XCTAssertEqual(friday.first?.body, friday.first.flatMap { expectedBody(for: $0.identifier) })
    }

    func testLanguageDrivesTheGeneratedBody() async {
        let localization = LocalizationManager.shared
        let original = localization.currentLanguage
        defer { localization.currentLanguage = original }

        var bodies: [LocalizationManager.Language: String] = [:]

        for language in [LocalizationManager.Language.Arabic, .English] {
            localization.currentLanguage = language
            let center = LocalNotificationCenterDouble(status: .authorized)
            let subject = manager(center: center,
                                  preferences: PrayerNotificationFixture.preferences(slots: [.fajr]))

            await subject.reschedule(day: PrayerNotificationFixture.day())
            bodies[language] = center.addedDrafts.first?.body
        }

        let arabic = bodies[.Arabic]
        let english = bodies[.English]

        XCTAssertNotNil(arabic)
        XCTAssertNotNil(english)
        XCTAssertNotEqual(arabic, english)
        XCTAssertTrue(arabic?.hasPrefix("\u{FD3E}") ?? false)
        XCTAssertFalse(english?.hasPrefix("\u{FD3E}") ?? true)
    }
}
