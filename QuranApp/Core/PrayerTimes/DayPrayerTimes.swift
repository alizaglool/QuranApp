//
//  DayPrayerTimes.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation
import Core

/// One day's prayer anchors, each stored as minutes since local midnight.
///
/// Minutes rather than `Date` for two reasons: the value survives a
/// `UserDefaults` round trip unchanged, and a window that crosses midnight
/// becomes a plain wrap-around comparison instead of date arithmetic.
struct DayPrayerTimes: Codable, Equatable {

    /// The local calendar day these anchors belong to, `yyyy-MM-dd`.
    let dayKey: String

    let fajr: Int
    let sunrise: Int
    let dhuhr: Int
    let asr: Int
    let sunset: Int
    let maghrib: Int
    let isha: Int
    /// Islamic midnight — the midpoint between sunset and the following Fajr.
    let midnight: Int
    /// Start of the last third of the night. It falls after midnight, so its
    /// value is normally smaller than `isha`.
    let lastThird: Int

    let timeZoneIdentifier: String?

    let calculationMethodId: Int?
    let calculationMethodName: String?

    static let fallbackTimeZoneIdentifier = "Asia/Riyadh"
}

// MARK: - Clock Helpers

extension DayPrayerTimes {

    var calendar: Calendar { DayPrayerTimes.calendar(for: timeZoneIdentifier) }

    var duha: Int { sunrise + (dhuhr - sunrise) / 4 }

    /// Minutes since midnight measured in *this day's* zone.
    func minutes(at date: Date) -> Int {
        DayPrayerTimes.minutesSinceMidnight(of: date, calendar: calendar)
    }

    func seconds(at date: Date) -> Int {
        DayPrayerTimes.secondsSinceMidnight(of: date, calendar: calendar)
    }

    static func calendar(for timeZoneIdentifier: String?) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZoneIdentifier.flatMap(TimeZone.init(identifier:))
            ?? TimeZone(identifier: fallbackTimeZoneIdentifier)
            ?? .current
        return calendar
    }

    static func dayKey(for date: Date, calendar: Calendar) -> String {
        dayKeyFormatter(calendar: calendar).string(from: date)
    }

    /// The inverse of `dayKey(for:calendar:)`, so a cached day can be aged
    /// against today on the anchors' own calendar rather than the device's.
    static func date(fromDayKey dayKey: String, calendar: Calendar) -> Date? {
        dayKeyFormatter(calendar: calendar).date(from: dayKey)
    }

    private static func dayKeyFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = calendar.timeZone
        return formatter
    }

    static func minutesSinceMidnight(of date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    static func secondsSinceMidnight(of date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute, .second], from: date)
        return (components.hour ?? 0) * 3600 + (components.minute ?? 0) * 60 + (components.second ?? 0)
    }
}

// MARK: - API Mapping

extension DayPrayerTimes {

    /// `nil` when any anchor is missing or unparseable. The caller then keeps
    /// whatever it had rather than publishing a half-built day, which would
    /// open or close windows at the wrong moment.
    init?(response: PrayerTimesData, dayKey: String) {
        let timings = response.timings

        guard let fajr = DayPrayerTimes.minutes(from: timings.Fajr),
              let sunrise = DayPrayerTimes.minutes(from: timings.Sunrise),
              let dhuhr = DayPrayerTimes.minutes(from: timings.Dhuhr),
              let asr = DayPrayerTimes.minutes(from: timings.Asr),
              let sunset = DayPrayerTimes.minutes(from: timings.Sunset),
              let maghrib = DayPrayerTimes.minutes(from: timings.Maghrib),
              let isha = DayPrayerTimes.minutes(from: timings.Isha),
              let midnight = DayPrayerTimes.minutes(from: timings.Midnight),
              let lastThird = DayPrayerTimes.minutes(from: timings.Lastthird)
        else { return nil }

        self.dayKey = dayKey
        self.timeZoneIdentifier = response.meta?.timezone ?? DayPrayerTimes.fallbackTimeZoneIdentifier
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.sunset = sunset
        self.maghrib = maghrib
        self.isha = isha
        self.midnight = midnight
        self.lastThird = lastThird
        self.calculationMethodId = response.meta?.method?.id
        self.calculationMethodName = response.meta?.method?.name
    }

