//
//  PrayerTimesStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation
import Combine
import AVFoundation
import UIKit
import UserNotifications
import Core

/// Single source of today's prayer anchors for every time-gated section.
///
/// Cached in `UserDefaults` rather than SwiftData on purpose: `StorageManager`
/// wipes the whole store on a schema mismatch, so a new `@Model` would cost the
/// user their bookmarks and reading progress the next time the schema moves.
@MainActor
final class PrayerTimesStore: ObservableObject {

    static let shared = PrayerTimesStore()

    /// `nil` until a day has been fetched or read back from the cache. Callers
    /// treat `nil` as "no gate can open" so a card never shows at the wrong hour.
    @Published private(set) var today: DayPrayerTimes?

    @Published private(set) var isRefreshing: Bool = false

    private var uncorrectedToday: DayPrayerTimes?
    private var minuteOffsets: [PrayerSlot: Int] = [:]

    private static let storageKey = "prayer_times_day_v3"
    private let service = QuranService.shared
    private let locationStore = SelectedLocationStore.shared
    private let defaults = UserDefaults.standard
    private var refreshTask: Task<Void, Never>?
    private var cachedIdentifier: String?

    /// Anchors drift a minute or two a day, so yesterday's cache is a better
    /// gate than none. Last month's is not: a device that never reaches the
    /// network would otherwise keep gating sections on whatever it last saw.
    private let maxCacheAgeInDays = 3

    private init() {
        let restored = restoredCacheEntry()
        minuteOffsets = PrayerNotificationManager.shared.preferences.clampedPrayerMinuteOffsets
        uncorrectedToday = restored?.times
        today = restored?.times.applyingMinuteOffsets(minuteOffsets)
        cachedIdentifier = restored?.cacheIdentifier
    }

    func applyMinuteOffsets(_ offsets: [PrayerSlot: Int]) {
        guard offsets != minuteOffsets else { return }
        minuteOffsets = offsets
        today = uncorrectedToday?.applyingMinuteOffsets(offsets)
        publishWidgetSnapshot()
    }

    /// Serves the cache when it already covers today at the selected location,
    /// otherwise refreshes once. Safe to call on every `onAppear`.
    func loadTodayForSelectedLocation() {
        publishWidgetSnapshot()

        let location = locationStore.selectedLocation

        // Measured on the anchors' own clock once we have them, so the day
        // rolls over at the selected location's midnight, not the device's.
        let calendar = today?.calendar ?? DayPrayerTimes.calendar(for: location.timeZoneIdentifier)
        let dayKey = DayPrayerTimes.dayKey(for: Date(), calendar: calendar)

        let isCacheCurrent = today?.dayKey == dayKey
            && cachedIdentifier == PrayerTimesStore.cacheIdentifier(for: location)
        guard !isCacheCurrent else { return }
        guard refreshTask == nil else { return }

        isRefreshing = true
        refreshTask = Task { [weak self] in
            await self?.refresh(for: location)
            self?.refreshTask = nil
            self?.isRefreshing = false
        }
    }

    /// Drops the cached day so the next load fetches the newly selected
    /// location instead of serving the previous city's anchors until midnight.
    func reloadAfterSelectedLocationChange() {
        refreshTask?.cancel()
        refreshTask = nil
        isRefreshing = true
        clearCacheEntry()
        loadTodayForSelectedLocation()
    }

    func reloadAfterCalculationPreferenceChange() {
        reloadAfterSelectedLocationChange()
    }

    // MARK: - Private

