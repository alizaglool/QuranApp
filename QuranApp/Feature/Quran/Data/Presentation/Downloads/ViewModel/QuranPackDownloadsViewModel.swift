//
//  QuranPackDownloadsViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import Foundation
import Combine
import Core

struct QuranPackRowItem: Identifiable {
    let id: String
    let juz: Int
    let title: String
    let pagesLabel: String
    let sizeLabel: String
    let isBundled: Bool
}

struct QuranPackDownloadConfirmation: Identifiable {
    let id: String
    let title: String
    let message: String
    let confirmTitle: String
    let cancelTitle: String
    let juzNumbers: [Int]
}

@MainActor
final class QuranPackDownloadsViewModel: MainViewModel {

    @Published private(set) var rows: [QuranPackRowItem] = []
    @Published private(set) var states: [String: ContentDownloadState] = [:]
    @Published private(set) var progressLabel: String = ""
    @Published private(set) var installedSizeLabel: String = ""
    @Published private(set) var hasInsufficientStorage: Bool = false
    @Published private(set) var isCatalogEmpty: Bool = false
    @Published private(set) var isRefreshing: Bool = false
    @Published private(set) var waitingKeys: Set<String> = []
    @Published var confirmation: QuranPackDownloadConfirmation?

    var isTabBarVisible: Bool { false }

    private let store: any QuranImagePackProviding
    private let availableStorageBytes: () -> Int64?
    private weak var coordinator: QuranPackDownloadsCoordinating?

    private var cancellables = Set<AnyCancellable>()
    private var packsByJuz: [Int: QuranImagePack] = [:]
    private var downloadablePacks: [QuranImagePack] = []
    private var currentKeys: Set<String> = []
    private var downloadableJuzNumbers: [Int] = []
    private var pendingJuzNumbers: [Int] = []
    private var settledSignature: String = ""

    init(coordinator: QuranPackDownloadsCoordinating,
         store: any QuranImagePackProviding = QuranImagePackStore.shared,
         availableStorageBytes: @escaping () -> Int64? = QuranPackDownloadsViewModel.volumeCapacityBytes) {
        self.coordinator = coordinator
        self.store = store
        self.availableStorageBytes = availableStorageBytes
    }

    func onAppear() {
        reloadCatalog()
        observeDownloads()
        refreshCatalogFromRemote()
    }
}

// MARK: - Titles

extension QuranPackDownloadsViewModel {

    var screenTitle: String { AppLocalizedKeys.quranDownloadsTitle.value }
    var headerCaption: String { AppLocalizedKeys.quranDownloadsHeaderCaption.value }
    var emptyTitle: String { AppLocalizedKeys.quranDownloadsEmptyTitle.value }
    var emptyMessage: String { AppLocalizedKeys.quranDownloadsEmptyMessage.value }
    var bundledLabel: String { AppLocalizedKeys.quranDownloadsBundled.value }
    var offlineNoteTitle: String { AppLocalizedKeys.quranDownloadsOfflineNote.value }
    var waitingNetworkLabel: String { AppLocalizedKeys.quranDownloadsWaitingNetwork.value }
    var fullDownloadTitle: String { AppLocalizedKeys.quranFullDownloadTitle.value }
    var includedContentTitle: String { AppLocalizedKeys.quranFullDownloadIncludesTitle.value }
    var includedContentBody: String { AppLocalizedKeys.quranFullDownloadIncludesBody.value }
    var excludedContentBody: String { AppLocalizedKeys.quranFullDownloadExcludesBody.value }

    var captionTracking: CGFloat { isArabic ? 0 : 1.5 }

    var fullStatus: QuranFullDownloadStatus {
        let resolved = QuranFullDownloadStatus.resolve(packs: downloadablePacks,
                                                       currentKeys: currentKeys,
                                                       states: states,
                                                       waitingKeys: waitingKeys)

        guard hasInsufficientStorage, !resolved.isDownloading, !resolved.isComplete else { return resolved }
        return resolved.markingInsufficientStorage()
    }

    var fullDownloadActionTitle: String {
        switch fullStatus.stage {
        case .notDownloaded: return AppLocalizedKeys.quranFullDownloadAction.value
        case .downloading:   return AppLocalizedKeys.quranFullDownloadCancelAction.value
        case .downloaded:    return AppLocalizedKeys.quranFullDownloadDoneAction.value
        case .failed:        return AppLocalizedKeys.quranFullDownloadRetryAction.value
        }
    }

