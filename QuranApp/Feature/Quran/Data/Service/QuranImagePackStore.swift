//
//  QuranImagePackStore.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import Foundation
import Combine
import Core

// MARK: - Catalog contract

protocol QuranImagePackProviding: AnyObject {

    var manifest: QuranImageManifest { get }
    var downloadablePacks: [QuranImagePack] { get }
    var statePublisher: AnyPublisher<[String: ContentDownloadState], Never> { get }
    var waitingKeysPublisher: AnyPublisher<Set<String>, Never> { get }

    func isBundled(pack: QuranImagePack) -> Bool
    func isCurrent(_ pack: QuranImagePack) -> Bool
    func download(juz: Int)
    func cancel(juz: Int)
    func cancelAll()

    @discardableResult
    func refreshCatalog() async -> QuranImageManifest
}

// MARK: - Store

final class QuranImagePackStore: ObservableObject, QuranImagePackProviding {

    static let shared = QuranImagePackStore()

    static let backgroundSessionIdentifier = "com.quranapp.quran.images.download"
    static let contentDirectoryName = "quran_images"
    static let stagingDirectoryName = "quran_images_staging"

    @Published private(set) var states: [String: ContentDownloadState] = [:]

    @Published private(set) var installedKeys: Set<String> = []

    @Published private(set) var waitingKeys: Set<String> = []

    private var settledKeys: Set<String> = []

    private let manifests: QuranImageManifestService
    private let fileManager: FileManager
    private let downloader: ContentDownloader
    private var cancellable: AnyCancellable?
    private var waitingCancellable: AnyCancellable?