    private func refresh(for location: SelectedLocation) async {
        let preferences = PrayerNotificationManager.shared.preferences
        do {
            let data = try await service.fetchPrayerTimes(latitude: location.latitude,
                                                          longitude: location.longitude,
                                                          methodId: preferences.calculationMethod.rawValue,
                                                          schoolId: preferences.jurisprudenceSchool.rawValue)
            // Stamped with the payload's own zone. On a cold launch the day key
            // is the only freshness signal there is, and the device zone would
            // file the fetched anchors under the wrong calendar day.
            let calendar = DayPrayerTimes.calendar(for: data.meta?.timezone)
            let dayKey = DayPrayerTimes.dayKey(for: Date(), calendar: calendar)
            guard let parsed = DayPrayerTimes(response: data, dayKey: dayKey) else {
                print("❌ Prayer times store: incomplete timings for \(dayKey)")
                return
            }
            let identifier = PrayerTimesStore.cacheIdentifier(for: location, preferences: preferences)
            minuteOffsets = preferences.clampedPrayerMinuteOffsets
            uncorrectedToday = parsed
            today = parsed.applyingMinuteOffsets(minuteOffsets)
            cachedIdentifier = identifier
            persist(parsed, cacheIdentifier: identifier)
            publishWidgetSnapshot()
        } catch {
            // Yesterday's cache is kept deliberately. Anchors move by a minute
            // or two a day, so a stale day is a far better gate than no gate.
            // Past the age bound it stops being one, and a closed gate is the
            // honest answer — a card at the wrong hour is worse than no card.
            print("❌ Prayer times store: \(error)")
            if let current = today, !isFresh(current) {
                clearCacheEntry()
            }
        }
    }

    private func publishWidgetSnapshot() {
        PrayerWidgetSnapshotWriter.shared.refresh(day: today)
    }

    private func persist(_ times: DayPrayerTimes, cacheIdentifier: String) {
        let entry = CachedPrayerTimesEntry(cacheIdentifier: cacheIdentifier, times: times)
        guard let encoded = try? JSONEncoder().encode(entry) else { return }
        defaults.set(encoded, forKey: PrayerTimesStore.storageKey)
    }

    private func clearCacheEntry() {
        uncorrectedToday = nil
        today = nil
        cachedIdentifier = nil
        defaults.removeObject(forKey: PrayerTimesStore.storageKey)
    }

    private func restoredCacheEntry() -> CachedPrayerTimesEntry? {
        guard let data = defaults.data(forKey: PrayerTimesStore.storageKey),
              let decoded = try? JSONDecoder().decode(CachedPrayerTimesEntry.self, from: data)
        else { return nil }
        // A blob written before the zone was recorded would keep being read on
        // the device clock for the rest of the day. Dropping it costs one fetch
        // and makes the zone fix take hold on the first launch after the update.
        guard decoded.times.timeZoneIdentifier != nil else { return nil }
        guard isFresh(decoded.times) else { return nil }
        return decoded
    }

    /// Measured on the anchors' own calendar, so a user in another zone neither
    /// ages the cached day early nor keeps it a day too long. A day key
    /// in the future — the device clock moved back — also reads as stale.
    private func isFresh(_ times: DayPrayerTimes) -> Bool {
        let calendar = times.calendar
        guard let cachedDay = DayPrayerTimes.date(fromDayKey: times.dayKey, calendar: calendar),
              let age = calendar.dateComponents([.day],
                                                from: calendar.startOfDay(for: cachedDay),
                                                to: calendar.startOfDay(for: Date())).day
        else { return false }
        return (0...maxCacheAgeInDays).contains(age)
    }

    // MARK: - Cache Identity

    static func cacheIdentifier(for location: SelectedLocation) -> String {
        cacheIdentifier(for: location, preferences: PrayerNotificationManager.shared.preferences)
    }

    static func cacheIdentifier(for location: SelectedLocation,
                                preferences: PrayerNotificationPreferences) -> String {
        [location.prayerTimesCacheIdentifier,
         "m\(preferences.calculationMethod.rawValue)",
         "s\(preferences.jurisprudenceSchool.rawValue)"].joined(separator: "|")
    }
}

/// Pairs a cached day with the location it was fetched for, so switching city
/// cannot keep serving the previous city's anchors until the next calendar day.
private struct CachedPrayerTimesEntry: Codable {
    let cacheIdentifier: String
    let times: DayPrayerTimes
}

// MARK: - Preferences Storage

final class PrayerNotificationPreferencesStore {

