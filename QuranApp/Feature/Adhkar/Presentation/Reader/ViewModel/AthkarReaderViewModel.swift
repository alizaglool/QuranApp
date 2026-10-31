//
//  AthkarReaderViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import Foundation
import Combine
import UIKit
import Core

// MARK: - Navigation reason

enum AthkarReaderNavigationReason {
    case user
    case playback
    case scroll
}

// MARK: - View model

@MainActor
final class AthkarReaderViewModel: MainViewModel {

    // MARK: - Output

    @Published private(set) var pages: [AthkarReaderPage] = []
    @Published private(set) var index: Int = 0
    @Published private(set) var tally: Int = 0
    @Published private(set) var completedCount: Int = 0
    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var isFinished: Bool = false
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var playingItemID: Int?
    @Published private(set) var playbackRepetition: Int = 0
    @Published private(set) var playbackRepetitionTotal: Int = 0
    @Published private(set) var scrollTarget: Int?
    @Published private(set) var toast: String = ""
    @Published var isShowingSettings: Bool = false

    let pack: AthkarPack
    let settings: AthkarReaderSettings

    private let completion: AthkarCompletionStore
    private let favorites = AthkarFavoritesStore.shared
    private let audio: any AthkarAudioPlaying
    private var cancellables = Set<AnyCancellable>()
    private var toastTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?
    private var focusLockTask: Task<Void, Never>?
    private var isFocusLocked: Bool = false
    private var hasReportedMissingAudio: Bool = false
    private var activePlaybackItemID: Int?

    var isTabBarVisible: Bool { false }

    weak var coordinator: AdhkarCoordinating?

    init(coordinator: AdhkarCoordinating,
         pack: AthkarPack,
         items: [AthkarItem],
         settings: AthkarReaderSettings? = nil,
         completion: AthkarCompletionStore? = nil,
         audio: (any AthkarAudioPlaying)? = nil) {
        self.coordinator = coordinator
        self.pack = pack
        self.settings = settings ?? .shared
        self.completion = completion ?? .shared
        self.audio = audio ?? AthkarItemAudioPlayer()
        self.pages = items.enumerated().map { offset, item in
            AthkarReaderPage.make(
                item: item,
                eyebrow: String(format: AppLocalizedKeys.athkarReaderPosition.value, offset + 1),
                repeatBadge: String(format: AppLocalizedKeys.athkarReaderTimes.value, item.repeatCount)
            )
        }
    }

    deinit {
        toastTask?.cancel()
        advanceTask?.cancel()
        focusLockTask?.cancel()
    }

    // MARK: - Strings

    var screenTitle: String { pack.name }

    var progressLabel: String {
        String(format: AppLocalizedKeys.athkarReaderProgress.value, completedCount, pages.count)
    }

    var positionLabel: String {
        "\(index + 1) | \(pages.count)"
    }

    var hintLabel: String {
        isCurrentComplete
            ? AppLocalizedKeys.athkarReaderDoneHint.value
            : AppLocalizedKeys.athkarReaderTapHint.value
    }

    var meaningTitle: String { AppLocalizedKeys.athkarReaderMeaning.value }

    var pronunciationTitle: String { AppLocalizedKeys.athkarReaderPronunciation.value }

    var sourceTitle: String { AppLocalizedKeys.athkarReaderSource.value }

    var favoriteLabel: String {
        isFavorite
            ? AppLocalizedKeys.athkarReaderRemoveFavorite.value
            : AppLocalizedKeys.athkarReaderAddFavorite.value
    }

    var copyLabel: String { AppLocalizedKeys.athkarReaderCopy.value }

    var shareLabel: String { AppLocalizedKeys.share.value }

    var completedTitle: String {
        String(format: AppLocalizedKeys.athkarReaderCompletedTitle.value, pack.name)
    }

    var completedMessage: String { AppLocalizedKeys.adhkarCompletedMessage.value }

    var readAgainTitle: String { AppLocalizedKeys.athkarReaderReadAgain.value }

    var backTitle: String { AppLocalizedKeys.back.value }

    var audioFailureMessage: String { AppLocalizedKeys.athkarAudioFailed.value }

    var audioSkippedMessage: String { AppLocalizedKeys.athkarAudioSkipped.value }

    func repetitionLabel(forItemID itemID: Int) -> String {
        guard showsRepetition(forItemID: itemID) else { return "" }
        return String(format: AppLocalizedKeys.athkarReaderRepetition.value, playbackRepetition, playbackRepetitionTotal)
    }

    func repetitionAccessibilityLabel(forItemID itemID: Int) -> String {
        guard showsRepetition(forItemID: itemID) else { return "" }
        return String(format: AppLocalizedKeys.athkarReaderRepetitionLabel.value, playbackRepetition, playbackRepetitionTotal)
    }

