//
//  AdhanVoiceViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 02/11/2026.
//

import Combine
import Core
import Foundation

struct AdhanVoiceItem: Identifiable, Equatable {

    let id: String
    let title: String
    let caption: String
    let isSelected: Bool
    let isPreviewPlaying: Bool
    let previewAccessibilityLabel: String
}

// MARK: - Adhan Voice View Model

@MainActor
final class AdhanVoiceViewModel: MainViewModel {

    @Published private(set) var items: [AdhanVoiceItem] = []
    @Published private(set) var isFullAdhanAvailable: Bool = false
    @Published private(set) var isFullAdhanPlaying: Bool = false
    @Published private(set) var fullAdhanRowTitle: String = ""
    @Published private(set) var fullAdhanRowCaption: String = ""
    @Published private(set) var playbackFailureMessage: String?

    var isTabBarVisible: Bool { false }

    private let manager: PrayerNotificationManager
    private let localizationManager = LocalizationManager.shared
    private weak var coordinator: AdhanVoiceCoordinating?
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: AdhanVoiceCoordinating, notificationManager: PrayerNotificationManager? = nil) {
        self.coordinator = coordinator
        manager = notificationManager ?? PrayerNotificationManager.shared
        reloadVoiceState()
        observeNotificationManager()
    }

    func onAppear() {
        reloadVoiceState()
    }

    func onDisappear() {
        manager.stopAdhanAudio()
    }
}

// MARK: - Titles

extension AdhanVoiceViewModel {

    var screenTitle: String { AppLocalizedKeys.adhanVoiceScreenTitle.value }
    var voiceSectionTitle: String { AppLocalizedKeys.adhanVoiceSectionTitle.value }
    var fullAdhanSectionTitle: String { AppLocalizedKeys.adhanVoiceFullSectionTitle.value }
    var footer: String { AppLocalizedKeys.adhanVoiceFooter.value }
    var unavailableMessage: String { AppLocalizedKeys.adhanVoiceUnavailable.value }
}

// MARK: - Actions

extension AdhanVoiceViewModel {

    func onBackTapped() {
        manager.stopAdhanAudio()
        coordinator?.coordinateBack()
    }

    func onVoiceTapped(_ identifier: String) {
        guard let recording = recording(forIdentifier: identifier) else { return }
        manager.selectRecording(recording)
    }

    func onPreviewTapped(_ identifier: String) {
        guard let recording = recording(forIdentifier: identifier) else { return }

        if manager.isPlayingAdhanAudio(recording, mode: .notificationTonePreview) {
            manager.stopAdhanAudio()
        } else {
            manager.previewNotificationTone(for: recording)
        }
    }

    func onFullAdhanTapped() {
        guard let recording = manager.selectedRecording else { return }

        if manager.isPlayingAdhanAudio(recording, mode: .fullAdhan) {
            manager.stopAdhanAudio()
        } else {
            manager.previewFullAdhan(for: recording)
        }
    }
}

// MARK: - Loading

private extension AdhanVoiceViewModel {

    func observeNotificationManager() {
        manager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadVoiceState()
            }
            .store(in: &cancellables)
    }

    func reloadVoiceState() {
        let selected = manager.selectedRecording
        let isPlayingFullAdhan = selected.map { manager.isPlayingAdhanAudio($0, mode: .fullAdhan) } ?? false

        items = manager.availableRecordings.map { item(for: $0, selected: selected) }
        isFullAdhanAvailable = manager.isFullAdhanAudioAvailable
        isFullAdhanPlaying = isPlayingFullAdhan
        fullAdhanRowTitle = isPlayingFullAdhan
            ? AppLocalizedKeys.adhanVoiceStopPreview.value
            : AppLocalizedKeys.adhanVoicePlayFullAdhan.value
        fullAdhanRowCaption = selected.map { name(for: $0) } ?? ""
        playbackFailureMessage = failureMessage(for: manager.lastAdhanPlaybackFailure)
    }

    func failureMessage(for failure: PrayerAdhanPlaybackFailure?) -> String? {
        guard failure != nil, !manager.availableRecordings.isEmpty else { return nil }

        return AppLocalizedKeys.adhanVoicePlaybackFailed.value
    }

    func item(for recording: AdhanRecording, selected: AdhanRecording?) -> AdhanVoiceItem {
        AdhanVoiceItem(id: recording.id,
                       title: name(for: recording),
                       caption: caption(for: recording),
                       isSelected: recording.id == selected?.id,
                       isPreviewPlaying: manager.isPlayingAdhanAudio(recording,
                                                                     mode: .notificationTonePreview),
                       previewAccessibilityLabel: previewAccessibilityLabel(for: recording))
    }

    func previewAccessibilityLabel(for recording: AdhanRecording) -> String {
        guard !manager.isPlayingAdhanAudio(recording, mode: .notificationTonePreview) else {
            return AppLocalizedKeys.adhanVoiceStopPreview.value
        }

        return String(format: AppLocalizedKeys.adhanVoicePreviewFormat.value,
                      AppLocalizedKeys.adhanVoiceNotificationToneLabel.value)
    }

    func name(for recording: AdhanRecording) -> String {
        isArabic ? recording.arabicTitle : recording.englishTitle
    }

    func caption(for recording: AdhanRecording) -> String {
        let origin = isArabic ? recording.arabicOrigin : recording.englishOrigin
        let duration = String(format: AppLocalizedKeys.adhanVoiceFullDurationFormat.value,
                              durationText(recording.fullAdhanDuration))
        let components: [String?] = [origin, duration]

        return components.compactMap { $0 }.joined(separator: " · ")
    }

    func durationText(_ duration: TimeInterval) -> String {
        let totalSeconds = max(0, Int(duration.rounded()))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        guard isArabic else { return String(format: "%d:%02d", minutes, seconds) }

        let paddedSeconds = seconds < 10 ? "٠\(seconds.arabicNumerals)" : seconds.arabicNumerals
        return "\(minutes.arabicNumerals):\(paddedSeconds)"
    }

    func recording(forIdentifier identifier: String) -> AdhanRecording? {
        manager.availableRecordings.first { $0.id == identifier }
    }

    var isArabic: Bool { localizationManager.currentLanguage == .Arabic }
}
