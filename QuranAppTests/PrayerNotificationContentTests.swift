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

    private static let pinnedSlotBindings: [String: Set<PrayerSlot>] = [
        "hadith_two_cool_prayers": [.fajr, .asr],
        "hadith_angels_gather": [.fajr, .asr],
        "hadith_isha_fajr_congregation": [.fajr, .isha],
        "hadith_fajr_sunnah_rakahs": [.fajr],
        "hadith_two_rakahs_before_maghrib": [.maghrib],
        "hadith_best_day_friday": [.jumuah],
        "hadith_ten_verses_al_kahf": [.surahAlKahf],
        "hadith_descent_last_third": [.lastThirdOfNight],
        "hadith_duha_rakahs": [.duha, .sunrise],
        "dhikr_morning_remembrance": [.sunrise],
        "dhikr_evening_remembrance": [.maghrib],
        "quran_al_isra_78": [.fajr],
        "quran_al_isra_79": [.lastThirdOfNight],
        "quran_adh_dhariyat_18": [.lastThirdOfNight],
        "quran_al_jumuah_9": [.jumuah],
        "quran_al_kahf_1": [.surahAlKahf],
        "quran_taha_130": [.sunrise]
    ]

    private let items = PrayerNotificationContentCatalog.items
    private let dayKey = PrayerNotificationFixture.mondayDayKey

    private var now: Date {
        PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey, minutesSinceMidnight: 30)
    }

    private var isArabic: Bool {
        LocalizationManager.shared.currentLanguage == .Arabic
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

    private func content(of identifier: String) -> PrayerNotificationContent? {
        guard let dayKey = dayKey(of: identifier),
              let slot = PrayerNotificationIdentifier.slot(of: identifier),
              let kind = PrayerNotificationIdentifier.kind(of: identifier)
        else { return nil }

        return PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind)
    }

    private func expectedBody(for identifier: String) -> String? {
        guard let content = content(of: identifier) else { return nil }

        return PrayerNotificationContentCatalog.body(for: content)
    }

    private func corpusKey(forReference reference: String) -> String? {
        guard let numbers = reference.components(separatedBy: " ").last else { return nil }
        let parts = numbers.components(separatedBy: ":")
        guard parts.count == 2, Int(parts[0]) != nil, Int(parts[1]) != nil else { return nil }

        return "\(parts[0])_\(parts[1])"
    }

    private func dayKeys(count: Int, from startDayKey: String) -> [String] {
        let calendar = PrayerNotificationFixture.calendar
        let start = PrayerNotificationFixture.date(dayKey: startDayKey, minutesSinceMidnight: 0)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"

        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start).map(formatter.string(from:))
        }
    }

    private func dedicatedItems(for slot: PrayerSlot) -> [PrayerNotificationContent] {
        items.filter { item in
            guard item.prayerSlots.contains(slot) else { return false }

            return item.prayerSlots.allSatisfy(\.requiresDedicatedContent)
        }
    }

    private func restrictedKinds(for slot: PrayerSlot) -> [PrayerNotificationKind] {
        slot.scheduledKinds.filter {
            PrayerNotificationContentSelector.requiresSlotSpecificContent(slot: slot, kind: $0)
        }
    }

    // MARK: - Catalog Integrity

    func testCatalogHasUniqueIdentifiers() {
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
        XCTAssertFalse(items.isEmpty)
    }

    func testEveryItemCarriesBothLanguagesForTitleAndText() {
        for item in items {
            XCTAssertFalse(item.arabicTitle.trimmingCharacters(in: .whitespaces).isEmpty, item.id)
            XCTAssertFalse(item.englishTitle.trimmingCharacters(in: .whitespaces).isEmpty, item.id)
            XCTAssertFalse(item.arabicText.trimmingCharacters(in: .whitespaces).isEmpty, item.id)
        }
    }

    func testArabicFieldsCarryNoLatinLettersAndEnglishFieldsCarryNoArabic() {
        let latin = CharacterSet(charactersIn: "A"..."Z").union(CharacterSet(charactersIn: "a"..."z"))
        let arabic = CharacterSet(charactersIn: UnicodeScalar(0x0600)!...UnicodeScalar(0x06FF)!)

        for item in items {
            for field in [item.arabicTitle, item.arabicText, item.arabicSource] {
                XCTAssertNil(field.rangeOfCharacter(from: latin), "\(item.id): \(field)")
            }

            for field in [item.englishTitle, item.reference] {
                XCTAssertNil(field.rangeOfCharacter(from: arabic), "\(item.id): \(field)")
            }
        }
    }

    func testEveryItemIsSuitableForAtLeastOneKind() {
        for item in items {
            XCTAssertFalse(item.suitableKinds.isEmpty, item.id)
        }
    }

    // MARK: - Source Preservation

    func testNarrationsAlwaysCarryACollectionSource() {
        let narrations = items.filter { $0.type.carriesNarrationSource && $0.authenticity.isNarrationGrading }
        XCTAssertFalse(narrations.isEmpty)

        for item in narrations {
            XCTAssertFalse(item.arabicSource.isEmpty, item.id)
            XCTAssertFalse(item.reference.isEmpty, item.id)
            let attributed = item.reference.contains("al-Bukhari") || item.reference.contains("Muslim")
            XCTAssertTrue(attributed, "\(item.id) is graded as a narration but names no collection")
        }
    }

    func testAppRemindersCarryNoNarrationSource() {
        let reminders = items.filter { $0.authenticity == .appReminder }
        XCTAssertFalse(reminders.isEmpty)

        for item in reminders {
            XCTAssertEqual(item.type, .reminder, item.id)
            XCTAssertTrue(item.arabicSource.isEmpty, item.id)
            XCTAssertTrue(item.reference.isEmpty, item.id)
        }
    }

    func testEveryQuranItemIsGradedAsQuranicTextAndNamesItsReference() {
        let verses = items.filter { $0.type == .quran }
        XCTAssertFalse(verses.isEmpty)

        for item in verses {
            XCTAssertEqual(item.authenticity, .quranicText, item.id)
            XCTAssertNotNil(corpusKey(forReference: item.reference),
                            "\(item.id) source is not a surah:ayah reference: \(item.reference)")
            XCTAssertFalse(item.arabicSource.isEmpty, item.id)
        }
    }

    func testNoNarrationIsGradedAsQuranicTextAndNoVerseIsGradedAsANarration() {
        for item in items {
            switch item.type {
            case .quran:
                XCTAssertFalse(item.authenticity.isNarrationGrading, item.id)
            case .hadith, .dhikr:
                XCTAssertTrue(item.authenticity.isNarrationGrading, item.id)
            case .dua, .reminder:
                break
            }
        }
    }

    // MARK: - Quranic Verse Exactness

    func testCorpusIsAvailableForVerification() {
        XCTAssertEqual(Self.corpus.count, 6236)
    }

    func testEveryQuranicTextMatchesTheBundledCorpusExactly() {
        let quranic = items.filter { $0.authenticity == .quranicText }
        XCTAssertFalse(quranic.isEmpty)

        for item in quranic {
            guard let key = corpusKey(forReference: item.reference) else {
                XCTFail("\(item.id) has no parsable reference")
                continue
            }

            guard let verse = Self.corpus[key]?
                .replacingOccurrences(of: "\u{FEFF}", with: "")
                .trimmingCharacters(in: .whitespaces)
            else {
                XCTFail("\(item.id) references a verse missing from the corpus: \(key)")
                continue
            }

            XCTAssertTrue(verse.contains(item.arabicText),
                          "\(item.id) text is not an exact excerpt of \(key)")
        }
    }

    func testTheMiddlePrayerVerseIsNotUsedAnywhereInTheCatalog() {
        guard let middlePrayerVerse = Self.corpus["2_238"]?
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .trimmingCharacters(in: .whitespaces)
        else { return XCTFail("corpus is missing 2:238") }

        for item in items {
            XCTAssertFalse(middlePrayerVerse.contains(item.arabicText),
                           "\(item.id) quotes Al-Baqarah 2:238")
            XCTAssertFalse(item.reference.hasSuffix("2:238"), item.id)
        }
    }

    // MARK: - Contextual Binding

    func testSlotBindingsMatchThePinnedAllowList() {
        let bound = items.filter { !$0.isGeneral }
        XCTAssertEqual(bound.count, Self.pinnedSlotBindings.count)

        for item in bound {
            XCTAssertEqual(item.prayerSlots,
                           Self.pinnedSlotBindings[item.id],
                           "\(item.id) is bound to an unreviewed set of prayers")
        }
    }

    func testGeneralItemsStayUnboundToAnyPrayer() {
        let general = items.filter(\.isGeneral)
        XCTAssertFalse(general.isEmpty)

        for item in general {
            XCTAssertTrue(item.prayerSlots.isEmpty, item.id)
            XCTAssertNil(Self.pinnedSlotBindings[item.id], item.id)
        }
    }

    func testEverySlotAndKindResolvesContent() {
        for slot in PrayerSlot.allCases {
            for kind in slot.scheduledKinds {
                XCTAssertNotNil(PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind),
                                "\(slot.rawValue).\(kind.rawValue)")
            }
        }
    }

    func testSlotPoolsOnlyOfferContentBoundToThatSlotOrGeneralContent() {
        for slot in PrayerSlot.allCases {
            for kind in PrayerNotificationKind.allCases {
                for item in PrayerNotificationContentSelector.pool(slot: slot, kind: kind) {
                    XCTAssertTrue(item.isGeneral || item.prayerSlots.contains(slot),
                                  "\(item.id) offered for \(slot.rawValue)")
                }
            }
        }
    }

    func testSupplementalAndFridaySlotsNeverDrawGeneralContent() {
        let restricted = PrayerSlot.allCases.filter(\.requiresDedicatedContent)
        XCTAssertFalse(restricted.isEmpty)

        for slot in restricted {
            for kind in restrictedKinds(for: slot) {
                let pool = PrayerNotificationContentSelector.pool(slot: slot, kind: kind)
                XCTAssertFalse(pool.isEmpty, "\(slot.rawValue).\(kind.rawValue)")

                for item in pool {
                    XCTAssertTrue(item.prayerSlots.contains(slot),
                                  "\(item.id) is general content offered for \(slot.rawValue)")
                }
            }
        }
    }

    func testRestrictedSlotsOwnEnoughDedicatedContentForEveryKind() {
        let restricted = PrayerSlot.allCases.filter(\.requiresDedicatedContent)

        for slot in restricted {
            let kinds = restrictedKinds(for: slot)

            for kind in kinds {
                let dedicated = dedicatedItems(for: slot).filter { $0.suits(kind: kind) }
                XCTAssertGreaterThanOrEqual(dedicated.count,
                                            kinds.count,
                                            "\(slot.rawValue) cannot fill \(kind.rawValue) without reuse")
            }
        }
    }

    func testPrayersWithoutDedicatedContentFallBackToTheGeneralPool() {
        let dhuhrPool = PrayerNotificationContentSelector.pool(slot: .dhuhr, kind: .adhan)
        XCTAssertFalse(dhuhrPool.isEmpty)
        XCTAssertTrue(dhuhrPool.allSatisfy(\.isGeneral))
    }

    // MARK: - Before Versus At Prayer

    func testKindRestrictedContentNeverReachesTheOtherKind() {
        for kind in PrayerNotificationKind.allCases {
            for slot in PrayerSlot.allCases {
                for item in PrayerNotificationContentSelector.pool(slot: slot, kind: kind) {
                    XCTAssertTrue(item.suits(kind: kind), "\(item.id) offered for \(kind.rawValue)")
                }
            }
        }
    }

    func testTheAdhanResponseSupplicationIsNeverOfferedBeforeThePrayer() {
        for slot in PrayerSlot.allCases {
            let ids = PrayerNotificationContentSelector.pool(slot: slot, kind: .reminder).map(\.id)
            XCTAssertFalse(ids.contains("dua_after_adhan"), slot.rawValue)
        }
    }

    func testPreparationContentIsNeverOfferedAtThePrayerTime() {
        let preparationOnly = ["hadith_fajr_sunnah_rakahs", "hadith_two_rakahs_before_maghrib"]

        for slot in PrayerSlot.allCases {
            let ids = PrayerNotificationContentSelector.pool(slot: slot, kind: .adhan).map(\.id)

            for identifier in preparationOnly {
                XCTAssertFalse(ids.contains(identifier), "\(identifier) offered at \(slot.rawValue)")
            }
        }
    }

    func testBeforeAndAtPrayerContentDifferForTheSamePrayer() {
        for slot in PrayerSlot.obligatorySlots {
            let reminder = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: .reminder)
            let adhan = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: .adhan)
            XCTAssertNotEqual(reminder?.id, adhan?.id, slot.rawValue)
        }
    }

    // MARK: - Repetition

    func testOneDayNeverRepeatsTheSameItem() {
        for dayKey in dayKeys(count: 60, from: PrayerNotificationFixture.mondayDayKey) {
            let assignment = PrayerNotificationContentSelector.shared.dailyAssignment(dayKey: dayKey)
            let identifiers = assignment.values.map(\.id)
            XCTAssertEqual(Set(identifiers).count, identifiers.count, dayKey)
        }
    }

    func testConsecutiveDaysRotateContentForEveryPrayer() {
        let keys = dayKeys(count: 121, from: PrayerNotificationFixture.mondayDayKey)

        for slot in PrayerSlot.obligatorySlots {
            for kind in PrayerNotificationKind.allCases {
                for (first, second) in zip(keys, keys.dropFirst()) {
                    let earlier = PrayerNotificationContentCatalog.content(dayKey: first, slot: slot, kind: kind)
                    let later = PrayerNotificationContentCatalog.content(dayKey: second, slot: slot, kind: kind)
                    XCTAssertNotEqual(earlier?.id, later?.id, "\(slot.rawValue).\(kind.rawValue) \(first)->\(second)")
                }
            }
        }
    }

    func testRotationReachesSeveralItemsOverAMonth() {
        for slot in PrayerSlot.obligatorySlots {
            let identifiers = dayKeys(count: 30, from: PrayerNotificationFixture.mondayDayKey).compactMap {
                PrayerNotificationContentCatalog.content(dayKey: $0, slot: slot, kind: .adhan)?.id
            }
            XCTAssertGreaterThanOrEqual(Set(identifiers).count, 3, slot.rawValue)
        }
    }

    // MARK: - Determinism

    func testSelectionIsStableAcrossRepeatedCalls() {
        for slot in PrayerSlot.allCases {
            for kind in PrayerNotificationKind.allCases {
                let first = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind)
                let second = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind)
                let third = PrayerNotificationContentCatalog.content(dayKey: dayKey, slot: slot, kind: kind)
                XCTAssertEqual(first, second)
                XCTAssertEqual(second, third)
            }
        }
    }

    func testMalformedDayKeysStillResolveContent() {
        for malformed in ["", "not-a-date", "2026-13-99", "2026"] {
            for kind in PrayerNotificationKind.allCases {
                XCTAssertNotNil(PrayerNotificationContentCatalog.content(dayKey: malformed, slot: .fajr, kind: kind),
                                malformed)
            }
        }
    }

    // MARK: - Seeded Randomness

    func testTheSameSeedReproducesIdenticalAssignments() {
        let first = PrayerNotificationContentSelector(seed: 1_234_567)
        let second = PrayerNotificationContentSelector(seed: 1_234_567)

        for dayKey in dayKeys(count: 30, from: PrayerNotificationFixture.mondayDayKey) {
            for slot in PrayerSlot.allCases {
                for kind in PrayerNotificationKind.allCases {
                    XCTAssertEqual(first.content(dayKey: dayKey, slot: slot, kind: kind),
                                   second.content(dayKey: dayKey, slot: slot, kind: kind),
                                   "\(dayKey).\(slot.rawValue).\(kind.rawValue)")
                }
            }
        }
    }

    func testDifferentSeedsProduceDifferentAssignments() {
        let first = PrayerNotificationContentSelector(seed: 1_234_567)
        let second = PrayerNotificationContentSelector(seed: 7_654_321)
        var differences = 0

        for dayKey in dayKeys(count: 30, from: PrayerNotificationFixture.mondayDayKey) {
            for slot in PrayerSlot.obligatorySlots {
                for kind in PrayerNotificationKind.allCases {
                    let earlier = first.content(dayKey: dayKey, slot: slot, kind: kind)?.id
                    let later = second.content(dayKey: dayKey, slot: slot, kind: kind)?.id

                    if earlier != later { differences += 1 }
                }
            }
        }

        XCTAssertGreaterThan(differences, 100)
    }

    func testTheStoredSeedStaysStableAcrossReads() {
        let defaults = PrayerNotificationFixture.defaults()
        let store = PrayerNotificationContentSeedStore(defaults: defaults)
        let seed = store.resolvedSeed()

        XCTAssertNotEqual(seed, 0)
        XCTAssertEqual(seed, store.resolvedSeed())
        XCTAssertEqual(seed, PrayerNotificationContentSeedStore(defaults: defaults).resolvedSeed())
    }

    func testFreshInstallsDrawSeparateSeeds() {
        let seeds = (0 ..< 8).map { _ in
            PrayerNotificationContentSeedStore(defaults: PrayerNotificationFixture.defaults()).resolvedSeed()
        }

        XCTAssertGreaterThan(Set(seeds).count, 1)
    }

    func testEveryDayOfTheRotationCycleCoversEveryObligatorySlotAndKind() {
        let subject = PrayerNotificationContentSelector(seed: 42)
        let keys = dayKeys(count: PrayerNotificationContentSelector.rotationCycleInDays,
                           from: PrayerNotificationFixture.mondayDayKey)

        for dayKey in keys {
            for slot in PrayerSlot.obligatorySlots {
                for kind in PrayerNotificationKind.allCases {
                    XCTAssertNotNil(subject.content(dayKey: dayKey, slot: slot, kind: kind),
                                    "\(dayKey).\(slot.rawValue).\(kind.rawValue)")
                }
            }
        }
    }

    // MARK: - Presentation

    func testBodyCombinesTheQuotedTextWithItsSource() {
        for item in items {
            let body = item.notificationBody
            XCTAssertTrue(body.contains(item.arabicText), item.id)

            if item.arabicSource.isEmpty {
                XCTAssertEqual(body.components(separatedBy: "\n").count, 1, item.id)
            } else {
                XCTAssertTrue(body.hasSuffix(item.arabicSource), item.id)
            }
        }
    }

    func testQuotationMarksFollowTheContentType() {
        for item in items {
            let body = item.notificationBody

            switch item.type {
            case .quran:
                XCTAssertTrue(body.hasPrefix("\u{FD3E}"), item.id)
            case .hadith, .dua, .dhikr:
                XCTAssertTrue(body.hasPrefix("\u{00AB}"), item.id)
            case .reminder:
                XCTAssertTrue(body.hasPrefix(item.arabicText), item.id)
            }
        }
    }

    func testNoRenderedBodyExceedsTheMaximumTextLength() {
        for item in items {
            XCTAssertLessThanOrEqual(item.notificationBody.count,
                                     PrayerNotificationContent.maximumTextLength,
                                     item.id)
        }
    }

    func testNoRenderedBodyCarriesLatinLetters() {
        let latin = CharacterSet(charactersIn: "A"..."Z").union(CharacterSet(charactersIn: "a"..."z"))

        for item in items {
            XCTAssertNil(item.notificationBody.rangeOfCharacter(from: latin),
                         "\(item.id): \(item.notificationBody)")
        }
    }

    func testLanguageSelectionDrivesTheTitleAndLeavesTheBodyUntranslated() {
        for item in items {
            XCTAssertEqual(item.localizedTitle(isArabic: true), item.arabicTitle, item.id)
            XCTAssertEqual(item.localizedTitle(isArabic: false), item.englishTitle, item.id)
            XCTAssertTrue(item.notificationBody.contains(item.arabicText), item.id)
        }
    }

    func testAuthenticityLabelsAreLocalizedInBothLanguages() {
        for authenticity in PrayerNotificationContentAuthenticity.allCases {
            XCTAssertFalse(authenticity.arabicLabel.isEmpty, authenticity.rawValue)
            XCTAssertFalse(authenticity.englishLabel.isEmpty, authenticity.rawValue)
        }
    }

    // MARK: - Scheduled Drafts

    func testAdhanDraftNamesThePrayerInTheTitleAndCarriesTheContentInTheBody() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center, preferences: PrayerNotificationFixture.preferences(slots: [.fajr]))

        await subject.reschedule(day: PrayerNotificationFixture.day())

        let identifier = PrayerNotificationIdentifier.identifier(dayKey: dayKey, slot: .fajr, kind: .adhan)
        let draft = center.addedDrafts.first { $0.identifier == identifier }
        let content = content(of: identifier)

        XCTAssertNotNil(content)
        XCTAssertEqual(draft?.title, PrayerSlot.fajr.localizedName)
        XCTAssertNil(draft?.subtitle)
        XCTAssertEqual(draft?.body, expectedBody(for: identifier))
    }

    func testReminderDraftNamesThePrayerWithoutTheLeadMinutesInTheTitle() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let preferences = PrayerNotificationFixture.preferences(slots: [.dhuhr],
                                                                isReminderEnabled: true,
                                                                leadMinutes: 20)
        let subject = manager(center: center, preferences: preferences)

        await subject.reschedule(day: PrayerNotificationFixture.day())

        let identifier = PrayerNotificationIdentifier.identifier(dayKey: dayKey, slot: .dhuhr, kind: .reminder)
        let draft = center.addedDrafts.first { $0.identifier == identifier }

        XCTAssertEqual(draft?.title, PrayerSlot.dhuhr.localizedName)
        XCTAssertNil(draft?.subtitle)
        XCTAssertFalse(draft?.title.contains(isArabic ? 20.arabicNumerals : "20") == true)
        XCTAssertEqual(draft?.body, expectedBody(for: identifier))
    }

    func testSupplementalDraftNamesItsOccasionInTheTitle() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let subject = manager(center: center,
                              preferences: PrayerNotificationFixture.preferences(slots: [.lastThirdOfNight]))

        await subject.reschedule(day: PrayerNotificationFixture.day())

        let identifier = PrayerNotificationIdentifier.identifier(dayKey: dayKey,
                                                                 slot: .lastThirdOfNight,
                                                                 kind: .reminder)
        let draft = center.addedDrafts.first { $0.identifier == identifier }

        XCTAssertEqual(draft?.title, PrayerSlot.lastThirdOfNight.localizedName)
        XCTAssertNil(draft?.subtitle)
        XCTAssertEqual(draft?.body, expectedBody(for: identifier))
    }

    func testFridayJumuahDraftSupersedesDhuhrAndKeepsItsOwnContent() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let fridayKey = PrayerNotificationFixture.nextFridayDayKey
        let preferences = PrayerNotificationFixture.preferences(slots: [.dhuhr, .jumuah])
        let subject = manager(center: center, preferences: preferences)

        await subject.reschedule(day: PrayerNotificationFixture.day(dayKey: fridayKey))

        let jumuah = PrayerNotificationIdentifier.identifier(dayKey: fridayKey, slot: .jumuah, kind: .adhan)
        let dhuhr = PrayerNotificationIdentifier.identifier(dayKey: fridayKey, slot: .dhuhr, kind: .adhan)

        XCTAssertNotNil(center.addedDrafts.first { $0.identifier == jumuah })
        XCTAssertNil(center.addedDrafts.first { $0.identifier == dhuhr })

        let draft = center.addedDrafts.first { $0.identifier == jumuah }
        XCTAssertEqual(draft?.body, expectedBody(for: jumuah))
        XCTAssertEqual(content(of: jumuah)?.prayerSlots, [.jumuah])
    }

    func testEveryScheduledDraftOfADayCarriesADistinctBody() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let preferences = PrayerNotificationFixture.preferences(slots: Set(PrayerSlot.obligatorySlots),
                                                                isReminderEnabled: true)
        let subject = manager(center: center, preferences: preferences)

        await subject.reschedule(day: PrayerNotificationFixture.day())

        let grouped = Dictionary(grouping: center.addedDrafts.filter { dayKey(of: $0.identifier) != nil }) {
            dayKey(of: $0.identifier)!
        }
        XCTAssertFalse(grouped.isEmpty)

        for (dayKey, drafts) in grouped {
            let bodies = drafts.map(\.body)
            XCTAssertEqual(Set(bodies).count, bodies.count, dayKey)
        }
    }

    func testEveryScheduledDraftCarriesACatalogBody() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let preferences = PrayerNotificationFixture.preferences(slots: Set(PrayerSlot.allCases),
                                                                isReminderEnabled: true)
        let subject = manager(center: center, preferences: preferences)

        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertFalse(center.addedDrafts.isEmpty)

        for draft in center.addedDrafts {
            XCTAssertEqual(draft.body, expectedBody(for: draft.identifier), draft.identifier)
            XCTAssertFalse(draft.body.isEmpty, draft.identifier)
            XCTAssertFalse(draft.title.isEmpty, draft.identifier)
        }
    }

    // MARK: - Rescheduling

    func testReschedulingKeepsIdenticalContentAndAddsNoDuplicates() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let preferences = PrayerNotificationFixture.preferences(slots: Set(PrayerSlot.obligatorySlots),
                                                                isReminderEnabled: true)
        let subject = manager(center: center, preferences: preferences)

        await subject.reschedule(day: PrayerNotificationFixture.day())
        var first: [String: String] = [:]
        center.addedDrafts.forEach { first[$0.identifier] = $0.body }

        center.resetLog()
        await subject.reschedule(day: PrayerNotificationFixture.day())
        var second: [String: String] = [:]
        center.addedDrafts.forEach { second[$0.identifier] = $0.body }

        XCTAssertFalse(first.isEmpty)
        XCTAssertEqual(first, second)

        let identifiers = center.addedDrafts.map(\.identifier)
        XCTAssertEqual(Set(identifiers).count, identifiers.count)
    }
}
