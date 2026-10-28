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
    let orderedAdhkar: [Dhikr]
    var isTabBarVisible: Bool { false }

    weak var coordinator: AdhkarCoordinating?

    private let audioService = DhikrAudioService()
    private var isAudioSessionActive: Bool = false

    private static func adhkarInReadingOrder(for category: DhikrCategory) -> [Dhikr] {
        var remaining = category.adhkar
        let ayatKursi = remaining.filter { $0.title?.contains("آية الكرسي") == true }
        remaining.removeAll { $0.title?.contains("آية الكرسي") == true }
        let salatNabi = remaining.filter { $0.title?.contains("الصلاة على النبي") == true }
        remaining.removeAll { $0.title?.contains("الصلاة على النبي") == true }
        return ayatKursi + remaining + salatNabi
    }

    var currentDhikr: Dhikr? {
        guard currentIndex < orderedAdhkar.count else { return nil }
        return orderedAdhkar[currentIndex]
    }

    var canGoNext: Bool { currentIndex < orderedAdhkar.count - 1 }
    var hasAudio: Bool { currentDhikr?.audio != nil }

    /// One uniform contract for the view: a dhikr that ships `segments` is used as
    /// authored, anything older is synthesised from `textAr` + `description`.
    func displaySegments(for dhikr: Dhikr) -> [DhikrSegment] {
        if let segments = dhikr.segments, !segments.isEmpty { return segments }

        var synthesised = [DhikrSegment(kind: .text, text: dhikr.textAr)]
        if let description = dhikr.description, !description.isEmpty {
            synthesised.append(DhikrSegment(kind: .note, text: description))
        }
        return synthesised
    }

    /// Athkar fills the bar by position, not by work done, so the first dhikr
    /// already shows a sliver instead of an empty track.
    var overallProgress: Double {
        let totalCount = orderedAdhkar.count
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(totalCount)
    }

    var tapProgress: Double {
        guard let dhikr = currentDhikr, dhikr.count > 0 else { return 0 }
        return Double(currentTapCount) / Double(dhikr.count)
    }

    init(coordinator: AdhkarCoordinating, category: DhikrCategory) {
        self.coordinator = coordinator
        self.category = category
        self.orderedAdhkar = Self.adhkarInReadingOrder(for: category)

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

    func navigateToIndex(_ index: Int) {
        guard index != currentIndex, orderedAdhkar.indices.contains(index) else { return }
        audioService.stop()
        currentTapCount = 0
        currentIndex = index
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
        if canGoNext {
            navigateToIndex(currentIndex + 1)
        } else {
            audioService.stop()
            currentTapCount = 0
            isAudioSessionActive = false
            isComplete = true
            WorshipTrackerStore.shared.markCompleted(adhkarCategoryIdentifier: category.id)
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
