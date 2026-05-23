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

    private var audioPlayer: AVAudioPlayer?

    var currentDhikr: Dhikr? {
        guard currentIndex < category.adhkar.count else { return nil }
        return category.adhkar[currentIndex]
    }

    var canGoNext: Bool { currentIndex < category.adhkar.count - 1 }
    var canGoPrevious: Bool { currentIndex > 0 }
    var hasAudio: Bool { currentDhikr?.audio != nil }

    var overallProgress: Double {
        let totalCount = category.adhkar.count
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }

    var tapProgress: Double {
        guard let dhikr = currentDhikr, dhikr.count > 0 else { return 0 }
        return Double(currentTapCount) / Double(dhikr.count)
    }

    // True when the next tap will complete the current dhikr and trigger an advance
    var willAdvanceOnNextTap: Bool {
        guard let dhikr = currentDhikr else { return false }
        return (currentTapCount + 1 >= dhikr.count) && canGoNext
    }

    init(category: DhikrCategory) {
        self.category = category
    }

    func onAppear() {}

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
    }

    func navigateToPrevious() {
        guard canGoPrevious else { return }
        stopAudio()
        currentTapCount = 0
        currentIndex -= 1
    }

    func toggleAudio() {
        if isPlaying {
            stopAudio()
        } else {
            playCurrentDhikrAudio()
        }
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
        if canGoNext {
            currentIndex += 1
        } else {
            isComplete = true
        }
    }

    private func playCurrentDhikrAudio() {
        guard let audioFile = currentDhikr?.audio,
              let url = Bundle.main.url(forResource: audioFile, withExtension: nil,
                                        subdirectory: "Audio") else { return }
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
