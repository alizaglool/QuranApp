//
//  AudioEngine.swift
//  QuranApp
//

import AVFoundation
import Combine
import MediaPlayer
import Foundation

// MARK: - PlayToMode

enum PlayToMode {
    case continuous
    case endOfSurah
    case endOfPage(page: Int)
    case stopAtVerse(surah: Int, verse: Int)
}

// MARK: - RepeatMode

enum RepeatMode: String, CaseIterable {
    case off, verse, surah

    var label: String {
        switch self {
        case .off:   return "إيقاف التكرار"
        case .verse: return "تكرار الآية"
        case .surah: return "تكرار السورة"
        }
    }

    var icon: String {
        switch self {
        case .off:   return "repeat"
        case .verse: return "repeat.1"
        case .surah: return "repeat"
        }
    }
}

// MARK: - AudioEngine

@MainActor
final class AudioEngine: NSObject, ObservableObject {

    static let shared = AudioEngine()

    @Published var isPlaying: Bool = false
    @Published var currentSurahNumber: Int = 1
    @Published var currentVerseNumber: Int = 1
    @Published var currentReciter: ReciterInfo = ReciterLibrary.all[0]
    @Published var playbackSpeed: Float = 1.0
    @Published var repeatMode: RepeatMode = .off
    @Published var verseProgress: Double = 0.0
    @Published var isLoadingVerse: Bool = false
    @Published var errorMessage: String? = nil
    @Published var verseDuration: TimeInterval = 0
    @Published var verseElapsed: TimeInterval = 0
    @Published var repeatRangeEnabled: Bool = false
    @Published var repeatVerseEnabled: Bool = false
    @Published var playSurahMode: Bool = false
    @Published var repeatFromSurah: Int = 1
    @Published var repeatFromVerse: Int = 1
    @Published var repeatToSurah: Int = 1
    @Published var repeatToVerse: Int = 7
    @Published var rangeRepeatCount: Int = 0
    @Published var verseRepeatCount: Int = 0
    /// Set to true while QuranPagerView's overlay is open so the global
    /// TabBarController mini player hides itself and avoids duplication.
    @Published var quranOverlayActive: Bool = false
    /// Set to true for the entire lifetime of QuranPagerView (appear → disappear).
    /// Suppresses the global TabBar mini player whenever the user is on the Quran screen,
    /// regardless of whether the overlay is currently visible.
    @Published var isQuranScreenActive: Bool = false
    @Published var playToMode: PlayToMode = .continuous

    private var currentVerseIteration: Int = 0
    private var currentRangeIteration: Int = 0
    private var pendingVerseAfterBismillah: Int? = nil

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    private var downloadTask: URLSessionDataTask?
    private let storage = StorageManager.shared

    private let speedOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    override private init() {
        super.init()
        loadSavedProgress()
        setupRemoteCommands()
        setupNotificationObservers()
    }

    // MARK: - Playback

    func play(surahNumber: Int, verseNumber: Int) {
        currentVerseIteration = 0
        currentRangeIteration = 0
        errorMessage = nil
        beginPlayback(surah: surahNumber, verse: verseNumber)
    }

    /// Play from a specific position without any range/verse-repeat constraints.
    /// Clears repeat and surah-mode so playback continues naturally through the Quran.
    func playFrom(surahNumber: Int, verseNumber: Int) {
        repeatRangeEnabled = false
        repeatVerseEnabled = false
        repeatMode = .off
        playSurahMode = false
        currentRangeIteration = 0
        currentVerseIteration = 0
        play(surahNumber: surahNumber, verseNumber: verseNumber)
    }

    /// Play the entire surah from verse 1 and stop automatically at the last verse.
    func playWholeSurah(surahNumber: Int) {
        playSurahMode = true
        repeatRangeEnabled = false
        repeatVerseEnabled = false
        repeatMode = .off
        currentRangeIteration = 0
        currentVerseIteration = 0
        play(surahNumber: surahNumber, verseNumber: 1)
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingPlaybackState()
        persistCurrentPosition()
    }

