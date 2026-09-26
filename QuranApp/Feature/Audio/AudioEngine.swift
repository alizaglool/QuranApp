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
    // Same reason as the repeat mutators: flipping this after a handoff is pinned
    // would let the wrong verse play off the audio clock. `didSet` covers the direct
    // writes from the View, which has no setter to route through.
    @Published var playSurahMode: Bool = false {
        didSet { cancelScheduledHandoff() }
    }
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
    private var prefetchTask: URLSessionDataTask?
    private var prefetchedTarget: (surah: Int, verse: Int)?
    /// The verse whose file is actually loaded in `audioPlayer`. This is not always
    /// `currentVerseNumber`: while the Bismillah plays it is verse 0 of the surah.
    private var activeTarget: (surah: Int, verse: Int)?
    private var scheduledHandoff: ScheduledHandoff?
    /// One scheduling attempt per verse — the progress timer would otherwise retry
    /// on every tick once the lead window opens.
    private var handoffAttempted = false
    private var sessionCategoryConfigured = false
    private var persistWorkItem: Task<Void, Never>?
    private let storage = StorageManager.shared

    /// Arm the next player this far (wall-clock seconds) before the current verse
    /// ends: long enough to decode a header off disk, short enough that a seek or a
    /// speed change rarely lands inside the window.
    private static let handoffLeadTime: TimeInterval = 1.0
    /// Below this, `play(atTime:)` has no room left to preroll; the delegate path
    /// takes over instead.
    private static let handoffMinimumLead: TimeInterval = 0.05

    private let speedOptions: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    /// Verse N+1, already decoded and pinned to the shared audio clock while verse N
    /// is still audible. `source` is the verse the target was derived from, so the
    /// target can be re-validated before it is adopted.
    private struct ScheduledHandoff {
        let player: AVAudioPlayer
        let target: (surah: Int, verse: Int)
        let source: (surah: Int, verse: Int)
        let reciter: String
    }

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
        cancelScheduledHandoff()
        downloadTask?.cancel()
        downloadTask = nil
        isLoadingVerse = false
        audioPlayer?.pause()
        isPlaying = false
        stopProgressTimer()
        updateNowPlayingPlaybackState()
        persistCurrentPosition()
    }

    func resume() {
        cancelScheduledHandoff()
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
        cancelScheduledHandoff()
        cancelPrefetch()
        // Without this the in-flight first-verse download completes and plays after
        // the user already stopped. Only `loadAndPlay()` cancelled it before.
        downloadTask?.cancel()
        downloadTask = nil
        isLoadingVerse = false
        audioPlayer?.stop()
        audioPlayer = nil
        activeTarget = nil
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
        // The scheduled start time was pinned to the old play head; it is wrong now.
        cancelScheduledHandoff()
        let time = player.duration * fraction
        player.currentTime = time
        verseElapsed = time
        verseProgress = fraction
        updateNowPlayingElapsed()
    }

    func setSpeed(_ speed: Float) {
        // Remaining wall-clock time changes with the rate, so any pinned handoff
        // would now fire at the wrong instant.
        cancelScheduledHandoff()
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
        // A pinned handoff was scheduled under the old repeat rule; it would play the
        // wrong verse. Drop it and let the normal path re-arm.
        cancelScheduledHandoff()
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
        cancelScheduledHandoff()
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
        cancelScheduledHandoff()
    }

    func switchReciter(_ reciter: ReciterInfo) {
        let s = currentSurahNumber
        let v = currentVerseNumber
        currentReciter = reciter
        storage.updateAudioProgress { $0.reciterSlug = reciter.id }
        // Anything warmed or already decoded belongs to the previous voice.
        cancelScheduledHandoff()
        cancelPrefetch()
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
        // Deliberately does NOT cancel `prefetchTask`: the verse being loaded here is
        // usually the one the prefetcher is already fetching, and killing it would
        // re-open the gap this whole path exists to close.
        downloadTask?.cancel()
        cancelScheduledHandoff()
        stopProgressTimer()
        audioPlayer?.stop()
        audioPlayer = nil
        activeTarget = nil

        let surah = currentSurahNumber
        let verse = verseOverride ?? currentVerseNumber

        // Downloaded file first, then the stream cache: a verse already fetched in
        // this session (repeat, re-listen, Bismillah, prefetch) replays with no
        // network round-trip at all.
        if let readyURL = readyLocalURL(surah: surah, verse: verse) {
            StreamCache.touch(readyURL)
            playFromURL(readyURL, surah: surah, verse: verse)
            return
        }

        // Stream from EveryAyah.com
        let remoteURL = ReciterLibrary.everyAyahURL(reciter: currentReciter.id, surah: surah, verse: verse)
        isLoadingVerse = true

        ensureStreamCacheDirectory()
        let destination = streamCacheURL(reciter: currentReciter.id, surah: surah, verse: verse)
        let protectedNames = streamCacheProtectedNames(adding: destination)

        let task = URLSession.shared.dataTask(with: remoteURL) { [weak self] data, response, error in
            let wasCancelled = (error as? URLError)?.code == .cancelled
            let notFound = (response as? HTTPURLResponse)?.statusCode == 404

            // The write happens here, on URLSession's own queue, so the main actor is
            // never blocked on ~200 KB of disk I/O at the start of a verse.
            var cached = false
            if !wasCancelled, !notFound, error == nil, let data, !data.isEmpty {
                cached = StreamCache.write(data, to: destination)
                if cached { StreamCache.evictIfNeeded(keeping: protectedNames) }
            }

            Task { @MainActor [weak self] in
                guard let self else { return }

                // `isLoadingVerse` is cleared per terminal path below, never up here.
                // Clearing it before `playFromURL` sets `isPlaying` leaves a frame
                // where the verse is neither loading nor playing, and the highlight
                // blinks off at the start of every session.
                if wasCancelled {
                    // Whoever cancelled owns the flag: `stop()`, `pause()` and
                    // `loadAndPlay()` each set it for the state they are moving to.
                    // Writing it here would clobber a newer load that has already
                    // started.
                    return
                }

                if notFound {
                    // If Bismillah file missing for this reciter, skip directly to verse 1
                    if verseOverride == 0 {
                        // Still loading — same tap, one continuous spinner across the
                        // retry, so this path does not blink either.
                        self.pendingVerseAfterBismillah = nil
                        self.loadAndPlay()
                    } else {
                        self.isLoadingVerse = false
                        self.errorMessage = "الآية غير متوفرة لهذا القارئ"
                    }
                    return
                }

                guard cached else {
                    self.isLoadingVerse = false
                    self.errorMessage = "تعذّر تحميل الآية"
                    return
                }

                self.playFromURL(destination, surah: surah, verse: verse)
            }
        }
        downloadTask = task
        task.resume()
    }

    private func playFromURL(_ url: URL, surah: Int, verse: Int) {
        do {
            try activateSessionIfNeeded()

            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.enableRate = true
            player.rate = playbackSpeed
            player.prepareToPlay()
            player.play()

            audioPlayer = player
            activeTarget = (surah, verse)
            isPlaying = true
            // Cleared only once `isPlaying` is true, never before: the highlight in
            // QuranPagerView is driven by `isPlaying || isLoadingVerse`, so clearing
            // it first leaves a frame where neither is set and the highlight blinks.
            // Same order as the handoff promotion below.
            isLoadingVerse = false
            verseDuration = player.duration
            verseElapsed = 0
            verseProgress = 0

            schedulePersist()
            updateNowPlayingInfo()
            startProgressTimer()
            prefetchNext(after: surah, verse: verse)
        } catch {
            errorMessage = "تعذّر تشغيل الآية"
            isPlaying = false
            isLoadingVerse = false
        }
    }

    // MARK: - Prefetch

    /// What will play after (surah, verse) — mirrors autoAdvance/advanceToNextVerse.
    /// Returns nil when nothing should be prefetched (repeat-verse, end of Quran,
    /// or a play-to boundary that will stop playback).
    private func nextPlaybackTarget(after surah: Int, verse: Int) -> (surah: Int, verse: Int)? {
        // Mid-Bismillah: the next thing to play is verse 1 of this surah.
        if verse == 0 { return (surah, pendingVerseAfterBismillah ?? 1) }

        // Verse repeat replays the same file — already cached, nothing to fetch.
        if repeatVerseEnabled { return nil }

        let total = ReciterLibrary.verseCounts[surah] ?? 1
        let next: (surah: Int, verse: Int)
        if verse < total {
            next = (surah, verse + 1)
        } else if playSurahMode {
            return nil
        } else if surah < 114 {
            // Surahs 2…114 except At-Tawbah open with a separate Bismillah file.
            next = (surah + 1, (surah + 1 != 9) ? 0 : 1)
        } else {
            return nil
        }

        switch playToMode {
        case .endOfSurah:
            if verse >= total { return nil }
        case .endOfPage(let targetPage):
            let probeVerse = next.verse == 0 ? 1 : next.verse
            if QuranDatabase.shared.getPage(forSurah: next.surah, verse: probeVerse) != targetPage { return nil }
        case .stopAtVerse(let stopSurah, let stopVerse):
            if surah > stopSurah || (surah == stopSurah && verse >= stopVerse) { return nil }
        case .continuous:
            break
        }
        return next
    }

    /// Warm the next verse's bytes into the stream cache while the current verse plays.
    private func prefetchNext(after surah: Int, verse: Int) {
        guard let next = nextPlaybackTarget(after: surah, verse: verse) else { return }
        if let inFlight = prefetchedTarget, inFlight == next, prefetchTask != nil { return }

        let reciter = currentReciter.id
        if DownloadManager.shared.isAvailable(reciterSlug: reciter, surahNumber: next.surah, verseNumber: next.verse) { return }

        ensureStreamCacheDirectory()
        let destination = streamCacheURL(reciter: reciter, surah: next.surah, verse: next.verse)
        if FileManager.default.fileExists(atPath: destination.path) { return }

        prefetchTask?.cancel()
        prefetchedTarget = next

        let protectedNames = streamCacheProtectedNames(adding: destination)
        let url = ReciterLibrary.everyAyahURL(reciter: reciter, surah: next.surah, verse: next.verse)
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard (response as? HTTPURLResponse)?.statusCode != 404,
                  let data, error == nil, !data.isEmpty,
                  StreamCache.write(data, to: destination) else { return }
            StreamCache.evictIfNeeded(keeping: protectedNames)
        }
        prefetchTask = task
        task.resume()
    }

    private func cancelPrefetch() {
        prefetchTask?.cancel()
        prefetchTask = nil
        prefetchedTarget = nil
    }

    // MARK: - Gapless handoff

    /// Decode verse N+1 and pin its start to the shared audio clock before verse N
    /// ends, so the crossover happens in the audio engine instead of waiting for a
    /// delegate callback plus a fresh file open.
    private func armHandoffIfDue(for player: AVAudioPlayer) {
        guard !handoffAttempted,
              scheduledHandoff == nil,
              let source = activeTarget,
              remainingPlaybackTime(of: player) <= Self.handoffLeadTime
        else { return }

        guard canScheduleHandoff(fromVerse: source.verse),
              let target = nextPlaybackTarget(after: source.surah, verse: source.verse)
        else {
            handoffAttempted = true
            return
        }

        // Bytes may still be in flight; the next tick gets another chance inside the
        // lead window, and the delegate path is the fallback if they never land.
        guard let url = readyLocalURL(surah: target.surah, verse: target.verse) else { return }

        handoffAttempted = true

        // Built on the main actor deliberately. AVAudioPlayer latches the run loop it
        // will deliver its delegate callbacks on at an undocumented point between
        // init and play, and a DispatchQueue worker has no run loop to latch — a
        // player prepared there can finish silently and never call
        // audioPlayerDidFinishPlaying, stalling the whole chain. This runs at
        // T-1.0s, a full second before the seam, so the header parse costs nothing
        // where it would be audible, and it is the same work `playFromURL`
        // already does on the main actor for every verse today.
        guard let prepared = try? AVAudioPlayer(contentsOf: url) else { return }
        prepared.delegate = self
        prepared.enableRate = true
        prepared.rate = playbackSpeed
        prepared.prepareToPlay()
        scheduleHandoff(prepared, target: target, source: source, reciter: currentReciter.id)
    }

    /// Back on the main actor with a decoded player: re-check that the verse it was
    /// built for is still the one playing, then pin its start time.
    private func scheduleHandoff(_ player: AVAudioPlayer,
                                 target: (surah: Int, verse: Int),
                                 source: (surah: Int, verse: Int),
                                 reciter: String) {
        guard scheduledHandoff == nil,
              isPlaying,
              reciter == currentReciter.id,
              let active = activeTarget, active == source,
              let current = audioPlayer, current.isPlaying
        else {
            player.stop()
            return
        }

        // Decoding outlasted the verse, or a seek moved the play head to the very end:
        // there is no room left to preroll, so let the delegate path handle it.
        let remaining = remainingPlaybackTime(of: current)
        guard remaining >= Self.handoffMinimumLead else {
            player.stop()
            return
        }

        player.rate = playbackSpeed
        guard player.play(atTime: current.deviceCurrentTime + remaining) else {
            player.stop()
            return
        }
        scheduledHandoff = ScheduledHandoff(player: player, target: target, source: source, reciter: reciter)
    }

    /// Adopts an already-playing scheduled verse. Returns false when there is none, or
    /// when playback state changed inside the lead window and the pre-computed target
    /// is no longer what `autoAdvance` would pick.
    private func promoteScheduledHandoffIfReady() -> Bool {
        guard let handoff = scheduledHandoff else { return false }
        scheduledHandoff = nil
        handoffAttempted = false

        guard handoff.reciter == currentReciter.id,
              canScheduleHandoff(fromVerse: handoff.source.verse),
              let expected = nextPlaybackTarget(after: handoff.source.surah, verse: handoff.source.verse),
              expected == handoff.target
        else {
            handoff.player.stop()
            return false
        }

        audioPlayer?.stop()

        let player = handoff.player
        player.delegate = self
        player.rate = playbackSpeed

        // Surah before verse: QuranPagerView reads `currentSurahNumber` from inside
        // `$currentVerseNumber`'s `willSet`, so it has to have settled first.
        currentSurahNumber = handoff.target.surah
        if handoff.target.verse == 0 {
            pendingVerseAfterBismillah = 1
            currentVerseNumber = 1
        } else {
            pendingVerseAfterBismillah = nil
            currentVerseNumber = handoff.target.verse
        }

        audioPlayer = player
        activeTarget = handoff.target
        isPlaying = true
        isLoadingVerse = false
        verseDuration = player.duration
        verseElapsed = 0
        verseProgress = 0

        schedulePersist()
        updateNowPlayingInfo()
        startProgressTimer()
        prefetchNext(after: handoff.target.surah, verse: handoff.target.verse)
        return true
    }

    /// Only the transitions `autoAdvance` resolves deterministically may be pinned in
    /// advance. The Bismillah always runs into its pending verse whatever the repeat
    /// flags say; anything else has to be plain forward playback, because a wrong
    /// handoff plays the wrong audio (a wrong prefetch only wastes a request).
    private func canScheduleHandoff(fromVerse verse: Int) -> Bool {
        if verse == 0 { return pendingVerseAfterBismillah != nil }
        return !repeatVerseEnabled && !repeatRangeEnabled
    }

    /// Tears down a next-verse player that was prepared but never reached.
    private func cancelScheduledHandoff() {
        scheduledHandoff?.player.stop()
        scheduledHandoff = nil
        handoffAttempted = false
    }

    /// Wall-clock seconds left in `player`. The rate matters: at 1.5× the remaining
    /// content is reached 1.5× sooner.
    private func remainingPlaybackTime(of player: AVAudioPlayer) -> TimeInterval {
        let rate = player.rate > 0 ? Double(player.rate) : 1
        return max(0, (player.duration - player.currentTime) / rate)
    }

    // MARK: - Progress Timer

    private func startProgressTimer() {
        stopProgressTimer()
        // `.common`, not the default mode: a page swipe puts the run loop in
        // `.tracking`, and a `.default`-only timer stops there — taking
        // `armHandoffIfDue(for:)` with it and disabling the gapless handoff during
        // the one interaction it was built for.
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tickProgress()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        progressTimer = timer
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
        armHandoffIfDue(for: player)
    }

    // MARK: - Persist

    /// A SwiftData `save()` on the main actor costs several milliseconds, and at one
    /// call per verse it lands squarely inside the seam between two files. Coalesce
    /// instead: at worst the last couple of seconds of position are lost on a kill,
    /// and `pause` / `stop` / interruption still persist immediately.
    private func schedulePersist() {
        persistWorkItem?.cancel()
        persistWorkItem = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            self?.persistCurrentPosition()
        }
    }

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

    /// The category never changes, and re-activating an already-active session is a
    /// cross-process round-trip. Both happen once, not once per verse.
    private func activateSessionIfNeeded() throws {
        let session = AVAudioSession.sharedInstance()
        if !sessionCategoryConfigured {
            try session.setCategory(.playback, mode: .default)
            sessionCategoryConfigured = true
        }
        if !isPlaying {
            try session.setActive(true)
        }
    }

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

        Task { @MainActor in
            switch type {
            case .began:
                self.persistCurrentPosition()
                self.cancelScheduledHandoff()
                self.isPlaying = false
                self.stopProgressTimer()

            case .ended:
                let shouldResume = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
                    .flatMap { AVAudioSession.InterruptionOptions(rawValue: $0) }
                    .map { $0.contains(.shouldResume) } ?? false
                if shouldResume { self.resume() }

            @unknown default:
                break
            }
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        Task { @MainActor in
            // Pause when headphones are unplugged (standard iOS behavior)
            if reason == .oldDeviceUnavailable {
                self.persistCurrentPosition()
                self.pause()
            }
        }
    }

    // MARK: - Helpers

    private func formatSpeed(_ speed: Float) -> String {
        speed == Float(Int(speed)) ? "\(Int(speed))×" : "\(speed)×"
    }

    // MARK: - Stream cache

    private func streamCacheURL(reciter: String, surah: Int, verse: Int) -> URL {
        StreamCache.url(reciter: reciter, surah: surah, verse: verse)
    }

    private func ensureStreamCacheDirectory() {
        StreamCache.ensureDirectory()
    }

    /// The on-disk file for a verse — downloaded copy first, then the stream cache —
    /// or nil while its bytes still have to come over the network.
    private func readyLocalURL(surah: Int, verse: Int) -> URL? {
        let reciter = currentReciter.id
        if DownloadManager.shared.isAvailable(reciterSlug: reciter, surahNumber: surah, verseNumber: verse),
           let downloaded = DownloadManager.shared.localURL(reciterSlug: reciter, surahNumber: surah, verseNumber: verse) {
            return downloaded
        }
        let cached = streamCacheURL(reciter: reciter, surah: surah, verse: verse)
        return FileManager.default.fileExists(atPath: cached.path) ? cached : nil
    }

    /// Filenames the eviction sweep must never delete: what is audible now, what the
    /// prefetcher is reaching for, and what is already decoded for the handoff.
    /// Captured on the main actor and handed to the sweep as a plain value.
    private func streamCacheProtectedNames(adding extra: URL?) -> Set<String> {
        var names: Set<String> = []
        if let extra { names.insert(extra.lastPathComponent) }
        if let active = activeTarget {
            names.insert(StreamCache.url(reciter: currentReciter.id, surah: active.surah, verse: active.verse).lastPathComponent)
        }
        if let target = prefetchedTarget {
            names.insert(StreamCache.url(reciter: currentReciter.id, surah: target.surah, verse: target.verse).lastPathComponent)
        }
        if let handoff = scheduledHandoff {
            names.insert(StreamCache.url(reciter: handoff.reciter, surah: handoff.target.surah, verse: handoff.target.verse).lastPathComponent)
        }
        return names
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioEngine: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard flag else {
                // A failed decode must not leave a sample-scheduled next verse playing
                // with no engine state behind it.
                self.cancelScheduledHandoff()
                return
            }
            self.autoAdvance()
        }
    }

    private func autoAdvance() {
        // The next verse is already audible on the shared audio clock — adopt it
        // instead of loading the same verse a second time (that would double-advance).
        if promoteScheduledHandoffIfReady() { return }

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

// MARK: - StreamCache

/// On-disk home for verses pulled from EveryAyah.com, kept under a rolling size cap.
///
/// File-scope and stateless by design: the sweep walks the directory off the main
/// actor, so reading a whole surah never blocks playback on `contentsOfDirectory`.
/// Modification date is the ordering key — no index to keep in sync with the disk.
private enum StreamCache {

    /// Roughly two full juz' of streamed audio. Listening through the whole Quran is
    /// ~900 MB, so the cap has to do real work rather than just catch pathologies.
    private static let budgetBytes: Int64 = 200 * 1024 * 1024
    /// Sweeping down to 80% of the budget keeps a sweep from firing on every write
    /// once the cache is full.
    private static let lowWaterMarkBytes: Int64 = 160 * 1024 * 1024

    private static let queue = DispatchQueue(label: "com.wird.audio.streamcache", qos: .utility)
    private static let lock = NSLock()
    private static var sweepScheduled = false

    static var directory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("wird-audio", isDirectory: true)
    }

    static func url(reciter: String, surah: Int, verse: Int) -> URL {
        let name = String(format: "%@_%03d%03d.mp3", reciter, surah, verse)
        return directory.appendingPathComponent(name)
    }

    static func ensureDirectory() {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// Eviction sorts on `contentModificationDate`, which is otherwise the download
    /// time — that makes the sweep FIFO, not LRU, and evicts the most-replayed verses
    /// first. Touching on every hit is what turns it into a real LRU.
    static func touch(_ url: URL) {
        queue.async {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path)
        }
    }

    /// Writes through a `.part` file so a truncated body can never be promoted into
    /// the cache and served as a playable verse.
    static func write(_ data: Data, to destination: URL) -> Bool {
        let part = destination.appendingPathExtension("part")
        do {
            try data.write(to: part, options: .atomic)
        } catch {
            return false
        }
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.moveItem(at: part, to: destination)
            return true
        } catch {
            try? FileManager.default.removeItem(at: part)
            return false
        }
    }

    /// Queues one sweep, never two: concurrent writes coalesce into a single pass.
    /// `keeping` holds the filenames that are in use right now and must survive.
    static func evictIfNeeded(keeping protectedNames: Set<String>) {
        lock.lock()
        if sweepScheduled {
            lock.unlock()
            return
        }
        sweepScheduled = true
        lock.unlock()

        queue.async {
            sweep(keeping: protectedNames)
            lock.lock()
            sweepScheduled = false
            lock.unlock()
        }
    }

    private static func sweep(keeping protectedNames: Set<String>) {
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return }

        var total: Int64 = 0
        var entries: [(url: URL, size: Int64, modified: Date)] = []
        for fileURL in contents {
            // A file can vanish underneath us (another sweep, the system reclaiming
            // tmp); skip it rather than abandoning the pass.
            guard let values = try? fileURL.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true,
                  let size = values.fileSize
            else { continue }
            total += Int64(size)
            entries.append((fileURL, Int64(size), values.contentModificationDate ?? .distantPast))
        }

        guard total > budgetBytes else { return }

        for entry in entries.sorted(by: { $0.modified < $1.modified }) {
            if total <= lowWaterMarkBytes { break }
            if protectedNames.contains(entry.url.lastPathComponent) { continue }
            do {
                try FileManager.default.removeItem(at: entry.url)
                total -= entry.size
            } catch {
                continue
            }
        }
    }
}