    private static let storageKey = "prayer_notification_preferences_v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func restoredPreferences() -> PrayerNotificationPreferences {
        guard let data = defaults.data(forKey: PrayerNotificationPreferencesStore.storageKey),
              let decoded = try? JSONDecoder().decode(PrayerNotificationPreferences.self, from: data)
        else { return .standard }
        return decoded
    }

    func save(_ preferences: PrayerNotificationPreferences) {
        guard let encoded = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(encoded, forKey: PrayerNotificationPreferencesStore.storageKey)
    }
}

// MARK: - Sound Assets

struct PrayerNotificationSoundCatalog {

    static let shortAdhanToneExtension = "caf"
    static let fullAdhanAudioExtension = "m4a"
    static let shortAdhanToneMaximumDuration: TimeInterval = 30

    @MainActor private static var cachedDurations: [String: TimeInterval] = [:]

    static func isWithinSystemSoundLimit(_ duration: TimeInterval) -> Bool {
        duration > 0 && duration < shortAdhanToneMaximumDuration
    }

    private let bundle: Bundle

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    var availableRecordings: [AdhanRecording] {
        AdhanRecording.bundled.filter { isAvailable($0) }
    }

    func isAvailable(_ recording: AdhanRecording) -> Bool {
        shortAdhanToneURL(for: recording) != nil && fullAdhanAudioURL(for: recording) != nil
    }

    func shortAdhanToneURL(for recording: AdhanRecording) -> URL? {
        bundle.url(forResource: recording.notificationToneResource,
                   withExtension: PrayerNotificationSoundCatalog.shortAdhanToneExtension)
    }

    func fullAdhanAudioURL(for recording: AdhanRecording) -> URL? {
        bundle.url(forResource: recording.fullAdhanResource,
                   withExtension: PrayerNotificationSoundCatalog.fullAdhanAudioExtension)
    }

    @MainActor
    func measuredDuration(ofFileAt url: URL) -> TimeInterval? {
        if let cached = PrayerNotificationSoundCatalog.cachedDurations[url.path] { return cached }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }

        PrayerNotificationSoundCatalog.cachedDurations[url.path] = player.duration
        return player.duration
    }

    @MainActor
    func notificationSoundFileName(for recording: AdhanRecording) -> String? {
        guard let url = shortAdhanToneURL(for: recording),
              let duration = measuredDuration(ofFileAt: url),
              PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(duration)
        else { return nil }

        return url.lastPathComponent
    }

    func resolvedRecording(forIdentifier identifier: String) -> AdhanRecording? {
        if let requested = AdhanRecording.recording(forIdentifier: identifier), isAvailable(requested) {
            return requested
        }

        if let fallback = AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier),
           isAvailable(fallback) {
            return fallback
        }

        return availableRecordings.first
    }
}

// MARK: - Slot Names

extension PrayerSlot {

    var localizedName: String {
        switch self {
        case .fajr: return AppLocalizedKeys.fajr.value
        case .dhuhr: return AppLocalizedKeys.dhuhr.value
        case .asr: return AppLocalizedKeys.asr.value
        case .maghrib: return AppLocalizedKeys.maghrib.value
        case .isha: return AppLocalizedKeys.isha.value
        case .duha: return AppLocalizedKeys.duha.value
        case .jumuah: return AppLocalizedKeys.jumuah.value
        case .sunrise: return AppLocalizedKeys.prayerSlotSunrise.value
        case .lastThirdOfNight: return AppLocalizedKeys.lastThirdOfNight.value
        case .surahAlKahf: return AppLocalizedKeys.prayerSlotSurahAlKahf.value
        }
    }

    var iconName: String {
        switch self {
        case .fajr: return "sunrise"
        case .dhuhr: return "sun.max"
        case .asr: return "sun.min"
        case .maghrib: return "sunset"
        case .isha: return "moon.stars"
        case .duha: return "sun.horizon"
        case .jumuah: return "building.columns"
        case .sunrise: return "sunrise.fill"
        case .lastThirdOfNight: return "moon.zzz"
        case .surahAlKahf: return "book.closed"
        }
    }
}