    func resume() {
        guard let player = audioPlayer else {
            loadAndPlay()
            return
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        player.rate = playbackSpeed
        player.play()
        isPlaying = true
        startProgressTimer()
        updateNowPlayingPlaybackState()
    }

    func stop() {
        pendingVerseAfterBismillah = nil
        playToMode = .continuous
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        verseProgress = 0
        verseElapsed = 0
        currentVerseIteration = 0
        currentRangeIteration = 0
        stopProgressTimer()
        deactivateAudioSession()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func nextVerse() {
        pendingVerseAfterBismillah = nil
        let total = ReciterLibrary.verseCounts[currentSurahNumber] ?? 1
        if currentVerseNumber < total {
            play(surahNumber: currentSurahNumber, verseNumber: currentVerseNumber + 1)
        } else if currentSurahNumber < 114 {
            play(surahNumber: currentSurahNumber + 1, verseNumber: 1)
        } else {
            stop()
        }
    }

    func previousVerse() {
        pendingVerseAfterBismillah = nil
        if currentVerseNumber > 1 {
            play(surahNumber: currentSurahNumber, verseNumber: currentVerseNumber - 1)
        } else if currentSurahNumber > 1 {
            let prevSurah = currentSurahNumber - 1
            let lastVerse = ReciterLibrary.verseCounts[prevSurah] ?? 1
            play(surahNumber: prevSurah, verseNumber: lastVerse)
        }
    }

    func seek(to fraction: Double) {
        guard let player = audioPlayer else { return }
        let time = player.duration * fraction
        player.currentTime = time
        verseElapsed = time
        verseProgress = fraction
        updateNowPlayingElapsed()
    }

    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        audioPlayer?.rate = speed
        storage.updateAudioProgress { $0.playbackSpeed = speed }
        updateNowPlayingElapsed()
    }

    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
        switch mode {
        case .off:
            repeatRangeEnabled = false
            repeatVerseEnabled = false
        case .verse:
            repeatVerseEnabled = true
            repeatRangeEnabled = false
        case .surah:
            repeatRangeEnabled = true
            repeatVerseEnabled = false
            let total = ReciterLibrary.verseCounts[currentSurahNumber] ?? 1
            repeatFromSurah = currentSurahNumber
            repeatFromVerse = 1
            repeatToSurah   = currentSurahNumber
            repeatToVerse   = total
        }
        storage.updateAudioProgress { $0.repeatMode = mode.rawValue }
    }

    func cycleRepeatMode() {
        let all = RepeatMode.allCases
        let idx = all.firstIndex(of: repeatMode) ?? 0
        setRepeatMode(all[(idx + 1) % all.count])
    }

    func setRepeatRange(enabled: Bool) {
        repeatRangeEnabled = enabled
        if enabled {
            repeatVerseEnabled = false
            repeatMode = .surah
        } else if !repeatVerseEnabled {
            repeatMode = .off
        }
        persistCurrentPosition()
    }

    func setRepeatVerse(enabled: Bool) {
        repeatVerseEnabled = enabled
        if enabled {
            repeatRangeEnabled = false
            repeatMode = .verse
        } else if !repeatRangeEnabled {
            repeatMode = .off
        }
        persistCurrentPosition()
    }

    func switchReciter(_ reciter: ReciterInfo) {
        let s = currentSurahNumber
        let v = currentVerseNumber
        currentReciter = reciter
        storage.updateAudioProgress { $0.reciterSlug = reciter.id }
        if hasActiveVerse {
            play(surahNumber: s, verseNumber: v)
        }
    }

    var currentSurahArabicName: String {
        ReciterLibrary.surahArabicNames[currentSurahNumber] ?? "سورة \(currentSurahNumber)"
    }

    var hasActiveVerse: Bool {
        audioPlayer != nil || isPlaying || isLoadingVerse
    }

    var nextSpeedLabel: String {
        let idx = speedOptions.firstIndex(of: playbackSpeed) ?? 2
        let next = speedOptions[(idx + 1) % speedOptions.count]
        return formatSpeed(next)
    }

    var currentSpeedLabel: String { formatSpeed(playbackSpeed) }

    func cycleSpeed() {
        let idx = speedOptions.firstIndex(of: playbackSpeed) ?? 2
        setSpeed(speedOptions[(idx + 1) % speedOptions.count])
    }

    // MARK: - Internal load

    private func beginPlayback(surah: Int, verse: Int) {
        currentSurahNumber = surah
        currentVerseNumber = verse
        // Play Bismillah (verse 0) before verse 1 for surahs 2-114 except At-Tawbah (9)
        if verse == 1 && surah != 1 && surah != 9 {
            pendingVerseAfterBismillah = 1
            loadAndPlay(verseOverride: 0)
        } else {
            pendingVerseAfterBismillah = nil
            loadAndPlay()
        }
    }