    init(manifests: QuranImageManifestService = .shared,
         fileManager: FileManager = .default) {
        self.manifests = manifests
        self.fileManager = fileManager

        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        downloader = ContentDownloader(
            contentRoot: support.appendingPathComponent(Self.contentDirectoryName, isDirectory: true),
            stagingRoot: support.appendingPathComponent(Self.stagingDirectoryName, isDirectory: true),
            queueLabel: "com.quranapp.quran.images.install",
            sessionIdentifier: Self.backgroundSessionIdentifier,
            excludedFromBackup: true,
            fileManager: fileManager,
            isInstalled: { directory in
                QuranImagePackStore.hasCompletePageCoverage(at: directory,
                                                            manifest: manifests.load(),
                                                            fileManager: fileManager)
            },
            cancellableStage: { _, archive, staging, isCancelled in
                let pages = staging.appendingPathComponent("pages", isDirectory: true)
                try? fileManager.removeItem(at: pages)
                _ = try AthkarArchive.extract(archiveAt: archive,
                                              to: pages,
                                              isCancelled: isCancelled) { entry in
                    entry.path.hasSuffix(".png")
                }
                return pages
            }
        )

        installedKeys = Set(downloader.installedKeys())

        cancellable = downloader.$states
            .receive(on: DispatchQueue.main)
            .sink { [weak self] states in
                guard let self else { return }
                self.states = states
                self.reconcileInstalled(states)
            }

        waitingCancellable = downloader.$waitingKeys
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keys in
                guard let self, self.waitingKeys != keys else { return }
                self.waitingKeys = keys
            }
    }

    // MARK: - Coverage

    static func hasCompletePageCoverage(at directory: URL,
                                        manifest: QuranImageManifest,
                                        fileManager: FileManager = .default) -> Bool {
        guard let entries = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return false }

        let pages = Set(entries.compactMap { Int($0) })

        guard let pack = coveredPack(forDirectory: directory, pages: pages, manifest: manifest) else { return false }
        guard pages.isSuperset(of: pack.pageRange) else { return false }

        var images = 0

        for page in pack.pageRange {
            let pageDirectory = directory.appendingPathComponent("\(page)", isDirectory: true)
            guard let lines = try? fileManager.contentsOfDirectory(atPath: pageDirectory.path) else { return false }

            let rendered = lines.filter { $0.hasSuffix(".png") }.count
            guard rendered > 0 else { return false }

            images += rendered
        }

        return images >= pack.imageCount
    }

    private static func coveredPack(forDirectory directory: URL,
                                    pages: Set<Int>,
                                    manifest: QuranImageManifest) -> QuranImagePack? {
        let name = directory.lastPathComponent

        if let keyed = manifest.packs.first(where: { $0.key == name }) { return keyed }

        guard let firstPage = pages.min() else { return nil }
        return manifest.pack(forPage: firstPage)
    }

    // MARK: - Installed Content

    private func reconcileInstalled(_ states: [String: ContentDownloadState]) {
        let settled = Set(states.filter { $0.value == .downloaded }.keys)
        guard settled != settledKeys else { return }
        settledKeys = settled
        refreshInstalledKeys()
    }

    private func refreshInstalledKeys() {
        installedKeys = Set(downloader.installedKeys())
    }

    private func didRemoveInstalledContent() {
        QuranPageImageCache.shared.forgetAvailability()
        refreshInstalledKeys()
    }

    // MARK: - Publishers

    var statePublisher: AnyPublisher<[String: ContentDownloadState], Never> {
        $states.eraseToAnyPublisher()
    }

    var waitingKeysPublisher: AnyPublisher<Set<String>, Never> {
        $waitingKeys.eraseToAnyPublisher()
    }

    // MARK: - Catalog

    var manifest: QuranImageManifest { manifests.load() }

    var packs: [QuranImagePack] { manifests.packs() }

    func pack(juz: Int) -> QuranImagePack? {
        manifests.pack(juz: juz)
    }

    func pack(forPage page: Int) -> QuranImagePack? {
        manifests.pack(forPage: page)
    }

    var downloadablePacks: [QuranImagePack] {
        let manifest = manifest
        return manifest.sortedPacks.filter { !manifest.isFullyBundled($0) }
    }

    func isBundled(pack: QuranImagePack) -> Bool {
        manifest.isFullyBundled(pack)
    }

    @discardableResult
    func refreshCatalog() async -> QuranImageManifest {
        let refreshed = await manifests.refresh()
        await MainActor.run {
            objectWillChange.send()
            refreshInstalledKeys()
        }
        return refreshed
    }

    // MARK: - Paths

    func directory(forJuz juz: Int) -> URL? {
        guard let pack = pack(juz: juz) else { return nil }
        return downloader.directory(forKey: pack.key)
    }

    func localPath(page: Int, line: Int) -> String? {
        guard let pack = pack(forPage: page) else { return nil }
        let url = downloader.directory(forKey: pack.key)
            .appendingPathComponent("\(page)", isDirectory: true)
            .appendingPathComponent("\(line).png")
        return fileManager.fileExists(atPath: url.path) ? url.path : nil
    }

    // MARK: - Status

    func state(for pack: QuranImagePack) -> ContentDownloadState {
        guard let request = request(for: pack) else { return downloader.state(forKey: pack.key) }
        return downloader.state(for: request)
    }

    func isCurrent(_ pack: QuranImagePack) -> Bool {
        guard let request = request(for: pack) else { return false }
        return downloader.isCurrent(request)
    }

    func isWaitingForNetwork(_ pack: QuranImagePack) -> Bool {
        waitingKeys.contains(pack.key)
    }

    private func request(for pack: QuranImagePack) -> ContentDownloadRequest? {
        guard let remote = pack.archiveRemoteURL else { return nil }
        return ContentDownloadRequest(key: pack.key,
                                      remoteURL: remote,
                                      archiveSizeBytes: pack.archiveSizeBytes,
                                      archiveSha256: pack.archiveSha256)
    }

    func state(forJuz juz: Int) -> ContentDownloadState {
        guard let pack = pack(juz: juz) else { return .notDownloaded }
        return state(for: pack)
    }

    func isDownloaded(juz: Int) -> Bool {
        guard let pack = pack(juz: juz) else { return false }
        return isCurrent(pack)
    }

    func hasPage(_ page: Int) -> Bool {
        if manifest.isBundled(page: page) { return true }
        guard let pack = pack(forPage: page) else { return false }
        return downloader.isDownloaded(pack.key)
    }

    func renderablePages() -> Set<Int> {
        var pages = Set<Int>()
        if let bundled = manifest.bundledPageRange { pages.formUnion(bundled) }
        let installed = Set(downloader.installedKeys())
        for pack in packs where installed.contains(pack.key) {
            pages.formUnion(pack.pageRange)
        }
        return pages
    }

    func isBundled(page: Int) -> Bool {
        manifest.isBundled(page: page)
    }

    func downloadedJuzs() -> [Int] {
        let installed = Set(downloader.installedKeys())
        return packs.filter { installed.contains($0.key) }.map(\.juz)
    }

    func missingJuzs() -> [QuranImagePack] {
        downloadablePacks.filter { !isCurrent($0) }
    }

    func installedSize(juz: Int) -> Int64 {
        guard let pack = pack(juz: juz) else { return 0 }
        return downloader.installedSize(of: pack.key)
    }

    func totalInstalledSize() -> Int64 {
        downloader.totalInstalledSize()
    }

    var isDownloadingAny: Bool {
        states.values.contains(where: \.isBusy)
    }

    // MARK: - Transfer

    func download(_ pack: QuranImagePack) {
        guard let request = request(for: pack) else {
            downloader.markFailed(.unavailable, for: pack.key)
            return
        }
        downloader.download(request)
    }

    func download(juz: Int) {
        guard let pack = pack(juz: juz) else { return }
        download(pack)
    }

    func downloadPage(_ page: Int) {
        guard let pack = pack(forPage: page) else { return }
        download(pack)
    }

    func downloadAll() {
        for pack in missingJuzs() where !state(for: pack).isBusy {
            download(pack)
        }
    }

    func cancel(juz: Int) {
        guard let pack = pack(juz: juz) else { return }
        downloader.cancel(key: pack.key)
    }

    func cancelAll() {
        for pack in packs where downloader.state(forKey: pack.key).isBusy {
            downloader.cancel(key: pack.key)
        }
    }

    func delete(juz: Int) {
        guard let pack = pack(juz: juz) else { return }
        delete(key: pack.key)
    }

    func delete(key: String) {
        downloader.delete(key: key)
        didRemoveInstalledContent()
    }

    func deleteAll() {
        downloader.deleteAll()
        didRemoveInstalledContent()
    }

    func resumeInterrupted() {
        downloader.resumeInterrupted()
    }
}