    var fullDownloadDetail: String {
        let status = fullStatus

        switch status.stage {
        case .notDownloaded:
            return String(format: AppLocalizedKeys.quranFullDownloadIdleDetailFormat.value,
                          sizeLabel(status.remainingBytes),
                          localizedNumber(status.remainingPackCount))

        case .downloading:
            if status.isWaitingForNetwork { return waitingNetworkLabel }
            if status.isInstalling { return AppLocalizedKeys.quranFullDownloadInstalling.value }
            return String(format: AppLocalizedKeys.quranFullDownloadProgressFormat.value,
                          sizeLabel(status.downloadedBytes),
                          sizeLabel(status.totalBytes),
                          percentLabel(status.percent))

        case .downloaded:
            return String(format: AppLocalizedKeys.quranDownloadsOnDeviceFormat.value,
                          sizeLabel(status.totalBytes))

        case let .failed(reason):
            guard reason == .noSpace else { return AppLocalizedKeys.quranFullDownloadFailedDetail.value }
            return String(format: AppLocalizedKeys.quranFullDownloadNoSpaceFormat.value,
                          sizeLabel(status.requiredFreeBytes))
        }
    }

    var isFullDownloadActionEnabled: Bool { !fullStatus.isComplete }
}

// MARK: - Storage

extension QuranPackDownloadsViewModel {

    nonisolated static func volumeCapacityBytes() -> Int64? {
        guard let root = FileManager.default.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first,
              let values = try? root.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        else { return nil }

        return values.volumeAvailableCapacityForImportantUsage
    }
}

// MARK: - Actions

extension QuranPackDownloadsViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func onFullDownloadTapped() {
        switch fullStatus.stage {
        case .notDownloaded:
            requestDownloadAll()

        case .downloading:
            cancelAll()

        case .failed:
            startPendingDownloads()

        case .downloaded:
            break
        }
    }

    func onRowActionTapped(_ row: QuranPackRowItem) {
        switch state(for: row) {
        case .downloading, .installing:
            store.cancel(juz: row.juz)

        case .notDownloaded, .failed:
            requestDownload(row)

        case .downloaded:
            break
        }
    }

    func confirmDownload(_ request: QuranPackDownloadConfirmation) {
        confirmation = nil
        hasInsufficientStorage = false

        for juz in request.juzNumbers {
            store.download(juz: juz)
        }
    }

    func cancelConfirmation() {
        confirmation = nil
    }

    func state(for row: QuranPackRowItem) -> ContentDownloadState {
        guard !row.isBundled else { return .downloaded }
        if let live = states[row.id], live.isBusy { return live }
        if currentKeys.contains(row.id) { return .downloaded }
        return states[row.id] ?? .notDownloaded
    }

    func isWaitingForNetwork(_ row: QuranPackRowItem) -> Bool {
        !row.isBundled && waitingKeys.contains(row.id)
    }
}

// MARK: - Requests

private extension QuranPackDownloadsViewModel {

    func requestDownload(_ row: QuranPackRowItem) {
        confirmation = QuranPackDownloadConfirmation(
            id: row.id,
            title: AppLocalizedKeys.quranDownloadsConfirmTitle.value,
            message: String(format: AppLocalizedKeys.quranDownloadsConfirmMessageFormat.value,
                            row.title,
                            row.sizeLabel),
            confirmTitle: AppLocalizedKeys.quranDownloadsDownloadAction.value,
            cancelTitle: AppLocalizedKeys.cancel.value,
            juzNumbers: [row.juz]
        )
    }

    func requestDownloadAll() {
        let pending = pendingJuzNumbers
        guard !pending.isEmpty, hasRoomForPendingPacks() else { return }

        confirmation = QuranPackDownloadConfirmation(
            id: "all",
            title: AppLocalizedKeys.quranDownloadsConfirmAllTitle.value,
            message: String(format: AppLocalizedKeys.quranDownloadsConfirmAllMessageFormat.value,
                            localizedNumber(pending.count),
                            sizeLabel(pendingBytes)),
            confirmTitle: AppLocalizedKeys.quranDownloadsDownloadAction.value,
            cancelTitle: AppLocalizedKeys.cancel.value,
            juzNumbers: pending
        )
    }

    func startPendingDownloads() {
        let pending = pendingJuzNumbers
        guard !pending.isEmpty, hasRoomForPendingPacks() else { return }

        for juz in pending {
            store.download(juz: juz)
        }
    }

    func cancelAll() {
        store.cancelAll()
    }

    var pendingBytes: Int64 {
        pendingJuzNumbers
            .compactMap { packsByJuz[$0]?.archiveSizeBytes }
            .reduce(Int64(0)) { $0 + Int64($1) }
    }