    private func loadAndPlay(verseOverride: Int? = nil) {
        downloadTask?.cancel()
        stopProgressTimer()
        audioPlayer?.stop()
        audioPlayer = nil

        let surah = currentSurahNumber
        let verse = verseOverride ?? currentVerseNumber

        // Try local file first (only if it was actually downloaded)
        if DownloadManager.shared.isAvailable(reciterSlug: currentReciter.id, surahNumber: surah, verseNumber: verse),
           let localURL = DownloadManager.shared.localURL(reciterSlug: currentReciter.id, surahNumber: surah, verseNumber: verse) {
            playFromURL(localURL, surah: surah, verse: verse)
            return
        }

        // Stream from EveryAyah.com
        let remoteURL = ReciterLibrary.everyAyahURL(reciter: currentReciter.id, surah: surah, verse: verse)
        isLoadingVerse = true

        let task = URLSession.shared.dataTask(with: remoteURL) { [weak self] data, response, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isLoadingVerse = false

                if let error = error as? URLError, error.code == .cancelled { return }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 404 {
                    // If Bismillah file missing for this reciter, skip directly to verse 1
                    if verseOverride == 0 {
                        self.pendingVerseAfterBismillah = nil
                        self.loadAndPlay()
                    } else {
                        self.errorMessage = "الآية غير متوفرة لهذا القارئ"
                    }
                    return
                }

                guard let data, error == nil else {
                    self.errorMessage = "تعذّر تحميل الآية"
                    return
                }

                // Write to temp file so AVAudioPlayer can read it
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(self.currentReciter.id)_\(surah)_\(verse).mp3")
                try? data.write(to: tmpURL)
                self.playFromURL(tmpURL, surah: surah, verse: verse)
            }
        }
        downloadTask = task
        task.resume()
    }

    private func playFromURL(_ url: URL, surah: Int, verse: Int) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.enableRate = true
            player.rate = playbackSpeed
            player.prepareToPlay()
            player.play()

            audioPlayer = player
            isPlaying = true
            verseDuration = player.duration
            verseElapsed = 0
            verseProgress = 0

            persistCurrentPosition()
            updateNowPlayingInfo()
            startProgressTimer()
        } catch {
            errorMessage = "تعذّر تشغيل الآية"
            isPlaying = false
        }
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func tickProgress() {
        guard let player = audioPlayer, player.isPlaying else { return }
        verseElapsed = player.currentTime
        verseDuration = player.duration
        verseProgress = player.duration > 0 ? player.currentTime / player.duration : 0
        updateNowPlayingElapsed()
    }

    // MARK: - Persist

    private func persistCurrentPosition() {
        let surah   = currentSurahNumber
        let verse   = currentVerseNumber
        let slug    = currentReciter.id
        let speed   = playbackSpeed
        let mode    = repeatMode.rawValue
        let rRange  = repeatRangeEnabled
        let rVerse  = repeatVerseEnabled
        let fromS   = repeatFromSurah
        let fromV   = repeatFromVerse
        let toS     = repeatToSurah
        let toV     = repeatToVerse
        let rRCount = rangeRepeatCount
        let rVCount = verseRepeatCount
        storage.updateAudioProgress {
            $0.surahNumber        = surah
            $0.verseNumber        = verse
            $0.reciterSlug        = slug
            $0.playbackSpeed      = speed
            $0.repeatMode         = mode
            $0.repeatRangeEnabled = rRange
            $0.repeatVerseEnabled = rVerse
            $0.repeatFromSurah    = fromS
            $0.repeatFromVerse    = fromV
            $0.repeatToSurah      = toS
            $0.repeatToVerse      = toV
            $0.rangeRepeatCount   = rRCount
            $0.verseRepeatCount   = rVCount
        }
    }

    private func loadSavedProgress() {
        guard let saved = storage.getAudioProgress() else { return }
        currentSurahNumber  = saved.surahNumber
        currentVerseNumber  = saved.verseNumber
        playbackSpeed       = saved.playbackSpeed
        repeatMode          = RepeatMode(rawValue: saved.repeatMode) ?? .off
        repeatRangeEnabled  = saved.repeatRangeEnabled
        repeatVerseEnabled  = saved.repeatVerseEnabled
        repeatFromSurah     = saved.repeatFromSurah
        repeatFromVerse     = saved.repeatFromVerse
        repeatToSurah       = saved.repeatToSurah
        repeatToVerse       = saved.repeatToVerse
        rangeRepeatCount    = saved.rangeRepeatCount
        verseRepeatCount    = saved.verseRepeatCount
        if let reciter = ReciterLibrary.reciter(for: saved.reciterSlug) {
            currentReciter = reciter
        }
    }

    // MARK: - AVAudioSession

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Lock Screen (MPNowPlayingInfoCenter)

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.pause() }
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.nextVerse() }
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor [weak self] in self?.previousVerse() }
            return .success
        }
        center.changePlaybackRateCommand.supportedPlaybackRates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        center.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            Task { @MainActor [weak self] in self?.setSpeed(Float(e.playbackRate)) }
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle]            = currentSurahArabicName
        info[MPMediaItemPropertyAlbumTitle]       = "آية \(currentVerseNumber)"
        info[MPMediaItemPropertyArtist]           = currentReciter.arabicName
        info[MPMediaItemPropertyPlaybackDuration] = audioPlayer?.duration ?? 0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        info[MPNowPlayingInfoPropertyPlaybackRate] = playbackSpeed
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingElapsed() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer?.currentTime ?? 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackSpeed) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingPlaybackState() {
        guard var info = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? Double(playbackSpeed) : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Notification Observers

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            persistCurrentPosition()
            isPlaying = false
            stopProgressTimer()

        case .ended:
            let shouldResume = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
                .flatMap { AVAudioSession.InterruptionOptions(rawValue: $0) }
                .map { $0.contains(.shouldResume) } ?? false
            if shouldResume { resume() }

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        // Pause when headphones are unplugged (standard iOS behavior)
        if reason == .oldDeviceUnavailable {
            persistCurrentPosition()
            pause()
        }
    }

    // MARK: - Helpers

    private func formatSpeed(_ speed: Float) -> String {
        speed == Float(Int(speed)) ? "\(Int(speed))×" : "\(speed)×"
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioEngine: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        Task { @MainActor in self.autoAdvance() }
    }

    private func autoAdvance() {
        // Bismillah finished — load the actual verse 1
        if let pending = pendingVerseAfterBismillah {
            pendingVerseAfterBismillah = nil
            currentVerseNumber = pending
            loadAndPlay()
            return
        }

        if repeatVerseEnabled {
            if verseRepeatCount == 0 || currentVerseIteration + 1 < verseRepeatCount {
                currentVerseIteration += 1
                loadAndPlay()
            } else {
                currentVerseIteration = 0
                advanceToNextVerse()
            }
        } else if repeatRangeEnabled {
            let pastEnd = currentSurahNumber > repeatToSurah ||
                          (currentSurahNumber == repeatToSurah && currentVerseNumber >= repeatToVerse)
            if !pastEnd {
                advanceToNextVerse()
            } else if rangeRepeatCount == 0 || currentRangeIteration + 1 < rangeRepeatCount {
                currentRangeIteration += 1
                beginPlayback(surah: repeatFromSurah, verse: repeatFromVerse)
            } else {
                currentRangeIteration = 0
                stop()
            }
        } else {
            advanceToNextVerse()
        }
    }

    private func advanceToNextVerse() {
        // Check play-to stop conditions before advancing
        switch playToMode {
        case .endOfSurah:
            let total = ReciterLibrary.verseCounts[currentSurahNumber] ?? 1
            if currentVerseNumber >= total {
                playToMode = .continuous
                stop()
                return
            }
        case .endOfPage(let targetPage):
            // Calculate what the next verse would be
            let total = ReciterLibrary.verseCounts[currentSurahNumber] ?? 1
            let nextSurah: Int
            let nextVerse: Int
            if currentVerseNumber < total {
                nextSurah = currentSurahNumber
                nextVerse = currentVerseNumber + 1
            } else if currentSurahNumber < 114 {
                nextSurah = currentSurahNumber + 1
                nextVerse = 1
            } else {
                playToMode = .continuous
                stop()
                return
            }
            let nextPage = QuranDatabase.shared.getPage(forSurah: nextSurah, verse: nextVerse)
            if nextPage != targetPage {
                playToMode = .continuous
                stop()
                return
            }
        case .stopAtVerse(let stopSurah, let stopVerse):
            if currentSurahNumber > stopSurah ||
               (currentSurahNumber == stopSurah && currentVerseNumber >= stopVerse) {
                playToMode = .continuous
                stop()
                return
            }
        case .continuous:
            break
        }

        let total = ReciterLibrary.verseCounts[currentSurahNumber] ?? 1
        if currentVerseNumber < total {
            currentVerseNumber += 1
            loadAndPlay()
        } else if playSurahMode {
            // Surah finished — stop and leave mode active for next play
            stop()
        } else if currentSurahNumber < 114 {
            beginPlayback(surah: currentSurahNumber + 1, verse: 1)
        } else {
            stop()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.errorMessage = "خطأ في تشغيل الملف الصوتي"
            self.isPlaying = false
        }
    }
}
