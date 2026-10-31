//
//  AthkarAudioDownloadManager.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/10/2026.
//

import Foundation
import Combine
import Core

// MARK: - Failure

typealias AthkarAudioFailure = ContentDownloadFailure

// MARK: - State

typealias AthkarAudioState = ContentDownloadState

// MARK: - Manager

final class AthkarAudioDownloadManager: ObservableObject {

    static let shared = AthkarAudioDownloadManager()

    @Published var states: [String: AthkarAudioState] = [:]

    @Published private(set) var waitingKeys: Set<String> = []

    private static let audioPrefix = "audio/"
    private static let audioFileExtension = "m4a"
    private static let stagedDirectoryName = "audio"
    static let backgroundSessionIdentifier = "com.quranapp.athkar.audio.transfer"

    private let fileManager: FileManager
    private let downloader: ContentDownloader
    private let expectedAudioFileNames: (String) -> Set<String>
    private let publishedArchiveChecksum: (String) -> String?
    private var cancellable: AnyCancellable?
    private var waitingCancellable: AnyCancellable?

    init(fileManager: FileManager = .default,
         rootDirectory: URL? = nil,
         expectedAudioFileNames: @escaping (String) -> Set<String> = { AthkarAudioDownloadManager.declaredAudioFileNames(inPack: $0) },
         publishedArchiveChecksum: @escaping (String) -> String? = { AthkarManifestService.shared.pack(key: $0)?.archiveSha256 }) {
        self.fileManager = fileManager
        self.expectedAudioFileNames = expectedAudioFileNames
        self.publishedArchiveChecksum = publishedArchiveChecksum

        let root = rootDirectory ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        downloader = ContentDownloader(
            contentRoot: root.appendingPathComponent("athkar_audio", isDirectory: true),
            stagingRoot: root.appendingPathComponent("athkar_audio_staging", isDirectory: true),
            queueLabel: "com.quranapp.athkar.audio.install",
            sessionIdentifier: Self.backgroundSessionIdentifier,
            excludedFromBackup: true,
            fileManager: fileManager,
            isInstalled: { directory in
                guard let contents = try? fileManager.contentsOfDirectory(atPath: directory.path) else { return false }

                let installed = Set(contents.filter { $0.hasSuffix(".\(Self.audioFileExtension)") })
                guard !installed.isEmpty else { return false }

                let expected = expectedAudioFileNames(Self.packKey(at: directory))
                guard !expected.isEmpty else { return true }

                return expected.isSubset(of: installed)
            },
            stage: { _, archive, staging in
                let raw = staging.appendingPathComponent("raw", isDirectory: true)
                let flat = staging.appendingPathComponent(Self.stagedDirectoryName, isDirectory: true)
                try? fileManager.removeItem(at: raw)
                try? fileManager.removeItem(at: flat)

                let written = try AthkarArchive.extract(archiveAt: archive, to: raw) { entry in
                    entry.path.hasPrefix(Self.audioPrefix) && entry.path.hasSuffix(".\(Self.audioFileExtension)")
                }

                try fileManager.createDirectory(at: flat, withIntermediateDirectories: true)
                for file in written {
                    let target = flat.appendingPathComponent(file.lastPathComponent)
                    try? fileManager.removeItem(at: target)
                    try fileManager.moveItem(at: file, to: target)
                }
                return flat
            }
        )

        cancellable = downloader.$states.sink { [weak self] in self?.states = $0 }

        waitingCancellable = downloader.$waitingKeys
            .receive(on: DispatchQueue.main)
            .sink { [weak self] keys in
                guard let self, self.waitingKeys != keys else { return }
                self.waitingKeys = keys
            }
    }

    // MARK: - Expected contents

    static func declaredAudioFileNames(inPack key: String) -> Set<String> {
        let names = AthkarPackStore.shared.items(forKey: key)
            .filter { $0.hasAudio }
            .map { ($0.audio as NSString).lastPathComponent }
            .filter { $0.hasSuffix(".\(audioFileExtension)") }

        return Set(names)
    }

    private static func packKey(at directory: URL) -> String {
        let name = directory.lastPathComponent
        guard name == stagedDirectoryName else { return name }
        return directory.deletingLastPathComponent().lastPathComponent
    }

    // MARK: - Paths

    func directory(forKey key: String) -> URL {
        downloader.directory(forKey: key)
    }

    func localURL(for item: AthkarItem, inPack key: String) -> URL? {
        guard item.hasAudio else { return nil }
        return localURL(forFileNamed: (item.audio as NSString).lastPathComponent, inPack: key)
    }

    func localURL(forFileNamed name: String, inPack key: String) -> URL? {
        guard isInstallCurrent(key) else { return nil }
        let url = directory(forKey: key).appendingPathComponent(name)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Status

    func isDownloaded(_ key: String) -> Bool {
        downloader.isDownloaded(key) && isInstallCurrent(key)
    }

    func isInstallCurrent(_ key: String) -> Bool {
        guard let published = publishedArchiveChecksum(key) else { return true }
        guard let installed = downloader.installedChecksum(key) else { return false }
        return installed.caseInsensitiveCompare(published) == .orderedSame
    }

    func state(for pack: AthkarPack) -> AthkarAudioState {
        guard let request = request(for: pack) else { return downloader.state(forKey: pack.key) }
        return downloader.state(for: request)
    }

    func installedSize(of key: String) -> Int64 {
        downloader.installedSize(of: key)
    }

    func isWaitingForNetwork(_ key: String) -> Bool {
        downloader.isWaitingForNetwork(key)
    }

    // MARK: - Transfer

    func download(pack: AthkarPack) {
        guard let request = request(for: pack) else {
            downloader.markFailed(.unavailable, for: pack.key)
            return
        }
        downloader.download(request)
    }

    private func request(for pack: AthkarPack) -> ContentDownloadRequest? {
        guard pack.hasAudio, let remote = pack.archiveRemoteURL else { return nil }
        return ContentDownloadRequest(key: pack.key,
                                      remoteURL: remote,
                                      archiveSizeBytes: pack.archiveSizeBytes,
                                      archiveSha256: pack.archiveSha256)
    }

    func resumeInterrupted() {
        downloader.resumeInterrupted()
    }

    func cancel(key: String) {
        downloader.cancel(key: key)
    }

    func delete(key: String) {
        downloader.delete(key: key)
    }
}
