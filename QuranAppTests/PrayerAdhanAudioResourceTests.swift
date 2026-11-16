//
//  PrayerAdhanAudioResourceTests.swift
//  QuranAppTests
//
//  Created by Ali Zaghloul on 16/11/2026.
//

import XCTest
import AVFoundation
@testable import QuranApp

@MainActor
final class PrayerAdhanAudioResourceTests: XCTestCase {

    private let bundledCatalog = PrayerNotificationFixture.soundCatalogWithBundledAudio()
    private let emptyCatalog = PrayerNotificationFixture.soundCatalogWithoutAudio()
    private var scratchDirectories: [URL] = []

    private var now: Date {
        PrayerNotificationFixture.date(dayKey: PrayerNotificationFixture.mondayDayKey, minutesSinceMidnight: 30)
    }

    override func tearDown() {
        for directory in scratchDirectories {
            try? FileManager.default.removeItem(at: directory)
        }

        scratchDirectories = []
        super.tearDown()
    }

    private func manager(soundCatalog: PrayerNotificationSoundCatalog,
                         defaults: UserDefaults = PrayerNotificationFixture.defaults(),
                         preferences: PrayerNotificationPreferences = PrayerNotificationFixture
                             .preferences()) -> PrayerNotificationManager {
        PrayerNotificationManagerBuilder.manager(center: LocalNotificationCenterDouble(status: .authorized),
                                                 defaults: defaults,
                                                 preferences: preferences,
                                                 now: now,
                                                 soundCatalog: soundCatalog)
    }

    private func scratchDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        scratchDirectories.append(directory)