    private func showsRepetition(forItemID itemID: Int) -> Bool {
        playingItemID == itemID && playbackRepetition > 0 && playbackRepetitionTotal > 1
    }

    var settingsTitle: String { AppLocalizedKeys.athkarSettingsTitle.value }

    var textSizeTitle: String { AppLocalizedKeys.athkarSettingsTextSize.value }

    var showTranslationTitle: String { AppLocalizedKeys.athkarSettingsShowTranslation.value }

    var layoutTitle: String { AppLocalizedKeys.athkarSettingsLayout.value }

    var layoutPagesTitle: String { AppLocalizedKeys.athkarSettingsLayoutPages.value }

    var layoutListTitle: String { AppLocalizedKeys.athkarSettingsLayoutList.value }

    var hasTranslatableContent: Bool {
        pages.contains { $0.hasMeaning || $0.hasTransliteration }
    }

    var startOverTitle: String { AppLocalizedKeys.athkarSettingsStartOver.value }

    var doneTitle: String { AppLocalizedKeys.done.value }

    var textSizeValue: String {
        String(format: AppLocalizedKeys.athkarSettingsSizeValue.value, settings.percent)
    }

    // MARK: - Derived

    var currentPage: AthkarReaderPage? {
        pages.indices.contains(index) ? pages[index] : nil
    }

    var shareText: String { currentPage?.shareText ?? "" }

    var target: Int { max(currentPage?.target ?? 1, 1) }

    var isCurrentComplete: Bool { tally >= target }

    var ringValue: Int { tally }

    var ringProgress: Double {
        min(1, Double(tally) / Double(target))
    }

    var overallProgress: Double {
        guard !pages.isEmpty else { return 0 }
        return Double(index + 1) / Double(pages.count)
    }

    var showsTranslation: Bool { settings.showsTranslation }

    var textScale: CGFloat { settings.scale }

    var layout: AthkarReaderLayout { settings.layout }

    var focusedItemID: Int? { currentPage?.item.id }

    var playingIndex: Int? {
        guard let playingItemID else { return nil }
        return pages.firstIndex { $0.item.id == playingItemID }
    }

    var hasAudio: Bool {
        guard let page = currentPage else { return false }
        return audio.canPlay(item: page.item, inPack: pack.key)
    }

    var hasToast: Bool { !toast.isEmpty }

    // MARK: - Lifecycle

    func onAppear() {
        observe()
        restorePosition()
        syncCurrent()
        scrollTarget = focusedItemID
        lockFocus()
    }

    func onDisappear() {
        audio.onFinished = nil
        stopPlayback()
        toastTask?.cancel()
        toastTask = nil
        advanceTask?.cancel()
        advanceTask = nil
        focusLockTask?.cancel()
        focusLockTask = nil
        isFocusLocked = false
    }

    // MARK: - Navigation

    func navigate(to newIndex: Int) {
        navigate(to: newIndex, reason: .user)
    }

    func navigate(to newIndex: Int, reason: AthkarReaderNavigationReason) {
        guard pages.indices.contains(newIndex), newIndex != index else { return }

        if reason == .user {
            advanceTask?.cancel()
            markCurrentIfSingle()
            stopPlayback()
        }

        if reason != .scroll {
            lockFocus()
            scrollTarget = pages[newIndex].item.id
        }

        index = newIndex
        syncCurrent()
    }

    func focus(onItemID itemID: Int) {
        guard !isFocusLocked else { return }
        guard let target = pages.firstIndex(where: { $0.item.id == itemID }) else { return }
        navigate(to: target, reason: .scroll)
    }

