//
//  RadioPlayer.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import Foundation
import AVFoundation
import Combine
import MediaPlayer

// MARK: - RadioPlayerFailure

enum RadioPlayerFailure {
    case offline
    case timedOut
    case streamFailed
}

// MARK: - RadioPlayer

@MainActor
final class RadioPlayer: NSObject, ObservableObject {

    static let shared = RadioPlayer()

    @Published private(set) var currentStation: RadioStation?
    @Published private(set) var currentTitle: String = ""
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var failure: RadioPlayerFailure?

    private let startTimeout: TimeInterval = 12

    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?
    private var timeoutTask: Task<Void, Never>?
    private var didRetryCurrentStation = false
    private var wasPlayingBeforeDropout = false
    private var cancellables = Set<AnyCancellable>()
    private var sessionConfigured = false

    private override init() {
        super.init()
        observeReachability()
    }

    var hasActiveStation: Bool { currentStation != nil }

    // MARK: - Controls

    func play(station: RadioStation, title: String) {
        guard NetworkReachability.shared.isOnline else {
            currentStation = station
            currentTitle = title
            teardownPlayer()
            isPlaying = false
            isLoading = false
            failure = .offline
            return
        }

        guard let url = station.streamURL else {
            failure = .streamFailed
            return
        }

        didRetryCurrentStation = false
        currentStation = station
        currentTitle = title
        startStream(url: url)
    }

    func resume() {
        guard let station = currentStation else { return }
        guard let player, player.currentItem != nil, failure == nil else {
            play(station: station, title: currentTitle)
            return
        }
        activateSession()
        isLoading = true
        player.play()
        updateNowPlaying()
    }

    func pause() {
        guard let player else { return }
        player.pause()
        isPlaying = false
        isLoading = false
        cancelTimeout()
        updateNowPlaying()
    }

    func toggle() {
        guard let station = currentStation else { return }
        if isPlaying || isLoading {
            pause()
        } else if failure != nil {
            play(station: station, title: currentTitle)
        } else {
            resume()
        }
    }

    func stop() {
        teardownPlayer()
        currentStation = nil
        currentTitle = ""
        isPlaying = false
        isLoading = false
        failure = nil
        wasPlayingBeforeDropout = false
        releaseAudioEngineBridge()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Stream Lifecycle

    private func startStream(url: URL) {
        teardownPlayer()
        failure = nil
        isPlaying = false
        isLoading = true

        claimAudioEngineBridge()
        activateSession()

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        player = newPlayer

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
            let status = observed.status
            Task { @MainActor in
                guard let self else { return }
                if status == .failed { self.handleStreamFailure() }
            }
        }

        timeControlObservation = newPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] observed, _ in
            let status = observed.timeControlStatus
            Task { @MainActor in
                self?.handleTimeControlStatus(status)
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemFailedToPlayToEnd(_:)),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item
        )

        newPlayer.play()
        startTimeoutCountdown()
        updateNowPlaying()
    }

    private func handleTimeControlStatus(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            cancelTimeout()
            isLoading = false
            isPlaying = true
            failure = nil
            didRetryCurrentStation = false
            updateNowPlaying()
        case .waitingToPlayAtSpecifiedRate:
            isPlaying = false
            isLoading = true
        case .paused:
            isPlaying = false
            isLoading = false
            updateNowPlaying()
        @unknown default:
            break
        }
    }

    @objc private func itemFailedToPlayToEnd(_ notification: Notification) {
        Task { @MainActor in
            self.handleStreamFailure()
        }
    }

    private func handleStreamFailure() {
        guard let station = currentStation else { return }

        if !didRetryCurrentStation, NetworkReachability.shared.isOnline, let url = station.streamURL {
            didRetryCurrentStation = true
            startStream(url: url)
            return
        }

        teardownPlayer()
        isPlaying = false
        isLoading = false
        failure = NetworkReachability.shared.isOnline ? .streamFailed : .offline
        updateNowPlaying()
    }

    private func startTimeoutCountdown() {
        cancelTimeout()
        let seconds = startTimeout
        timeoutTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, !Task.isCancelled, self.isLoading, !self.isPlaying else { return }
            self.teardownPlayer()
            self.isLoading = false
            self.isPlaying = false
            self.failure = NetworkReachability.shared.isOnline ? .timedOut : .offline
        }
    }

    private func cancelTimeout() {
        timeoutTask?.cancel()
        timeoutTask = nil
    }

    private func teardownPlayer() {
        cancelTimeout()
        statusObservation?.invalidate()
        statusObservation = nil
        timeControlObservation?.invalidate()
        timeControlObservation = nil
        if let item = player?.currentItem {
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemFailedToPlayToEndTime,
                object: item
            )
        }
        player?.pause()
        player?.replaceCurrentItem(with: nil)
        player = nil
    }

    // MARK: - Reachability

    private func observeReachability() {
        NetworkReachability.shared.$isOnline
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] online in
                Task { @MainActor in
                    self?.handleReachabilityChange(online: online)
                }
            }
            .store(in: &cancellables)
    }

    private func handleReachabilityChange(online: Bool) {
        guard let station = currentStation else { return }

        if !online {
            wasPlayingBeforeDropout = isPlaying || isLoading
            if wasPlayingBeforeDropout {
                teardownPlayer()
                isPlaying = false
                isLoading = false
                failure = .offline
            }
            return
        }

        guard wasPlayingBeforeDropout else { return }
        wasPlayingBeforeDropout = false
        didRetryCurrentStation = false
        play(station: station, title: currentTitle)
    }

    // MARK: - Audio Session

    private func activateSession() {
        let session = AVAudioSession.sharedInstance()
        if !sessionConfigured {
            try? session.setCategory(.playback, mode: .default)
            sessionConfigured = true
        }
        try? session.setActive(true)
    }

    // MARK: - AudioEngine Bridge

    private func claimAudioEngineBridge() {
        let engine = AudioEngine.shared
        engine.radioActive = true
        engine.radioRemotePlay = { [weak self] in self?.resume() }
        engine.radioRemotePause = { [weak self] in self?.pause() }
        engine.radioStop = { [weak self] in self?.stop() }
        engine.stop()

        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.changePlaybackRateCommand.isEnabled = false
    }

    private func releaseAudioEngineBridge() {
        let engine = AudioEngine.shared
        engine.radioActive = false
        engine.radioRemotePlay = nil
        engine.radioRemotePause = nil
        engine.radioStop = nil

        let center = MPRemoteCommandCenter.shared()
        center.nextTrackCommand.isEnabled = true
        center.previousTrackCommand.isEnabled = true
        center.changePlaybackRateCommand.isEnabled = true
    }

    // MARK: - Now Playing

    private func updateNowPlaying() {
        guard currentStation != nil else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = currentTitle
        info[MPMediaItemPropertyArtist] = AppLocalizedKeys.radio.value
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