        return directory
    }

    private func writeSilentTone(seconds: Double, to url: URL) throws {
        let settings: [String: Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                                       AVSampleRateKey: 8_000.0,
                                       AVNumberOfChannelsKey: 1,
                                       AVLinearPCMBitDepthKey: 16,
                                       AVLinearPCMIsFloatKey: false,
                                       AVLinearPCMIsBigEndianKey: false]
        let file = try AVAudioFile(forWriting: url, settings: settings)
        let frames = AVAudioFrameCount(8_000 * seconds)
        let buffer = try XCTUnwrap(AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frames))
        buffer.frameLength = frames

        for channel in 0..<Int(file.processingFormat.channelCount) {
            buffer.floatChannelData?[channel].update(repeating: 0, count: Int(frames))
        }

        try file.write(from: buffer)
    }

    private func catalog(toneSeconds: Double?,
                         isFullAdhanReadable: Bool,
                         recording: AdhanRecording) throws -> PrayerNotificationSoundCatalog {
        let resources = try scratchDirectory().appendingPathComponent("Adhan.bundle", isDirectory: true)
        try FileManager.default.createDirectory(at: resources, withIntermediateDirectories: true)

        let toneURL = resources
            .appendingPathComponent("\(recording.notificationToneResource).caf")
        let fullURL = resources
            .appendingPathComponent("\(recording.fullAdhanResource).m4a")

        if let toneSeconds {
            try writeSilentTone(seconds: toneSeconds, to: toneURL)
        } else {
            try Data("not audio".utf8).write(to: toneURL)
        }

        if isFullAdhanReadable {
            try FileManager.default.copyItem(at: try XCTUnwrap(bundledCatalog.fullAdhanAudioURL(for: recording)),
                                             to: fullURL)
        } else {
            try Data("not audio".utf8).write(to: fullURL)
        }

        return PrayerNotificationSoundCatalog(bundle: try XCTUnwrap(Bundle(url: resources)))
    }

    // MARK: - Bundled Resources

    func testEveryConfiguredRecordingResolvesToARealBundledResource() throws {
        XCTAssertFalse(AdhanRecording.bundled.isEmpty)

        for recording in AdhanRecording.bundled {
            let toneURL = try XCTUnwrap(bundledCatalog.shortAdhanToneURL(for: recording),
                                        "\(recording.id) is missing its notification tone")
            let fullURL = try XCTUnwrap(bundledCatalog.fullAdhanAudioURL(for: recording),
                                        "\(recording.id) is missing its full adhan")

            XCTAssertTrue(FileManager.default.fileExists(atPath: toneURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: fullURL.path))
            XCTAssertTrue(bundledCatalog.isAvailable(recording))
            XCTAssertEqual(toneURL.lastPathComponent, "\(recording.notificationToneResource).caf")
            XCTAssertEqual(fullURL.lastPathComponent, "\(recording.fullAdhanResource).m4a")
        }

        XCTAssertEqual(bundledCatalog.availableRecordings.count, AdhanRecording.bundled.count)
    }

    func testEveryBundledToneIsDecodableAndWithinTheSystemSoundLimit() throws {
        for recording in AdhanRecording.bundled {
            let url = try XCTUnwrap(bundledCatalog.shortAdhanToneURL(for: recording))
            let duration = try XCTUnwrap(bundledCatalog.measuredDuration(ofFileAt: url),
                                         "\(recording.id) tone is not decodable")

            XCTAssertTrue(PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(duration),
                          "\(recording.id) tone lasts \(duration)s")
            XCTAssertEqual(bundledCatalog.notificationSoundFileName(for: recording),
                           "\(recording.notificationToneResource).caf")
        }
    }

    func testEveryBundledFullAdhanIsDecodableAndMatchesItsDeclaredDuration() throws {
        for recording in AdhanRecording.bundled {
            let url = try XCTUnwrap(bundledCatalog.fullAdhanAudioURL(for: recording))
            let player = try AVAudioPlayer(contentsOf: url)

            XCTAssertGreaterThan(player.duration, 60)
            XCTAssertEqual(player.duration, recording.fullAdhanDuration, accuracy: 3,
                           "\(recording.id) declares \(recording.fullAdhanDuration)s")
        }
    }

    func testBundledRecordingsAreDistinctFilesRatherThanPlaceholders() throws {
        var tones = Set<Data>()
        var fullAdhans = Set<Data>()

        for recording in AdhanRecording.bundled {
            let toneURL = try XCTUnwrap(bundledCatalog.shortAdhanToneURL(for: recording))
            let fullURL = try XCTUnwrap(bundledCatalog.fullAdhanAudioURL(for: recording))

            tones.insert(try Data(contentsOf: toneURL))
            fullAdhans.insert(try Data(contentsOf: fullURL))
        }

        XCTAssertEqual(tones.count, AdhanRecording.bundled.count)
        XCTAssertEqual(fullAdhans.count, AdhanRecording.bundled.count)
    }

    // MARK: - Missing Resources

    func testAMissingResourceIsReportedRatherThanTreatedAsAvailable() {
        XCTAssertTrue(emptyCatalog.availableRecordings.isEmpty)

        for recording in AdhanRecording.bundled {
            XCTAssertFalse(emptyCatalog.isAvailable(recording))
            XCTAssertNil(emptyCatalog.shortAdhanToneURL(for: recording))
            XCTAssertNil(emptyCatalog.fullAdhanAudioURL(for: recording))
            XCTAssertNil(emptyCatalog.notificationSoundFileName(for: recording))
        }
    }

    func testPlaybackOfAMissingResourceReportsAFailureInsteadOfFallingSilent() {
        let subject = manager(soundCatalog: emptyCatalog)
        let recording = try! XCTUnwrap(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))

        subject.previewNotificationTone(for: recording)

        XCTAssertEqual(subject.lastAdhanPlaybackFailure,
                       PrayerAdhanPlaybackFailure(reason: .missingResource,
                                                  recordingIdentifier: recording.id,
                                                  mode: .notificationTonePreview))
        XCTAssertFalse(subject.isPlayingAdhanAudio(recording, mode: .notificationTonePreview))

        subject.previewFullAdhan(for: recording)

        XCTAssertEqual(subject.lastAdhanPlaybackFailure?.mode, .fullAdhan)
        XCTAssertEqual(subject.lastAdhanPlaybackFailure?.reason, .missingResource)
    }

    func testPlaybackOfAnUnreadableResourceReportsAFailure() throws {
        let recording = try XCTUnwrap(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))
        let catalog = try catalog(toneSeconds: 5, isFullAdhanReadable: false, recording: recording)
        let subject = manager(soundCatalog: catalog)

        XCTAssertNotNil(catalog.fullAdhanAudioURL(for: recording))

        subject.previewFullAdhan(for: recording)

        XCTAssertEqual(subject.lastAdhanPlaybackFailure?.reason, .unreadableResource)
        XCTAssertEqual(subject.lastAdhanPlaybackFailure?.recordingIdentifier, recording.id)
        XCTAssertFalse(subject.isPlayingAdhanAudio(recording, mode: .fullAdhan))
    }

    // MARK: - Sound Limit

    func testAFailureClearsOnTheNextAttemptAndOnStop() throws {
        let recording = try XCTUnwrap(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))
        let catalog = try catalog(toneSeconds: 5, isFullAdhanReadable: false, recording: recording)
        let subject = manager(soundCatalog: catalog)

        subject.previewFullAdhan(for: recording)

        XCTAssertEqual(subject.lastAdhanPlaybackFailure?.reason, .unreadableResource)

        subject.previewNotificationTone(for: recording)

        XCTAssertNotEqual(subject.lastAdhanPlaybackFailure?.reason, .unreadableResource)
        XCTAssertNotEqual(subject.lastAdhanPlaybackFailure?.reason, .missingResource)

        subject.stopAdhanAudio()

        XCTAssertNil(subject.lastAdhanPlaybackFailure)

        subject.previewFullAdhan(for: recording)

        XCTAssertNotNil(subject.lastAdhanPlaybackFailure)

        subject.stopAdhanAudio()

        XCTAssertNil(subject.lastAdhanPlaybackFailure)
    }

    func testTheSystemSoundLimitRejectsAnythingThirtySecondsOrLonger() {
        XCTAssertTrue(PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(29))
        XCTAssertTrue(PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(29.99))
        XCTAssertFalse(PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(30))
        XCTAssertFalse(PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(31))
        XCTAssertFalse(PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(0))
        XCTAssertFalse(PrayerNotificationSoundCatalog.isWithinSystemSoundLimit(-1))
    }

    func testAnOverlongToneIsRejectedAsANotificationSound() throws {
        let recording = try XCTUnwrap(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))
        let catalog = try catalog(toneSeconds: 31, isFullAdhanReadable: true, recording: recording)
        let toneURL = try XCTUnwrap(catalog.shortAdhanToneURL(for: recording))
        let duration = try XCTUnwrap(catalog.measuredDuration(ofFileAt: toneURL))

        XCTAssertEqual(duration, 31, accuracy: 0.1)
        XCTAssertNil(catalog.notificationSoundFileName(for: recording))

        let subject = manager(soundCatalog: catalog,
                              preferences: PrayerNotificationFixture.preferences(alertStyle: .shortAdhanTone))

        XCTAssertFalse(subject.isShortAdhanToneAvailable)
        XCTAssertEqual(subject.effectiveAlertStyle, .standardTone)
    }

    func testAnUnreadableToneIsRejectedAsANotificationSound() throws {
        let recording = try XCTUnwrap(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))
        let catalog = try catalog(toneSeconds: nil, isFullAdhanReadable: true, recording: recording)
        let toneURL = try XCTUnwrap(catalog.shortAdhanToneURL(for: recording))

        XCTAssertNil(catalog.measuredDuration(ofFileAt: toneURL))
        XCTAssertNil(catalog.notificationSoundFileName(for: recording))
    }

    // MARK: - Selection

    func testSelectingARecordingPersistsItAndTurnsOnTheAdhanTone() {
        let defaults = PrayerNotificationFixture.defaults()
        let subject = manager(soundCatalog: bundledCatalog,
                              defaults: defaults,
                              preferences: PrayerNotificationFixture.preferences(alertStyle: .standardTone))
        let recording = try! XCTUnwrap(bundledCatalog.availableRecordings.last)

        subject.selectRecording(recording)
        let stored = PrayerNotificationPreferencesStore(defaults: defaults).restoredPreferences()

        XCTAssertEqual(stored.adhanRecordingIdentifier, recording.id)
        XCTAssertEqual(stored.alertStyle, .shortAdhanTone)
        XCTAssertEqual(subject.selectedRecording, recording)
        XCTAssertEqual(subject.notificationSoundFileName, "\(recording.notificationToneResource).caf")
        XCTAssertEqual(subject.effectiveAlertStyle, .shortAdhanTone)
    }

    func testAPersistedSelectionSurvivesANewManager() {
        let defaults = PrayerNotificationFixture.defaults()
        let recording = try! XCTUnwrap(bundledCatalog.availableRecordings.last)

        manager(soundCatalog: bundledCatalog, defaults: defaults).selectRecording(recording)
        let restored = manager(soundCatalog: bundledCatalog,
                               defaults: defaults,
                               preferences: PrayerNotificationPreferencesStore(defaults: defaults)
                                   .restoredPreferences())

        XCTAssertEqual(restored.selectedRecording, recording)
        XCTAssertEqual(restored.preferences.adhanRecordingIdentifier, recording.id)
    }

    func testSelectingARecordingWithoutAToneLeavesTheAlertStyleAlone() {
        let defaults = PrayerNotificationFixture.defaults()
        let subject = manager(soundCatalog: emptyCatalog,
                              defaults: defaults,
                              preferences: PrayerNotificationFixture.preferences(alertStyle: .standardTone))
        let recording = try! XCTUnwrap(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))

        subject.selectRecording(recording)

        XCTAssertEqual(subject.preferences.adhanRecordingIdentifier, recording.id)
        XCTAssertEqual(subject.preferences.alertStyle, .standardTone)
        XCTAssertFalse(subject.isShortAdhanToneAvailable)
    }

    func testAnUnknownIdentifierFallsBackToTheDefaultRecording() {
        XCTAssertEqual(bundledCatalog.resolvedRecording(forIdentifier: "no_such_recording")?.id,
                       AdhanRecording.defaultIdentifier)
        XCTAssertEqual(bundledCatalog.resolvedRecording(forIdentifier: "")?.id,
                       AdhanRecording.defaultIdentifier)
        XCTAssertNil(emptyCatalog.resolvedRecording(forIdentifier: AdhanRecording.defaultIdentifier))
    }

    func testTheDefaultRecordingIsBundledAndAvailable() throws {
        let recording = try XCTUnwrap(AdhanRecording.recording(forIdentifier: AdhanRecording.defaultIdentifier))

        XCTAssertTrue(bundledCatalog.isAvailable(recording))
        XCTAssertNotNil(bundledCatalog.notificationSoundFileName(for: recording))
    }

    // MARK: - Playback Resolution

    func testPreviewAndFullPlaybackResolveTheSelectedRecording() throws {
        let defaults = PrayerNotificationFixture.defaults()
        let subject = manager(soundCatalog: bundledCatalog, defaults: defaults)
        let recording = try XCTUnwrap(bundledCatalog.availableRecordings.first)
        let unresolved: [PrayerAdhanPlaybackFailureReason] = [.missingResource, .unreadableResource]

        subject.selectRecording(recording)
        subject.previewNotificationTone(for: recording)
        let toneFailure = subject.lastAdhanPlaybackFailure
        subject.stopAdhanAudio()

        subject.previewFullAdhan(for: recording)
        let fullFailure = subject.lastAdhanPlaybackFailure
        subject.stopAdhanAudio()

        if let toneFailure {
            XCTAssertFalse(unresolved.contains(toneFailure.reason), "tone failed with \(toneFailure.reason)")
        }

        if let fullFailure {
            XCTAssertFalse(unresolved.contains(fullFailure.reason), "full adhan failed with \(fullFailure.reason)")
        }

        XCTAssertEqual(subject.selectedRecording?.id, recording.id)
        XCTAssertTrue(subject.isFullAdhanAudioAvailable)
    }

    func testNotificationsCarryTheSelectedRecordingAsTheirSound() async {
        let center = LocalNotificationCenterDouble(status: .authorized)
        let defaults = PrayerNotificationFixture.defaults()
        let recording = try! XCTUnwrap(bundledCatalog.availableRecordings.last)
        let subject = PrayerNotificationManagerBuilder.manager(center: center,
                                                               defaults: defaults,
                                                               preferences: PrayerNotificationFixture
                                                                   .preferences(slots: [.fajr]),
                                                               now: now,
                                                               soundCatalog: bundledCatalog)

        subject.selectRecording(recording)
        await subject.reschedule(day: PrayerNotificationFixture.day())

        XCTAssertFalse(center.addedDrafts.isEmpty)
        XCTAssertTrue(center.addedDrafts.allSatisfy {
            $0.soundFileName == "\(recording.notificationToneResource).caf"
        })
    }
}
