//
//  PrayerNotificationTestDoubles.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 30/10/2026.
//

import Foundation
import Core
@testable import QuranApp

// MARK: - Fixtures

enum PrayerNotificationFixture {

    static let timeZoneIdentifier = "Asia/Riyadh"

    static let fajrMinutes = 300
    static let sunriseMinutes = 380
    static let dhuhrMinutes = 710
    static let asrMinutes = 910
    static let sunsetMinutes = 1050
    static let maghribMinutes = 1055
    static let ishaMinutes = 1145
    static let midnightMinutes = 1425
    static let lastThirdMinutes = 180

    static let fridayDayKey = "2026-10-30"
    static let mondayDayKey = "2026-11-02"
    static let tuesdayDayKey = "2026-11-03"
    static let nextFridayDayKey = "2026-11-06"

    static var calendar: Calendar { DayPrayerTimes.calendar(for: PrayerNotificationFixture.timeZoneIdentifier) }

    static func day(dayKey: String = PrayerNotificationFixture.mondayDayKey) -> DayPrayerTimes {
        DayPrayerTimes(dayKey: dayKey,
                       fajr: PrayerNotificationFixture.fajrMinutes,
                       sunrise: PrayerNotificationFixture.sunriseMinutes,
                       dhuhr: PrayerNotificationFixture.dhuhrMinutes,
                       asr: PrayerNotificationFixture.asrMinutes,
                       sunset: PrayerNotificationFixture.sunsetMinutes,
                       maghrib: PrayerNotificationFixture.maghribMinutes,
                       isha: PrayerNotificationFixture.ishaMinutes,
                       midnight: PrayerNotificationFixture.midnightMinutes,
                       lastThird: PrayerNotificationFixture.lastThirdMinutes,
                       timeZoneIdentifier: PrayerNotificationFixture.timeZoneIdentifier,
                       calculationMethodId: PrayerCalculationMethod.default.rawValue,
                       calculationMethodName: "Umm Al-Qura University, Makkah")
    }

    static func date(dayKey: String, minutesSinceMidnight: Int) -> Date {
        let calendar = PrayerNotificationFixture.calendar
        guard let anchor = DayPrayerTimes.date(fromDayKey: dayKey, calendar: calendar),
              let shifted = calendar.date(byAdding: .minute,
                                          value: minutesSinceMidnight,
                                          to: calendar.startOfDay(for: anchor))
        else { return Date() }
        return shifted
    }

    static func weekday(ofDayKey dayKey: String) -> Int {
        let calendar = PrayerNotificationFixture.calendar
        guard let anchor = DayPrayerTimes.date(fromDayKey: dayKey, calendar: calendar) else { return 0 }
        return calendar.component(.weekday, from: anchor)
    }

    static func preferences(isEnabled: Bool = true,
                            slots: Set<PrayerSlot> = PrayerSlot.defaultEnabledSlots,
                            alertStyle: PrayerNotificationAlertStyle = .standardTone,
                            isReminderEnabled: Bool = false,
                            leadMinutes: Int = PrayerNotificationPreferences.defaultReminderLeadMinutes,
                            isInAppAdhanEnabled: Bool = false,
                            method: PrayerCalculationMethod = .default,
                            school: PrayerJurisprudenceSchool = .default) -> PrayerNotificationPreferences {
        PrayerNotificationPreferences(isPrayerNotificationEnabled: isEnabled,
                                      enabledSlots: slots,
                                      alertStyle: alertStyle,
                                      isPrePrayerReminderEnabled: isReminderEnabled,
                                      prePrayerReminderLeadMinutes: leadMinutes,
                                      isInAppAdhanAudioEnabled: isInAppAdhanEnabled,
                                      calculationMethod: method,
                                      jurisprudenceSchool: school)
    }

    static func defaults(_ name: String = UUID().uuidString) -> UserDefaults {
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    static func soundCatalog() -> PrayerNotificationSoundCatalog {
        PrayerNotificationSoundCatalog(bundle: Bundle(for: LocalNotificationCenterDouble.self))
    }
}

// MARK: - Clock

final class LocalNotificationClockDouble: LocalNotificationClock {

