//
//  AthkarItemAudioPlayer.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import AVFoundation
import Combine
import Core

// MARK: - Playback contract

@MainActor
protocol AthkarAudioPlaying: AnyObject {

    var playingItemID: Int? { get }
    var isPaused: Bool { get }
    var currentRepetition: Int { get }
    var totalRepetitions: Int { get }
    var onFinished: (@MainActor (Int) -> Void)? { get set }
    var stateChanges: AnyPublisher<Void, Never> { get }
    var failures: AnyPublisher<Void, Never> { get }

    func isPlaying(itemID: Int) -> Bool
    func isActive(itemID: Int) -> Bool
    func canPlay(item: AthkarItem, inPack packKey: String) -> Bool
    func toggle(item: AthkarItem, inPack packKey: String)
    func play(item: AthkarItem, inPack packKey: String)
    func stop()
    func clearFailure()
}

// MARK: - Player

@MainActor
final class AthkarItemAudioPlayer: ObservableObject, AthkarAudioPlaying {

    static let autoRepeatCountLimit: Int = 10

    @Published private(set) var playingItemID: Int?
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var hasFailed: Bool = false
    @Published private(set) var currentRepetition: Int = 0
    @Published private(set) var totalRepetitions: Int = 0

    var onFinished: (@MainActor (Int) -> Void)?

    private let downloads: AthkarAudioDownloadManager
    private let notificationCenter: NotificationCenter
    private let searchExtensions = ["m4a", "mp3", "aac", "caf"]
    private let subdirectory = "Audio"

    private var player: AVAudioPlayer?
    private var playerDelegate: AthkarItemAudioPlayerDelegate?
    private var generation: Int = 0
    private var targetPlays: Int = 1
    private var interruptionObserver: NSObjectProtocol?
    private var routeChangeObserver: NSObjectProtocol?
    private var isResumableAfterInterruption: Bool = false
    private var isSessionCategoryConfigured: Bool = false

    init(notificationCenter: NotificationCenter = .default, downloads: AthkarAudioDownloadManager = .shared) {
        self.notificationCenter = notificationCenter
        self.downloads = downloads
        observeInterruptions()
        observeRouteChanges()
    }

    deinit {
        if let interruptionObserver {
            notificationCenter.removeObserver(interruptionObserver)
        }

        if let routeChangeObserver {
            notificationCenter.removeObserver(routeChangeObserver)
        }
    }

    // MARK: - Publishers

    var stateChanges: AnyPublisher<Void, Never> {
        $playingItemID
            .map { _ in () }
            .merge(with: $isPaused.map { _ in () })
            .merge(with: $currentRepetition.map { _ in () })
            .eraseToAnyPublisher()
    }