    /// Aladhan returns `"HH:mm"`. Some payloads append a zone, `"04:26 (AST)"`,
    /// so only the leading clock is read. A missing value reads as `nil`, which
    /// makes the whole day `nil` and keeps every window closed.
    private static func minutes(from value: String?) -> Int? {
        guard let value else { return nil }
        let clock = value.trimmingCharacters(in: .whitespaces).prefix(5)
        let parts = clock.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute)
        else { return nil }
        return hour * 60 + minute
    }
}

// MARK: - Prayer Slots

enum PrayerSlot: String, Codable, CaseIterable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha
    case duha
    case jumuah

    static let obligatorySlots: [PrayerSlot] = [.fajr, .dhuhr, .asr, .maghrib, .isha]
    static let voluntarySlots: [PrayerSlot] = [.duha, .jumuah]

    static let defaultEnabledSlots: Set<PrayerSlot> = Set(PrayerSlot.obligatorySlots)

    var isFridayOnly: Bool { self == .jumuah }

    var replacesDhuhrOnFriday: Bool { self == .jumuah }
}

extension DayPrayerTimes {

    func minutesSinceMidnight(of slot: PrayerSlot) -> Int {
        switch slot {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        case .duha: return duha
        case .jumuah: return dhuhr
        }
    }
}

// MARK: - Calculation Method

enum PrayerCalculationMethod: Int, Codable, CaseIterable {
    case shiaIthnaAshari = 0
    case universityOfIslamicSciencesKarachi = 1
    case islamicSocietyOfNorthAmerica = 2
    case muslimWorldLeague = 3
    case ummAlQuraUniversity = 4
    case egyptianGeneralAuthorityOfSurvey = 5
    case instituteOfGeophysicsTehran = 7
    case gulfRegion = 8
    case kuwait = 9
    case qatar = 10
    case majlisUgamaIslamSingapura = 11
    case unionDesOrganisationsIslamiquesDeFrance = 12
    case diyanetIsleriBaskanligi = 13
    case spiritualAdministrationOfMuslimsOfRussia = 14
    case moonsightingCommittee = 15
    case dubai = 16
    case jabatanKemajuanIslamMalaysia = 17
    case tunisia = 18
    case algeria = 19
    case kementerianAgamaRepublikIndonesia = 20
    case morocco = 21
    case comunidadeIslamicaDeLisboa = 22
    case jordan = 23

    static let `default`: PrayerCalculationMethod = .ummAlQuraUniversity
}

enum PrayerJurisprudenceSchool: Int, Codable, CaseIterable {
    case standard = 0
    case hanafi = 1

    static let `default`: PrayerJurisprudenceSchool = .standard
}

// MARK: - Notification Preferences

enum PrayerNotificationAlertStyle: String, Codable, CaseIterable {
    case standardTone
    case shortAdhanTone
}

struct PrayerNotificationPreferences: Codable, Equatable {

    static let reminderLeadMinutesRange = 5...60
    static let reminderLeadMinutesStep = 5
    static let defaultReminderLeadMinutes = 15

    var isPrayerNotificationEnabled: Bool
    var enabledSlots: Set<PrayerSlot>
    var alertStyle: PrayerNotificationAlertStyle
    var isPrePrayerReminderEnabled: Bool
    var prePrayerReminderLeadMinutes: Int
    var isInAppAdhanAudioEnabled: Bool
    var calculationMethod: PrayerCalculationMethod
    var jurisprudenceSchool: PrayerJurisprudenceSchool

    static let standard = PrayerNotificationPreferences(
        isPrayerNotificationEnabled: false,
        enabledSlots: PrayerSlot.defaultEnabledSlots,
        alertStyle: .standardTone,
        isPrePrayerReminderEnabled: false,
        prePrayerReminderLeadMinutes: PrayerNotificationPreferences.defaultReminderLeadMinutes,
        isInAppAdhanAudioEnabled: false,
        calculationMethod: .default,
        jurisprudenceSchool: .default
    )

