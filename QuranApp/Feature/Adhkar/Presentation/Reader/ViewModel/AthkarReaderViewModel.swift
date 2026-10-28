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
    @Published private(set) var toast: String = ""
    @Published var isShowingSettings: Bool = false

    let pack: AthkarPack
    let settings = AthkarReaderSettings.shared

    private let completion = AthkarCompletionStore.shared
    private let favorites = AthkarFavoritesStore.shared
    private let audio = AthkarItemAudioPlayer()
    private var cancellables = Set<AnyCancellable>()
    private var toastTask: Task<Void, Never>?
    private var advanceTask: Task<Void, Never>?

    var isTabBarVisible: Bool { false }

    weak var coordinator: AdhkarCoordinating?

    init(coordinator: AdhkarCoordinating, pack: AthkarPack, items: [AthkarItem]) {
        self.coordinator = coordinator
        self.pack = pack
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

    var settingsTitle: String { AppLocalizedKeys.athkarSettingsTitle.value }

    var textSizeTitle: String { AppLocalizedKeys.athkarSettingsTextSize.value }

    var showTranslationTitle: String { AppLocalizedKeys.athkarSettingsShowTranslation.value }

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
    }

    func onDisappear() {
        audio.stop()
        toastTask?.cancel()
        toastTask = nil
        advanceTask?.cancel()
        advanceTask = nil
    }

    // MARK: - Navigation

    func navigate(to newIndex: Int) {
        guard pages.indices.contains(newIndex), newIndex != index else { return }
        advanceTask?.cancel()
        markCurrentIfSingle()
        audio.stop()
        index = newIndex
        syncCurrent()
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
        audio.stop()
        completion.markFinished(pack, itemIDs: pages.map(\.item.id))
        WorshipTrackerStore.shared.markCompleted(adhkarCategoryIdentifier: pack.key)
        isFinished = true
    }

    func restart() {
        audio.stop()
        advanceTask?.cancel()
        completion.reset(packKey: pack.key)
        isFinished = false
        index = 0
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
        audio.toggle(item: page.item, inPack: pack.key)
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

    func startOver() {
        isShowingSettings = false
        restart()
    }

    // MARK: - State

    private func observe() {
        guard cancellables.isEmpty else { return }

        audio.$playingItemID
            .receive(on: DispatchQueue.main)
            .sink { [weak self] playing in
                guard let self else { return }
                self.isPlaying = playing != nil && playing == self.currentPage?.item.id
            }
            .store(in: &cancellables)

        audio.$hasFailed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failed in
                guard let self, failed else { return }
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
            return
        }

        tally = completion.tally(itemID: page.item.id, inPack: pack.key)
        isFavorite = favorites.isFavorite(itemID: page.item.id, inPack: pack.key)
        isPlaying = audio.isPlaying(itemID: page.item.id)
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