// MARK: - Notification Manager

@MainActor
final class PrayerNotificationManager: NSObject, ObservableObject {

    static let shared = PrayerNotificationManager(
        center: SystemLocalNotificationCenter(),
        preferencesStore: PrayerNotificationPreferencesStore(defaults: .standard),
        clock: SystemLocalNotificationClock(),
        soundCatalog: PrayerNotificationSoundCatalog(bundle: .main)
    )

    @Published private(set) var authorizationStatus: LocalNotificationAuthorizationStatus = .notDetermined
    @Published private(set) var preferences: PrayerNotificationPreferences
    @Published private(set) var scheduledRequestCount: Int = 0
    @Published private(set) var scheduledWindowInDays: Int = 0

    let soundCatalog: PrayerNotificationSoundCatalog

    private let scheduler: LocalNotificationScheduler
    private let preferencesStore: PrayerNotificationPreferencesStore
    private let builder: PrayerNotificationScheduleBuilder
    private let audioPlayer: PrayerAdhanAudioPlayer
    private var cancellables = Set<AnyCancellable>()
    private var rescheduleTask: Task<Void, Never>?

    init(center: LocalNotificationCenter,
         preferencesStore: PrayerNotificationPreferencesStore,
         clock: LocalNotificationClock,
         soundCatalog: PrayerNotificationSoundCatalog,
         audioFocus: AdhanAudioFocus? = nil) {
        self.scheduler = LocalNotificationScheduler(
            center: center,
            ownedIdentifierPrefix: PrayerNotificationIdentifier.ownedIdentifierPrefix
        )
        self.preferencesStore = preferencesStore
        self.builder = PrayerNotificationScheduleBuilder(clock: clock)
        self.soundCatalog = soundCatalog
        self.audioPlayer = PrayerAdhanAudioPlayer(soundCatalog: soundCatalog, audioFocus: audioFocus)
        self.preferences = preferencesStore.restoredPreferences()
        super.init()
        self.audioPlayer.onPlaybackStateChange = { [weak self] in
            self?.objectWillChange.send()
        }
    }
}

// MARK: - Authorization

extension PrayerNotificationManager {

    func refreshAuthorizationStatus() async {
        authorizationStatus = await scheduler.currentAuthorizationStatus()
    }

    func requestAuthorization() async {
        let current = await scheduler.currentAuthorizationStatus()
        authorizationStatus = current == .notDetermined ? await scheduler.requestAuthorization() : current
        await reschedule(day: PrayerTimesStore.shared.today)
    }
}

// MARK: - Preferences

extension PrayerNotificationManager {

    func updatePreferences(_ changes: (inout PrayerNotificationPreferences) -> Void) {
        var updated = preferences
        changes(&updated)
        updated.prePrayerReminderLeadMinutes = updated.clampedReminderLeadMinutes
        guard updated != preferences else { return }

        let previous = preferences
        preferences = updated
        preferencesStore.save(updated)

        let didCalculationChange = previous.calculationMethod != updated.calculationMethod
            || previous.jurisprudenceSchool != updated.jurisprudenceSchool

        if didCalculationChange {
            PrayerTimesStore.shared.reloadAfterCalculationPreferenceChange()
        } else {
            PrayerTimesStore.shared.applyMinuteOffsets(updated.clampedPrayerMinuteOffsets)
            rescheduleFromPrayerTimesStore()
        }
    }

    var availableRecordings: [AdhanRecording] { soundCatalog.availableRecordings }

    var selectedRecording: AdhanRecording? {
        soundCatalog.resolvedRecording(forIdentifier: preferences.adhanRecordingIdentifier)
    }

    var notificationSoundFileName: String? {
        guard let recording = selectedRecording else { return nil }
        return soundCatalog.notificationSoundFileName(for: recording)
    }

    var isShortAdhanToneAvailable: Bool { notificationSoundFileName != nil }

