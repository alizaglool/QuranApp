//
//  AdhkarReadingViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import AVFoundation
import Core

@MainActor
final class AdhkarReadingViewModel: MainViewModel {

    @Published var currentIndex: Int = 0
    @Published var currentTapCount: Int = 0
    @Published var isComplete: Bool = false
    @Published var isPlaying: Bool = false

    let category: DhikrCategory
    var isTabBarVisible: Bool { false }

    weak var coordinator: AdhkarCoordinating?

    private var audioPlayer: AVAudioPlayer?

    private var sortedAdhkar: [Dhikr] {
        var remaining = category.adhkar
        let ayatKursi = remaining.filter { $0.title?.contains("آية الكرسي") == true }
        remaining.removeAll { $0.title?.contains("آية الكرسي") == true }
        let salatNabi = remaining.filter { $0.title?.contains("الصلاة على النبي") == true }
        remaining.removeAll { $0.title?.contains("الصلاة على النبي") == true }
        return ayatKursi + remaining + salatNabi
    }

    var currentDhikr: Dhikr? {
        guard currentIndex < sortedAdhkar.count else { return nil }
        return sortedAdhkar[currentIndex]
    }

    var canGoNext: Bool { currentIndex < sortedAdhkar.count - 1 }
    var canGoPrevious: Bool { currentIndex > 0 }
    var hasAudio: Bool { currentDhikr?.audio != nil }

    var overallProgress: Double {
        let totalCount = sortedAdhkar.count
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    var tapProgress: Double {
        guard let dhikr = currentDhikr, dhikr.count > 0 else { return 0 }
        return Double(currentTapCount) / Double(dhikr.count)
    }

    var willAdvanceOnNextTap: Bool {
        guard let dhikr = currentDhikr else { return false }
        return (currentTapCount + 1 >= dhikr.count) && canGoNext
    }

    init(coordinator: AdhkarCoordinating, category: DhikrCategory) {
        self.coordinator = coordinator
        self.category = category
    }

    func goBack() {
        coordinator?.coordinateBack()
    }

    func onAppear() {
        stopAudio()
        currentIndex = 0
        currentTapCount = 0
        isComplete = false
        if hasAudio {
            playCurrentDhikrAudio()
        }
    }

    func onTap() {
        guard let dhikr = currentDhikr else { return }
        currentTapCount += 1
        if currentTapCount >= dhikr.count {
            advanceToNextDhikr()
        }
    }

    func navigateToNext() {
        guard canGoNext else { return }
        stopAudio()
        currentTapCount = 0
        currentIndex += 1
        if hasAudio { playCurrentDhikrAudio() }
    }

    func navigateToPrevious() {
        guard canGoPrevious else { return }
        stopAudio()
        currentTapCount = 0
        currentIndex -= 1
        if hasAudio { playCurrentDhikrAudio() }
    }

    func toggleAudio() {
        if isPlaying {
            stopAudio()
        } else {
            playCurrentDhikrAudio()
        }
    }

    func resetCurrentCount() {
        currentTapCount = 0
    }

    func reset() {
        stopAudio()
        currentIndex = 0
        currentTapCount = 0
        isComplete = false
    }

    func onDisappear() {
        stopAudio()
    }

    private func advanceToNextDhikr() {
        stopAudio()
        currentTapCount = 0
        if currentIndex < sortedAdhkar.count - 1 {
            currentIndex += 1
            if hasAudio { playCurrentDhikrAudio() }
        } else {
            isComplete = true
        }
    }

    private func playCurrentDhikrAudio() {
        guard let audioFile = currentDhikr?.audio,
              let url = findAudioURL(for: audioFile) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = AudioPlayerDelegate(onFinish: { [weak self] in
                Task { @MainActor in self?.isPlaying = false }
            })
            audioPlayer?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    private func findAudioURL(for filename: String) -> URL? {
        let extensions = ["m4a", "mp3", "aac", "caf"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: filename, withExtension: ext) {
                return url
            }
            if let url = Bundle.main.url(forResource: filename, withExtension: ext, subdirectory: "Audio") {
                return url
            }
        }
        return Bundle.main.url(forResource: filename, withExtension: nil)
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }
}

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