    var currentDate: Date

    init(currentDate: Date) {
        self.currentDate = currentDate
    }
}

// MARK: - Notification Center

@MainActor
final class LocalNotificationCenterDouble: NSObject, LocalNotificationCenter {

    var status: LocalNotificationAuthorizationStatus
    var statusAfterRequest: LocalNotificationAuthorizationStatus

    private(set) var authorizationRequestCount = 0
    private(set) var statusReadCount = 0
    private(set) var removalBatches: [[String]] = []
    private(set) var addedDrafts: [LocalNotificationRequestDraft] = []
    private(set) var pending: [LocalNotificationRequestDraft] = []

    init(status: LocalNotificationAuthorizationStatus = .authorized,
         statusAfterRequest: LocalNotificationAuthorizationStatus = .authorized) {
        self.status = status
        self.statusAfterRequest = statusAfterRequest
        super.init()
    }

    func currentAuthorizationStatus() async -> LocalNotificationAuthorizationStatus {
        statusReadCount += 1
        return status
    }

    func requestAuthorization() async -> LocalNotificationAuthorizationStatus {
        authorizationRequestCount += 1
        status = statusAfterRequest
        return status
    }

    func pendingRequestIdentifiers() async -> [String] {
        pending.map(\.identifier)
    }

    func removeRequests(withIdentifiers identifiers: [String]) {
        removalBatches.append(identifiers)
        pending.removeAll { identifiers.contains($0.identifier) }
    }

    func add(_ draft: LocalNotificationRequestDraft) async {
        addedDrafts.append(draft)
        pending.removeAll { $0.identifier == draft.identifier }
        pending.append(draft)
    }
}

// MARK: - Center Inspection

extension LocalNotificationCenterDouble {

    var pendingIdentifiers: [String] { pending.map(\.identifier) }

    var ownedIdentifiers: [String] { pendingIdentifiers.filter(PrayerNotificationIdentifier.isOwned) }

    var foreignIdentifiers: [String] { pendingIdentifiers.filter { !PrayerNotificationIdentifier.isOwned($0) } }

    var removedIdentifiers: [String] { removalBatches.flatMap { $0 } }

    func seedForeignRequest(identifier: String) {
        pending.append(LocalNotificationRequestDraft(identifier: identifier,
                                                      title: "",
                                                      body: "",
                                                      soundFileName: nil,
                                                      dateComponents: DateComponents()))
    }

    func seedOwnedRequest(dayKey: String, slot: PrayerSlot, kind: PrayerNotificationKind) {
        let identifier = PrayerNotificationIdentifier.identifier(dayKey: dayKey, slot: slot, kind: kind)
        pending.append(LocalNotificationRequestDraft(identifier: identifier,
                                                      title: "",
                                                      body: "",
                                                      soundFileName: nil,
                                                      dateComponents: DateComponents()))
    }

    func resetLog() {
        addedDrafts = []
        removalBatches = []
    }
}

// MARK: - Manager Assembly

@MainActor
enum PrayerNotificationManagerBuilder {

    static func manager(center: LocalNotificationCenterDouble,
                        defaults: UserDefaults,
                        preferences: PrayerNotificationPreferences,
                        now: Date) -> PrayerNotificationManager {
        let preferencesStore = PrayerNotificationPreferencesStore(defaults: defaults)
        preferencesStore.save(preferences)
        return PrayerNotificationManager(center: center,
                                         preferencesStore: preferencesStore,
                                         clock: LocalNotificationClockDouble(currentDate: now),
                                         soundCatalog: PrayerNotificationFixture.soundCatalog())
    }
}

// MARK: - Async Waiting

@MainActor
enum PrayerNotificationWait {

    static func until(_ condition: () -> Bool) async {
        for _ in 0..<5_000 {
            if condition() { return }
            await Task.yield()
        }
    }
}
