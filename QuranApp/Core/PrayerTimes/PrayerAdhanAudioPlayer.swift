//
//  PrayerAdhanAudioPlayer.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 02/11/2026.
//

import Foundation
import AVFoundation

enum PrayerAdhanPlaybackMode: Equatable {
    case notificationTonePreview
    case fullAdhan
}

enum PrayerAdhanPlaybackFailureReason: Equatable {
    case missingResource
    case unreadableResource
    case audioSessionUnavailable
}

struct PrayerAdhanPlaybackFailure: Equatable {

    let reason: PrayerAdhanPlaybackFailureReason
    let recordingIdentifier: String
    let mode: PrayerAdhanPlaybackMode
}

@MainActor
final class PrayerAdhanAudioPlayer {

    private let soundCatalog: PrayerNotificationSoundCatalog
    private let audioFocus: AdhanAudioFocus
    private let faceDownDetector: DeviceFaceDownDetector
    private let notificationCenter: NotificationCenter

    private var player: AVAudioPlayer?
    private var playerDelegate: PrayerAdhanAudioPlayerDelegate?
    private var generation: Int = 0
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var isResumableAfterInterruption: Bool = false
    private var isSessionCategoryConfigured: Bool = false

    private(set) var playingRecordingIdentifier: String?
    private(set) var playingMode: PrayerAdhanPlaybackMode?
    private(set) var lastFailure: PrayerAdhanPlaybackFailure?

    var onPlaybackStateChange: (@MainActor () -> Void)?

    init(soundCatalog: PrayerNotificationSoundCatalog,
         audioFocus: AdhanAudioFocus? = nil,
         faceDownDetector: DeviceFaceDownDetector? = nil,
         notificationCenter: NotificationCenter = .default) {
        self.soundCatalog = soundCatalog
        self.audioFocus = audioFocus ?? AppAdhanAudioFocus()
        self.faceDownDetector = faceDownDetector ?? MotionDeviceFaceDownDetector()
        self.notificationCenter = notificationCenter
        observeInterruptions()
        observeRouteChanges()
        observeFaceDownPlacement()
    }

    deinit {
        if let interruptionObserver {
            notificationCenter.removeObserver(interruptionObserver)
        }

        if let routeChangeObserver {
            notificationCenter.removeObserver(routeChangeObserver)
        }
    }

    // MARK: - State

    var isPlaying: Bool { player?.isPlaying ?? false }

    func isPlaying(_ recording: AdhanRecording, mode: PrayerAdhanPlaybackMode) -> Bool {
        playingRecordingIdentifier == recording.id && playingMode == mode && isPlaying
    }

    // MARK: - Playback

    func playFullAdhan(for recording: AdhanRecording) {
        play(url: soundCatalog.fullAdhanAudioURL(for: recording), recording: recording, mode: .fullAdhan)
    }

    func playNotificationTonePreview(for recording: AdhanRecording) {
        play(url: soundCatalog.shortAdhanToneURL(for: recording),
             recording: recording,
             mode: .notificationTonePreview)
    }

    func stop() {
        guard playingRecordingIdentifier != nil || lastFailure != nil else { return }
        teardownPlayer()
        deactivateSession()
        lastFailure = nil
        onPlaybackStateChange?()
    }
}

// MARK: - Playback Pipeline

private extension PrayerAdhanAudioPlayer {

    func play(url: URL?, recording: AdhanRecording, mode: PrayerAdhanPlaybackMode) {
        lastFailure = nil

        guard let url else {
            report(.missingResource, recording: recording, mode: mode)
            return
        }

        teardownPlayer()
        audioFocus.pauseCompetingPlayback()

        do {
            try activateSession()
        } catch {
            report(.audioSessionUnavailable, recording: recording, mode: mode)
            return
        }

        guard let newPlayer = try? AVAudioPlayer(contentsOf: url) else {
            deactivateSession()
            report(.unreadableResource, recording: recording, mode: mode)
            return
        }

        attachDelegate(to: newPlayer)
        player = newPlayer
        playingRecordingIdentifier = recording.id
        playingMode = mode
        newPlayer.prepareToPlay()
        newPlayer.play()
        startFaceDownMonitoringIfNeeded()
        onPlaybackStateChange?()
    }

    func report(_ reason: PrayerAdhanPlaybackFailureReason,
                recording: AdhanRecording,
                mode: PrayerAdhanPlaybackMode) {
        let failure = PrayerAdhanPlaybackFailure(reason: reason,
                                                 recordingIdentifier: recording.id,
                                                 mode: mode)
        lastFailure = failure
        onPlaybackStateChange?()
    }

    func attachDelegate(to player: AVAudioPlayer) {
        generation += 1

        let delegate = PrayerAdhanAudioPlayerDelegate(token: generation) { [weak self] token in
            self?.handleFinish(token: token)
        }

        player.delegate = delegate
        playerDelegate = delegate
    }

    func handleFinish(token: Int) {
        guard token == generation else { return }
        stop()
    }

    func teardownPlayer() {
        generation += 1
        faceDownDetector.stopMonitoring()
        player?.stop()
        player?.delegate = nil
        player = nil
        playerDelegate = nil
        playingRecordingIdentifier = nil
        playingMode = nil
        isResumableAfterInterruption = false
    }
}

// MARK: - Session

private extension PrayerAdhanAudioPlayer {

    func activateSession() throws {
        let session = AVAudioSession.sharedInstance()

        if !isSessionCategoryConfigured {
            try session.setCategory(.playback, mode: .default)
            isSessionCategoryConfigured = true
        }

        try session.setActive(true)
    }

    func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Interruptions

private extension PrayerAdhanAudioPlayer {

    func observeInterruptions() {
        interruptionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated { self?.handleInterruption(notification) }
        }
    }

    func observeRouteChanges() {
        routeChangeObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated { self?.handleRouteChange(notification) }
        }
    }

    func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            guard isPlaying else { return }
            player?.pause()
            faceDownDetector.stopMonitoring()
            isResumableAfterInterruption = true
            onPlaybackStateChange?()

        case .ended:
            guard isResumableAfterInterruption else { return }
            isResumableAfterInterruption = false

            let shouldResume = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
                .flatMap { AVAudioSession.InterruptionOptions(rawValue: $0) }
                .map { $0.contains(.shouldResume) } ?? false

            guard shouldResume else {
                stop()
                return
            }

            try? activateSession()
            player?.play()
            startFaceDownMonitoringIfNeeded()
            onPlaybackStateChange?()

        @unknown default:
            break
        }
    }

    func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable
        else { return }

        stop()
    }
}

// MARK: - Face Down

private extension PrayerAdhanAudioPlayer {

    func observeFaceDownPlacement() {
        faceDownDetector.onFaceDown = { [weak self] in
            self?.stop()
        }
    }

    func startFaceDownMonitoringIfNeeded() {
        guard playingMode == .fullAdhan else { return }
        faceDownDetector.startMonitoring()
    }
}

// MARK: - Delegate

private final class PrayerAdhanAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {

    private let token: Int
    private let onFinish: @MainActor (Int) -> Void
    private var hasReported = false

    init(token: Int, onFinish: @escaping @MainActor (Int) -> Void) {
        self.token = token
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        report()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        report()
    }

    private func report() {
        guard !hasReported else { return }
        hasReported = true

        let token = self.token
        let onFinish = self.onFinish
        Task { @MainActor in onFinish(token) }
    }
}