    var failures: AnyPublisher<Void, Never> {
        $hasFailed
            .filter { $0 }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Repetition policy

    static func audioPlayCount(forRepeatCount count: Int) -> Int {
        let repetitions = max(count, 1)
        return repetitions <= autoRepeatCountLimit ? repetitions : 1
    }

    static func heldRepetitionCount(forRepeatCount count: Int) -> Int {
        max(count, 1)
    }

    // MARK: - Queries

    var isActive: Bool { playingItemID != nil }

    func isPlaying(itemID: Int) -> Bool {
        playingItemID == itemID && !isPaused
    }

    func isActive(itemID: Int) -> Bool {
        playingItemID == itemID
    }

    func canPlay(item: AthkarItem, inPack packKey: String) -> Bool {
        url(for: item, inPack: packKey) != nil
    }

    // MARK: - Transport

    func toggle(item: AthkarItem, inPack packKey: String) {
        guard playingItemID == item.id else {
            play(item: item, inPack: packKey)
            return
        }
        if isPaused { resume() } else { pause() }
    }

    func play(item: AthkarItem, inPack packKey: String) {
        teardown()
        hasFailed = false

        guard let url = url(for: item, inPack: packKey) else {
            hasFailed = true
            return
        }

        do {
            try activateSession()

            let player = try AVAudioPlayer(contentsOf: url)
            attachDelegate(to: player)
            self.player = player

            guard player.play() else {
                teardown()
                hasFailed = true
                return
            }

            playingItemID = item.id
            isPaused = false
            targetPlays = Self.audioPlayCount(forRepeatCount: item.count)
            totalRepetitions = Self.heldRepetitionCount(forRepeatCount: item.count)
            currentRepetition = 1
        } catch {
            teardown()
            hasFailed = true
        }
    }

    func pause() {
        guard let player, isActive, !isPaused else { return }
        player.pause()
        isPaused = true
    }

    func resume() {
        guard let player, isActive, isPaused else { return }

        guard player.play() else {
            stop()
            hasFailed = true
            return
        }

        isPaused = false
    }

    func stop() {
        guard isActive else {
            teardown()
            return
        }

        teardown()
        deactivateSession()
    }

    func clearFailure() { hasFailed = false }

    // MARK: - Completion

    private func handleFinish(token: Int, didSucceed: Bool) {
        guard token == generation, let finishedItemID = playingItemID else { return }

        guard didSucceed else {
            teardown()
            hasFailed = true
            deactivateSession()
            return
        }

        if currentRepetition < targetPlays, let player {
            currentRepetition += 1
            player.currentTime = 0
            attachDelegate(to: player)

            guard player.play() else {
                teardown()
                hasFailed = true
                deactivateSession()
                return
            }

            return
        }

        teardown()
        onFinished?(finishedItemID)

        if !isActive { deactivateSession() }
    }

    private func attachDelegate(to player: AVAudioPlayer) {
        generation += 1

        let delegate = AthkarItemAudioPlayerDelegate(token: generation) { [weak self] token, didSucceed in
            self?.handleFinish(token: token, didSucceed: didSucceed)
        }

        player.delegate = delegate
        playerDelegate = delegate
    }

    // MARK: - Interruptions

    private func observeInterruptions() {
        interruptionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated { self?.handleInterruption(notification) }
        }
    }

    private func observeRouteChanges() {
        routeChangeObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated { self?.handleRouteChange(notification) }
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable
        else { return }

        pause()
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            guard isActive, !isPaused else { return }
            pause()
            isResumableAfterInterruption = true

        case .ended:
            guard isResumableAfterInterruption else { return }
            isResumableAfterInterruption = false

            let shouldResume = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
                .flatMap { AVAudioSession.InterruptionOptions(rawValue: $0) }
                .map { $0.contains(.shouldResume) } ?? false

            guard shouldResume else { return }
            try? activateSession()
            resume()

        @unknown default:
            break
        }
    }

    // MARK: - Session

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()

        if !isSessionCategoryConfigured {
            try session.setCategory(.playback, mode: .default)
            isSessionCategoryConfigured = true
        }

        try session.setActive(true)
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Teardown

    private func teardown() {
        generation += 1
        player?.stop()
        player?.delegate = nil
        player = nil
        playerDelegate = nil
        playingItemID = nil
        isPaused = false
        currentRepetition = 0
        totalRepetitions = 0
        targetPlays = 1
        isResumableAfterInterruption = false
    }

    // MARK: - Resources

    private func url(for item: AthkarItem, inPack packKey: String) -> URL? {
        guard item.hasAudio else { return nil }

        if let downloaded = downloads.localURL(for: item, inPack: packKey) { return downloaded }

        let name = (item.audio as NSString).deletingPathExtension
        let declared = (item.audio as NSString).pathExtension
        let candidates = declared.isEmpty
            ? searchExtensions
            : [declared] + searchExtensions.filter { $0 != declared }

        for ext in candidates {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }

        return nil
    }
}

// MARK: - Delegate

private final class AthkarItemAudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {

    private let token: Int
    private let onFinish: @MainActor (Int, Bool) -> Void
    private var hasReported = false

    init(token: Int, onFinish: @escaping @MainActor (Int, Bool) -> Void) {
        self.token = token
        self.onFinish = onFinish
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        report(didSucceed: flag)
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        report(didSucceed: false)
    }

    private func report(didSucceed: Bool) {
        guard !hasReported else { return }
        hasReported = true

        let token = self.token
        let onFinish = self.onFinish
        Task { @MainActor in onFinish(token, didSucceed) }
    }
}