    var isFullAdhanAudioAvailable: Bool {
        guard let recording = selectedRecording else { return false }
        return soundCatalog.fullAdhanAudioURL(for: recording) != nil
    }

    func selectRecording(_ recording: AdhanRecording) {
        let hasTone = soundCatalog.notificationSoundFileName(for: recording) != nil

        updatePreferences {
            $0.adhanRecordingIdentifier = recording.id

            if hasTone {
                $0.alertStyle = .shortAdhanTone
            }
        }
    }

    var effectiveAlertStyle: PrayerNotificationAlertStyle {
        guard preferences.alertStyle == .shortAdhanTone, isShortAdhanToneAvailable else { return .standardTone }
        return .shortAdhanTone
    }
}

// MARK: - Scheduling

extension PrayerNotificationManager {

    func startObservingPrayerTimes() {
        PrayerTimesStore.shared.$today
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] day in
                self?.reschedule(for: day)
            }
            .store(in: &cancellables)

        SelectedLocationStore.shared.$selectedLocation
            .dropFirst()
            .sink { [weak self] _ in
                self?.handleSelectedLocationChange()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.rescheduleFromPrayerTimesStore()
            }
            .store(in: &cancellables)
    }

    func handleSelectedLocationChange() {
        rescheduleFromPrayerTimesStore()
    }

    func rescheduleFromPrayerTimesStore() {
        reschedule(for: PrayerTimesStore.shared.today)
    }

    func reschedule(for day: DayPrayerTimes?) {
        rescheduleTask?.cancel()
        rescheduleTask = Task { [weak self] in
            await self?.reschedule(day: day)
        }
    }

    func reschedule(day: DayPrayerTimes?) async {
        let status = await scheduler.currentAuthorizationStatus()
        authorizationStatus = status

        guard status.allowsScheduling, preferences.isPrayerNotificationEnabled, let day else {
            await scheduler.removeOwnedRequests()
            scheduledRequestCount = 0
            scheduledWindowInDays = 0
            return
        }

        let entries = builder.entries(for: day, preferences: preferences)
        let sound = resolvedNotificationSoundFileName
        await scheduler.replaceOwnedRequests(with: entries.map {
            draft(for: $0, soundFileName: usesPrayerCallSound(entry: $0) ? sound : nil)
        })

        scheduledRequestCount = entries.count
        scheduledWindowInDays = Set(entries.map(\.dayKey)).count
    }
}

// MARK: - Foreground Presentation

extension PrayerNotificationManager: UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let identifier = notification.request.identifier
        return await presentationOptions(forIdentifier: identifier)
    }

    func presentationOptions(forIdentifier identifier: String) -> UNNotificationPresentationOptions {
        let bannerOptions: UNNotificationPresentationOptions = [.banner, .list, .sound]
        guard PrayerNotificationIdentifier.isOwned(identifier),
              PrayerNotificationIdentifier.kind(of: identifier) == .adhan,
              preferences.isInAppAdhanAudioEnabled,
              let recording = selectedRecording,
              soundCatalog.fullAdhanAudioURL(for: recording) != nil
        else { return bannerOptions }

        audioPlayer.playFullAdhan(for: recording)
        return [.banner, .list]
    }

    func stopAdhanAudio() {
        audioPlayer.stop()
    }
}

// MARK: - Adhan Preview

extension PrayerNotificationManager {

    func isPlayingAdhanAudio(_ recording: AdhanRecording, mode: PrayerAdhanPlaybackMode) -> Bool {
        audioPlayer.isPlaying(recording, mode: mode)
    }

    var lastAdhanPlaybackFailure: PrayerAdhanPlaybackFailure? { audioPlayer.lastFailure }

    func previewNotificationTone(for recording: AdhanRecording) {
        audioPlayer.playNotificationTonePreview(for: recording)
    }

    func previewFullAdhan(for recording: AdhanRecording) {
        audioPlayer.playFullAdhan(for: recording)
    }
}

// MARK: - Test Notification

