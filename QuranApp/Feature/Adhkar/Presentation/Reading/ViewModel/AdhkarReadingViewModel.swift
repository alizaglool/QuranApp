//
//  AdhkarReadingViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
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

    private let audioService = DhikrAudioService()
    private var isAudioSessionActive: Bool = false

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

    /// One uniform contract for the view: a dhikr that ships `segments` is used as
    /// authored, anything older is synthesised from `textAr` + `description`.
    var currentSegments: [DhikrSegment] {
        guard let dhikr = currentDhikr else { return [] }
        if let segments = dhikr.segments, !segments.isEmpty { return segments }

        var synthesised = [DhikrSegment(kind: .text, text: dhikr.textAr)]
        if let description = dhikr.description, !description.isEmpty {
            synthesised.append(DhikrSegment(kind: .note, text: description))
        }
        return synthesised
    }

    var repeatLabel: String? { currentDhikr?.repeatLabel }

    /// Athkar fills the bar by position, not by work done, so the first dhikr
    /// already shows a sliver instead of an empty track.
    var overallProgress: Double {
        let totalCount = sortedAdhkar.count
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(totalCount)
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

        audioService.onStateChange = { [weak self] playing in
            self?.isPlaying = playing
        }
    }

    func goBack() {
        coordinator?.coordinateBack()
    }

    func onAppear() {
        stopAudio()
        currentIndex = 0
        currentTapCount = 0
        isComplete = false
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
        audioService.stop()
        currentTapCount = 0
        currentIndex += 1
        continueAudioSessionIfActive()
    }

    func navigateToPrevious() {
        guard canGoPrevious else { return }
        audioService.stop()
        currentTapCount = 0
        currentIndex -= 1
        continueAudioSessionIfActive()
    }

    func toggleAudio() {
        if isPlaying {
            stopAudio()
        } else {
            isAudioSessionActive = true
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
        audioService.stop()
        currentTapCount = 0
        if currentIndex < sortedAdhkar.count - 1 {
            currentIndex += 1
            continueAudioSessionIfActive()
        } else {
            isAudioSessionActive = false
            isComplete = true
        }
    }

    /// Carries an active listening session to the dhikr the user just moved to.
    /// Nothing starts on its own — the session exists only after the play button.
    private func continueAudioSessionIfActive() {
        guard isAudioSessionActive else { return }
        playCurrentDhikrAudio()
    }

    private func playCurrentDhikrAudio() {
        guard let dhikr = currentDhikr, let audioFile = dhikr.audio else { return }
        audioService.play(resource: audioFile, repeats: audioRepeats(for: dhikr))
    }

    private func audioRepeats(for dhikr: Dhikr) -> Int {
        dhikr.count
    }

    private func stopAudio() {
        isAudioSessionActive = false
        audioService.stop()
    }
}