    func hasRoomForPendingPacks() -> Bool {
        let hasRoom = QuranFullDownloadStatus.hasRoom(forRemaining: pendingBytes,
                                                      availableBytes: availableStorageBytes())
        hasInsufficientStorage = !hasRoom
        return hasRoom
    }
}

// MARK: - Loading

private extension QuranPackDownloadsViewModel {

    func observeDownloads() {
        guard cancellables.isEmpty else { return }

        store.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                self?.applyStates(updated)
            }
            .store(in: &cancellables)

        store.waitingKeysPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keys in
                guard let self, self.waitingKeys != keys else { return }
                self.waitingKeys = keys
            }
            .store(in: &cancellables)
    }

    func applyStates(_ updated: [String: ContentDownloadState]) {
        states = updated

        let signature = Self.signature(of: updated)
        guard signature != settledSignature else { return }
        settledSignature = signature
        reloadCatalog()
    }

    func refreshCatalogFromRemote() {
        guard !isRefreshing else { return }
        isRefreshing = true

        Task { [weak self] in
            guard let self else { return }
            await self.store.refreshCatalog()
            self.isRefreshing = false
            self.reloadCatalog()
        }
    }

    func reloadCatalog() {
        let manifest = store.manifest
        let packs = manifest.sortedPacks

        packsByJuz = Dictionary(uniqueKeysWithValues: packs.map { ($0.juz, $0) })
        isCatalogEmpty = packs.isEmpty

        let downloadable = store.downloadablePacks
        let current = downloadable.filter { store.isCurrent($0) }
        downloadablePacks = downloadable
        downloadableJuzNumbers = downloadable.map(\.juz)
        currentKeys = Set(current.map(\.key))
        pendingJuzNumbers = downloadable.filter { !currentKeys.contains($0.key) }.map(\.juz)

        rows = packs.map(makeRow)
        settledSignature = Self.signature(of: states)
        hasInsufficientStorage = false

        refreshHeader()
    }

    func makeRow(_ pack: QuranImagePack) -> QuranPackRowItem {
        QuranPackRowItem(
            id: pack.key,
            juz: pack.juz,
            title: AppLocalizedKeys.juzKey(pack.juz).value,
            pagesLabel: pagesLabel(for: pack),
            sizeLabel: pack.archiveSizeLabel,
            isBundled: store.isBundled(pack: pack)
        )
    }

    func refreshHeader() {
        let total = downloadableJuzNumbers.count
        let installed = total - pendingJuzNumbers.count

        progressLabel = pendingJuzNumbers.isEmpty && total > 0
            ? AppLocalizedKeys.quranDownloadsAllDone.value
            : String(format: AppLocalizedKeys.quranDownloadsProgressFormat.value,
                     localizedNumber(installed),
                     localizedNumber(total))

        let installedBytes = downloadableJuzNumbers
            .filter { !pendingJuzNumbers.contains($0) }
            .compactMap { packsByJuz[$0]?.archiveSizeBytes }
            .reduce(0, +)

        installedSizeLabel = installedBytes > 0
            ? String(format: AppLocalizedKeys.quranDownloadsOnDeviceFormat.value,
                     sizeLabel(Int64(installedBytes)))
            : ""
    }
}

// MARK: - Formatting

private extension QuranPackDownloadsViewModel {

    var isArabic: Bool {
        LocalizationManager.shared.currentLanguage == .Arabic
    }

    func localizedNumber(_ value: Int) -> String {
        isArabic ? value.arabicNumerals : "\(value)"
    }

    func pagesLabel(for pack: QuranImagePack) -> String {
        String(format: AppLocalizedKeys.quranDownloadsPagesFormat.value,
               localizedNumber(pack.firstPage),
               localizedNumber(pack.lastPage))
    }

    func sizeLabel(_ bytes: Int64) -> String {
        let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        return "\u{2066}\(size)\u{2069}"
    }

    func percentLabel(_ percent: Int) -> String {
        isArabic ? "\u{2066}\(percent.arabicNumerals)%\u{2069}" : "\u{2066}\(percent)%\u{2069}"
    }

    static func signature(of states: [String: ContentDownloadState]) -> String {
        states.keys.sorted().map { key in
            switch states[key] {
            case .downloaded: return "\(key):d"
            case .installing: return "\(key):i"
            case .downloading: return "\(key):t"
            case .failed: return "\(key):f"
            case .notDownloaded, .none: return "\(key):n"
            }
        }
        .joined(separator: ",")
    }
}