enum PrayerNotificationTestOutcome: Equatable {
    case scheduled
    case authorizationDenied
    case authorizationNotRequested
}

extension PrayerNotificationManager {

    static let testRequestIdentifier: String = "test_prayer_notification.manual"
    static let testNotificationDelayInSeconds: TimeInterval = 5

    func sendTestNotification() async -> PrayerNotificationTestOutcome {
        let status = await scheduler.currentAuthorizationStatus()
        authorizationStatus = status

        guard status.allowsScheduling else {
            return status.isDenied ? .authorizationDenied : .authorizationNotRequested
        }

        await scheduler.add(testNotificationDraft())
        return .scheduled
    }
}

// MARK: - Private

private extension PrayerNotificationManager {

    func draft(for entry: PrayerNotificationScheduleEntry,
               soundFileName: String?) -> LocalNotificationRequestDraft {
        let content = PrayerNotificationContentCatalog.content(dayKey: entry.dayKey,
                                                              slot: entry.slot,
                                                              kind: entry.kind)

        return LocalNotificationRequestDraft(identifier: entry.identifier,
                                             title: title(for: entry),
                                             body: body(for: entry, content: content),
                                             soundFileName: soundFileName,
                                             dateComponents: entry.dateComponents)
    }

    func usesPrayerCallSound(entry: PrayerNotificationScheduleEntry) -> Bool {
        !entry.slot.isSupplemental && entry.kind != .iqamah
    }

    func title(for entry: PrayerNotificationScheduleEntry) -> String {
        entry.kind == .iqamah ? iqamahTitle(for: entry.slot) : entry.slot.localizedName
    }

    func iqamahTitle(for slot: PrayerSlot) -> String {
        String(format: AppLocalizedKeys.prayerNotificationIqamahTitleFormat.value, slot.localizedName)
    }

    func body(for entry: PrayerNotificationScheduleEntry,
              content: PrayerNotificationContent?) -> String {
        guard let content else { return fallbackBody(for: entry) }

        return content.notificationBody
    }

    func fallbackBody(for entry: PrayerNotificationScheduleEntry) -> String {
        if let supplemental = supplementalFallbackBody(for: entry.slot) { return supplemental }

        let name = entry.slot.localizedName

        switch entry.kind {
        case .adhan:
            return String(format: AppLocalizedKeys.prayerNotificationAdhanBodyFormat.value, name)
        case .iqamah:
            return String(format: AppLocalizedKeys.prayerNotificationIqamahBodyFormat.value, name)
        case .reminder:
            return String(format: AppLocalizedKeys.prayerNotificationReminderBodyFormat.value,
                          name,
                          localizedNumber(entry.leadMinutes))
        }
    }

    func supplementalFallbackBody(for slot: PrayerSlot) -> String? {
        switch slot {
        case .sunrise: return AppLocalizedKeys.prayerNotificationSunriseBody.value
        case .lastThirdOfNight: return AppLocalizedKeys.prayerNotificationLastThirdBody.value
        case .surahAlKahf: return AppLocalizedKeys.prayerNotificationSurahAlKahfBody.value
        default: return nil
        }
    }

    func testNotificationDraft() -> LocalNotificationRequestDraft {
        LocalNotificationRequestDraft(identifier: PrayerNotificationManager.testRequestIdentifier,
                                      title: AppLocalizedKeys.prayerNotificationsTestTitle.value,
                                      body: AppLocalizedKeys.prayerNotificationsTestBody.value,
                                      soundFileName: resolvedNotificationSoundFileName,
                                      dateComponents: DateComponents(),
                                      secondsFromNow: PrayerNotificationManager.testNotificationDelayInSeconds)
    }

    var resolvedNotificationSoundFileName: String? {
        effectiveAlertStyle == .shortAdhanTone ? notificationSoundFileName : nil
    }

    func localizedNumber(_ value: Int) -> String {
        isArabic ? value.arabicNumerals : "\(value)"
    }

    var isArabic: Bool { LocalizationManager.shared.currentLanguage == .Arabic }
}
