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

    var overallProgress: Double {
        let total = category.adhkar.count
        guard total > 0 else { return 0 }
        return Double(currentIndex) / Double(total)
    }

    var tapProgress: Double {
        guard let dhikr = currentDhikr, dhikr.count > 0 else { return 0 }
        return Double(currentTapCount) / Double(dhikr.count)
    }

    var hasAudio: Bool { currentDhikr?.audio != nil }

    init(category: DhikrCategory) {
        self.category = category
    }

    func onAppear() {}

    func onTap() {
        guard let dhikr = currentDhikr else { return }
        currentTapCount += 1
        if currentTapCount >= dhikr.count {
            advanceToNext()
        }
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

    private func advanceToNext() {
        stopAudio()
        currentTapCount = 0
        if currentIndex < category.adhkar.count - 1 {
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
            audioPlayer?.delegate = AudioDelegate(onFinish: { [weak self] in
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

// Thin delegate to get playback-finished callback without retaining the VM
private final class AudioDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
