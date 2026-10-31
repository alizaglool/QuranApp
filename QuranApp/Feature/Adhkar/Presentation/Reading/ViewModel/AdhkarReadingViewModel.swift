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
    @Published private(set) var hasAudio: Bool = false

    let category: DhikrCategory
    let orderedAdhkar: [Dhikr]
    var isTabBarVisible: Bool { false }

    weak var coordinator: AdhkarCoordinating?

    private let audioService: DhikrAudioService
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

    func shareText(for dhikr: Dhikr) -> String {
        var blocks: [String] = displaySegments(for: dhikr).compactMap { segment in
            guard let text = segment.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { return nil }
            return text
        }

        if let repeatLabel = dhikr.repeatLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
           !repeatLabel.isEmpty {
            blocks.append(repeatLabel)
        }

        let body = blocks.joined(separator: "\n\n")

        guard let reference = dhikr.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reference.isEmpty,
              !Self.comparableForm(of: body).contains(Self.comparableForm(of: reference)) else {
            return body
        }
        return body.isEmpty ? reference : body + "\n\n" + reference
    }

    private static let diacriticScalars: Set<Unicode.Scalar> = {
        var scalars: Set<Unicode.Scalar> = []
        for range in [0x0610...0x061A, 0x064B...0x065F, 0x06D6...0x06ED] {
            for value in range {
                if let scalar = Unicode.Scalar(UInt32(value)) { scalars.insert(scalar) }
            }
        }
        for value in [0x0640, 0x0670] {
            if let scalar = Unicode.Scalar(UInt32(value)) { scalars.insert(scalar) }
        }
        return scalars
    }()

    private static let letterVariants: [String: String] = [
        "\u{0623}": "\u{0627}",
        "\u{0625}": "\u{0627}",
        "\u{0622}": "\u{0627}",
        "\u{0671}": "\u{0627}",
        "\u{0649}": "\u{064A}",
        "\u{0629}": "\u{0647}"
    ]

    private static func comparableForm(of text: String) -> String {
        var stripped = ""
        for scalar in text.unicodeScalars where !diacriticScalars.contains(scalar) {
            stripped.unicodeScalars.append(scalar)
        }
        for (variant, canonical) in letterVariants {
            stripped = stripped.replacingOccurrences(of: variant, with: canonical)
        }
        return stripped.split(whereSeparator: \.isWhitespace).joined(separator: " ")
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

    init(coordinator: AdhkarCoordinating, category: DhikrCategory, downloads: AthkarAudioDownloadManager = .shared) {
        self.coordinator = coordinator
        self.category = category
        self.orderedAdhkar = Self.adhkarInReadingOrder(for: category)
        self.audioService = DhikrAudioService(downloads: downloads)

        audioService.onStateChange = { [weak self] playing in
            self?.isPlaying = playing
        }
        refreshAudioAvailability()
    }

    func goBack() {
        coordinator?.coordinateBack()
    }

    func onAppear() {
        stopAudio()
        currentIndex = 0
        currentTapCount = 0
        isComplete = false
        refreshAudioAvailability()
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
        refreshAudioAvailability()
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
        refreshAudioAvailability()
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

    private func refreshAudioAvailability() {
        let resolved = currentDhikr.flatMap { dhikr in
            dhikr.audio.flatMap { file in audioService.resourceURL(forDhikrIdentifier: dhikr.id, resource: file) }
        }
        let available = resolved != nil
        if available != hasAudio { hasAudio = available }
    }

    private func playCurrentDhikrAudio() {
        guard let dhikr = currentDhikr, let audioFile = dhikr.audio else { return }
        audioService.play(dhikrIdentifier: dhikr.id, resource: audioFile, repeats: audioRepeats(for: dhikr))
    }

    func audioRepeats(for dhikr: Dhikr) -> Int {
        AthkarItemAudioPlayer.audioPlayCount(forRepeatCount: dhikr.count)
    }

    private func stopAudio() {
        isAudioSessionActive = false
        audioService.stop()
    }
}