    init(isPrayerNotificationEnabled: Bool,
         enabledSlots: Set<PrayerSlot>,
         alertStyle: PrayerNotificationAlertStyle,
         isPrePrayerReminderEnabled: Bool,
         prePrayerReminderLeadMinutes: Int,
         isInAppAdhanAudioEnabled: Bool,
         calculationMethod: PrayerCalculationMethod,
         jurisprudenceSchool: PrayerJurisprudenceSchool) {
        self.isPrayerNotificationEnabled = isPrayerNotificationEnabled
        self.enabledSlots = enabledSlots
        self.alertStyle = alertStyle
        self.isPrePrayerReminderEnabled = isPrePrayerReminderEnabled
        self.prePrayerReminderLeadMinutes = prePrayerReminderLeadMinutes
        self.isInAppAdhanAudioEnabled = isInAppAdhanAudioEnabled
        self.calculationMethod = calculationMethod
        self.jurisprudenceSchool = jurisprudenceSchool
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let standard = PrayerNotificationPreferences.standard
        isPrayerNotificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .isPrayerNotificationEnabled)
            ?? standard.isPrayerNotificationEnabled
        enabledSlots = try container.decodeIfPresent(Set<PrayerSlot>.self, forKey: .enabledSlots)
            ?? standard.enabledSlots
        alertStyle = try container.decodeIfPresent(PrayerNotificationAlertStyle.self, forKey: .alertStyle)
            ?? standard.alertStyle
        isPrePrayerReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .isPrePrayerReminderEnabled)
            ?? standard.isPrePrayerReminderEnabled
        prePrayerReminderLeadMinutes = try container.decodeIfPresent(Int.self, forKey: .prePrayerReminderLeadMinutes)
            ?? standard.prePrayerReminderLeadMinutes
        isInAppAdhanAudioEnabled = try container.decodeIfPresent(Bool.self, forKey: .isInAppAdhanAudioEnabled)
            ?? standard.isInAppAdhanAudioEnabled
        calculationMethod = try container.decodeIfPresent(PrayerCalculationMethod.self, forKey: .calculationMethod)
            ?? standard.calculationMethod
        jurisprudenceSchool = try container.decodeIfPresent(PrayerJurisprudenceSchool.self,
                                                           forKey: .jurisprudenceSchool)
            ?? standard.jurisprudenceSchool
    }

    var clampedReminderLeadMinutes: Int {
        min(max(prePrayerReminderLeadMinutes, PrayerNotificationPreferences.reminderLeadMinutesRange.lowerBound),
            PrayerNotificationPreferences.reminderLeadMinutesRange.upperBound)
    }
}

// MARK: - Notification Identity

enum PrayerNotificationKind: String, Codable, CaseIterable {
    case adhan
    case reminder
}

enum PrayerNotificationIdentifier {

    static let ownedPrefix = "prayer_notification"
    private static let separator = "."

    static let ownedIdentifierPrefix = PrayerNotificationIdentifier.ownedPrefix
        + PrayerNotificationIdentifier.separator

    static func identifier(dayKey: String, slot: PrayerSlot, kind: PrayerNotificationKind) -> String {
        [PrayerNotificationIdentifier.ownedPrefix, dayKey, slot.rawValue, kind.rawValue]
            .joined(separator: PrayerNotificationIdentifier.separator)
    }

    static func isOwned(_ identifier: String) -> Bool {
        identifier.hasPrefix(PrayerNotificationIdentifier.ownedIdentifierPrefix)
    }

    static func slot(of identifier: String) -> PrayerSlot? {
        let parts = identifier.components(separatedBy: PrayerNotificationIdentifier.separator)
        guard parts.count == 4, parts[0] == PrayerNotificationIdentifier.ownedPrefix else { return nil }
        return PrayerSlot(rawValue: parts[2])
    }

    static func kind(of identifier: String) -> PrayerNotificationKind? {
        let parts = identifier.components(separatedBy: PrayerNotificationIdentifier.separator)
        guard parts.count == 4, parts[0] == PrayerNotificationIdentifier.ownedPrefix else { return nil }
        return PrayerNotificationKind(rawValue: parts[3])
    }
}

// MARK: - Schedule Builder