    private func lockFocus() {
        isFocusLocked = true
        focusLockTask?.cancel()
        focusLockTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.isFocusLocked = false
        }
    }

    func advance() {
        guard !pages.isEmpty else { return }

        if index + 1 < pages.count {
            navigate(to: index + 1)
        } else {
            finish()
        }
    }

    func close() {
        coordinator?.coordinateBack()
    }

    // MARK: - Counting

    func count() {
        guard let page = currentPage else { return }

        guard tally < page.target else {
            advance()
            return
        }

        completion.advance(item: page.item, inPack: pack.key)
        tally = completion.tally(itemID: page.item.id, inPack: pack.key)
        completedCount = completion.completedCount(forKey: pack.key)

        guard tally >= page.target else {
            UISelectionFeedbackGenerator().selectionChanged()
            return
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        scheduleAdvance(after: page.id)
    }

    func count(itemID: Int) {
        guard let target = pages.firstIndex(where: { $0.item.id == itemID }) else { return }

        if target != index {
            navigate(to: target, reason: .scroll)
        }

        count()
    }

    private func scheduleAdvance(after pageID: Int) {
        advanceTask?.cancel()
        advanceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled, let self, self.currentPage?.id == pageID else { return }
            self.advance()
        }
    }

    private func markCurrentIfSingle() {
        guard let page = currentPage, !page.needsCount else { return }
        completion.setCompleted(true, itemID: page.item.id, inPack: pack.key)
    }

    // MARK: - Completion

    func finish() {
        stopPlayback()
        completion.markFinished(pack, itemIDs: pages.map(\.item.id))
        WorshipTrackerStore.shared.markCompleted(adhkarCategoryIdentifier: pack.key)
        isFinished = true
    }

    func restart() {
        stopPlayback()
        advanceTask?.cancel()
        completion.reset(packKey: pack.key)
        isFinished = false
        index = 0
        lockFocus()
        scrollTarget = pages.first?.item.id
        syncCurrent()
    }

    // MARK: - Item actions

    func toggleFavorite() {
        guard let page = currentPage else { return }
        favorites.toggle(itemID: page.item.id, inPack: pack.key)
        isFavorite = favorites.isFavorite(itemID: page.item.id, inPack: pack.key)
    }

    func copyCurrent() {
        guard let page = currentPage, !page.shareText.isEmpty else { return }
        UIPasteboard.general.string = page.shareText
        showToast(AppLocalizedKeys.athkarCopied.value)
    }

    func toggleAudio() {
        guard let page = currentPage else { return }

        if !audio.isActive(itemID: page.item.id) {
            hasReportedMissingAudio = false
        }

        audio.toggle(item: page.item, inPack: pack.key)
        activePlaybackItemID = audio.playingItemID
    }

    // MARK: - Settings

    func openSettings() {
        isShowingSettings = true
    }

    func closeSettings() {
        isShowingSettings = false
    }

    func shrinkText() {
        settings.shrink()
    }

    func growText() {
        settings.grow()
    }

    func setShowsTranslation(_ value: Bool) {
        settings.setShowsTranslation(value)
    }

    func setLayout(_ value: AthkarReaderLayout) {
        settings.setLayout(value)
    }

    func startOver() {
        isShowingSettings = false
        restart()
    }

    // MARK: - Playback

    private func refreshPlaybackState() {
        playingItemID = audio.playingItemID
        playbackRepetition = audio.currentRepetition
        playbackRepetitionTotal = audio.totalRepetitions

        guard let page = currentPage else {
            isPlaying = false
            return
        }

        isPlaying = audio.isPlaying(itemID: page.item.id)
    }

    private func advancePlayback(after itemID: Int) {
        guard activePlaybackItemID == itemID else { return }
        activePlaybackItemID = nil

        guard let finished = pages.firstIndex(where: { $0.item.id == itemID }),
              let next = nextPlayableIndex(after: finished)
        else {
            refreshPlaybackState()
            return
        }

        if next.skipped > 0, !hasReportedMissingAudio {
            hasReportedMissingAudio = true
            showToast(audioSkippedMessage)
        }

        navigate(to: next.index, reason: .playback)
        audio.play(item: pages[next.index].item, inPack: pack.key)
        activePlaybackItemID = audio.playingItemID
    }

    private func stopPlayback() {
        audio.stop()
        activePlaybackItemID = nil
    }

    private func nextPlayableIndex(after start: Int) -> (index: Int, skipped: Int)? {
        var skipped = 0

        for cursor in (start + 1)..<pages.count {
            guard audio.canPlay(item: pages[cursor].item, inPack: pack.key) else {
                skipped += 1
                continue
            }
            return (cursor, skipped)
        }

        return nil
    }

    // MARK: - State

    private func observe() {
        guard cancellables.isEmpty else { return }

        audio.onFinished = { [weak self] itemID in
            self?.advancePlayback(after: itemID)
        }

        audio.stateChanges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshPlaybackState()
            }
            .store(in: &cancellables)

        audio.failures
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.showToast(self.audioFailureMessage)
                self.audio.clearFailure()
            }
            .store(in: &cancellables)

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    private func restorePosition() {
        guard !pages.isEmpty else { return }

        let firstPending = pages.firstIndex { page in
            !completion.isCompleted(itemID: page.item.id, inPack: pack.key)
        }

        guard let firstPending else {
            index = pages.count - 1
            isFinished = completion.isFinished(pack)
            return
        }

        index = firstPending
    }

    private func syncCurrent() {
        completedCount = completion.completedCount(forKey: pack.key)

        guard let page = currentPage else {
            tally = 0
            isFavorite = false
            refreshPlaybackState()
            return
        }

        tally = completion.tally(itemID: page.item.id, inPack: pack.key)
        isFavorite = favorites.isFavorite(itemID: page.item.id, inPack: pack.key)
        refreshPlaybackState()
    }

    private func showToast(_ message: String) {
        toastTask?.cancel()
        toast = message
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            guard !Task.isCancelled else { return }
            self?.toast = ""
        }
    }
}