struct PrayerNotificationScheduleEntry: Equatable {
    let identifier: String
    let dayKey: String
    let slot: PrayerSlot
    let kind: PrayerNotificationKind
    let fireDate: Date
    let dateComponents: DateComponents
    let leadMinutes: Int
}

struct PrayerNotificationScheduleBuilder {

    static let pendingRequestLimit = LocalNotificationPendingBudget.requestLimit
    static let maximumWindowInDays = 7
    private static let fridayWeekday = 6

    let clock: LocalNotificationClock

    func entries(for day: DayPrayerTimes,
                 preferences: PrayerNotificationPreferences) -> [PrayerNotificationScheduleEntry] {
        guard preferences.isPrayerNotificationEnabled, !preferences.enabledSlots.isEmpty else { return [] }

        let calendar = day.calendar
        guard let anchorDay = DayPrayerTimes.date(fromDayKey: day.dayKey, calendar: calendar) else { return [] }

        let now = clock.currentDate
        var dayGroups: [[PrayerNotificationScheduleEntry]] = []

        for dayOffset in 0..<PrayerNotificationScheduleBuilder.maximumWindowInDays {
            guard let dayStart = calendar.date(byAdding: .day,
                                               value: dayOffset,
                                               to: calendar.startOfDay(for: anchorDay))
            else { continue }

            dayGroups.append(entries(forDayStartingAt: dayStart,
                                     day: day,
                                     preferences: preferences,
                                     calendar: calendar,
                                     now: now))
        }

        return LocalNotificationPendingBudget
            .affordableGroups(dayGroups, limit: PrayerNotificationScheduleBuilder.pendingRequestLimit)
            .flatMap { $0 }
    }
}

private extension PrayerNotificationScheduleBuilder {

    func entries(forDayStartingAt dayStart: Date,
                 day: DayPrayerTimes,
                 preferences: PrayerNotificationPreferences,
                 calendar: Calendar,
                 now: Date) -> [PrayerNotificationScheduleEntry] {

        let dayKey = DayPrayerTimes.dayKey(for: dayStart, calendar: calendar)
        let isFriday = calendar.component(.weekday, from: dayStart)
            == PrayerNotificationScheduleBuilder.fridayWeekday
        let leadMinutes = preferences.clampedReminderLeadMinutes
        var entries: [PrayerNotificationScheduleEntry] = []

        for slot in PrayerSlot.allCases {
            guard preferences.enabledSlots.contains(slot) else { continue }
            guard !(slot.isFridayOnly && !isFriday) else { continue }

            let isSupersededByJumuah = slot == .dhuhr
                && isFriday
                && preferences.enabledSlots.contains(.jumuah)
            guard !isSupersededByJumuah else { continue }

            guard let prayerDate = calendar.date(byAdding: .minute,
                                                 value: day.minutesSinceMidnight(of: slot),
                                                 to: dayStart)
            else { continue }

            if prayerDate > now {
                entries.append(entry(slot: slot,
                                     kind: .adhan,
                                     dayKey: dayKey,
                                     fireDate: prayerDate,
                                     calendar: calendar,
                                     leadMinutes: 0))
            }

            guard preferences.isPrePrayerReminderEnabled,
                  let reminderDate = calendar.date(byAdding: .minute, value: -leadMinutes, to: prayerDate),
                  reminderDate > now
            else { continue }

            entries.append(entry(slot: slot,
                                 kind: .reminder,
                                 dayKey: dayKey,
                                 fireDate: reminderDate,
                                 calendar: calendar,
                                 leadMinutes: leadMinutes))
        }

        return entries.sorted { $0.fireDate < $1.fireDate }
    }

    func entry(slot: PrayerSlot,
               kind: PrayerNotificationKind,
               dayKey: String,
               fireDate: Date,
               calendar: Calendar,
               leadMinutes: Int) -> PrayerNotificationScheduleEntry {

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        components.timeZone = calendar.timeZone

        return PrayerNotificationScheduleEntry(
            identifier: PrayerNotificationIdentifier.identifier(dayKey: dayKey, slot: slot, kind: kind),
            dayKey: dayKey,
            slot: slot,
            kind: kind,
            fireDate: fireDate,
            dateComponents: components,
            leadMinutes: leadMinutes
        )
    }
}
