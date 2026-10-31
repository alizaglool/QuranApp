//
//  QuranFullDownloadStatus.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import Foundation

// MARK: - Stage

enum QuranFullDownloadStage: Equatable {
    case notDownloaded
    case downloading
    case downloaded
    case failed(ContentDownloadFailure)
}

// MARK: - Status

struct QuranFullDownloadStatus: Equatable {

    static let spaceMarginBytes: Int64 = 32 * 1024 * 1024

    let stage: QuranFullDownloadStage
    let downloadedBytes: Int64
    let totalBytes: Int64
    let installedPackCount: Int
    let totalPackCount: Int
    let isInstalling: Bool
    let isWaitingForNetwork: Bool

    static let unavailable = QuranFullDownloadStatus(stage: .notDownloaded,
                                                     downloadedBytes: 0,
                                                     totalBytes: 0,
                                                     installedPackCount: 0,
                                                     totalPackCount: 0,
                                                     isInstalling: false,
                                                     isWaitingForNetwork: false)
}

// MARK: - Output

extension QuranFullDownloadStatus {

    var fraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(downloadedBytes) / Double(totalBytes)))
    }

    var percent: Int {
        guard !isComplete else { return 100 }
        return min(99, Int((fraction * 100).rounded(.down)))
    }

    var remainingBytes: Int64 { max(0, totalBytes - downloadedBytes) }

    var remainingPackCount: Int { max(0, totalPackCount - installedPackCount) }

    var isDownloading: Bool { stage == .downloading }

    var isComplete: Bool { stage == .downloaded }

    var hasFailed: Bool {
        guard case .failed = stage else { return false }
        return true
    }

    var isAvailable: Bool { totalPackCount > 0 }

    var requiredFreeBytes: Int64 { Self.requiredFreeBytes(forRemaining: remainingBytes) }

    func markingInsufficientStorage() -> QuranFullDownloadStatus {
        QuranFullDownloadStatus(stage: .failed(.noSpace),
                                downloadedBytes: downloadedBytes,
                                totalBytes: totalBytes,
                                installedPackCount: installedPackCount,
                                totalPackCount: totalPackCount,
                                isInstalling: false,
                                isWaitingForNetwork: false)
    }
}

// MARK: - Resolution

extension QuranFullDownloadStatus {

    static func resolve(packs: [QuranImagePack],
                        currentKeys: Set<String>,
                        states: [String: ContentDownloadState],
                        waitingKeys: Set<String>) -> QuranFullDownloadStatus {
        guard !packs.isEmpty else { return .unavailable }

        var downloadedBytes: Int64 = 0
        var installedCount: Int = 0
        var busyKeys: [String] = []
        var isInstalling: Bool = false
        var failure: ContentDownloadFailure?

        for pack in packs {
            let size = Int64(pack.archiveSizeBytes)

            guard !currentKeys.contains(pack.key) else {
                downloadedBytes += size
                installedCount += 1
                continue
            }

            switch states[pack.key] {
            case let .downloading(progress):
                busyKeys.append(pack.key)
                downloadedBytes += transferredBytes(of: size, progress: progress)

            case .installing:
                busyKeys.append(pack.key)
                isInstalling = true
                downloadedBytes += size

            case let .failed(reason):
                failure = preferredFailure(failure, reason)

            case .downloaded, .notDownloaded, .none:
                break
            }
        }

        return QuranFullDownloadStatus(
            stage: stage(busyKeys: busyKeys,
                         installedCount: installedCount,
                         packCount: packs.count,
                         failure: failure),
            downloadedBytes: downloadedBytes,
            totalBytes: packs.reduce(0) { $0 + Int64($1.archiveSizeBytes) },
            installedPackCount: installedCount,
            totalPackCount: packs.count,
            isInstalling: isInstalling,
            isWaitingForNetwork: !busyKeys.isEmpty && busyKeys.allSatisfy(waitingKeys.contains)
        )
    }

    static func transferredBytes(of size: Int64, progress: Double) -> Int64 {
        let share = ContentDownloader.transferShare
        guard share > 0, size > 0 else { return 0 }
        let ratio = min(1, max(0, progress / share))
        return Int64((Double(size) * ratio).rounded())
    }

    private static func stage(busyKeys: [String],
                              installedCount: Int,
                              packCount: Int,
                              failure: ContentDownloadFailure?) -> QuranFullDownloadStage {
        guard busyKeys.isEmpty else { return .downloading }
        guard installedCount < packCount else { return .downloaded }
        guard let failure else { return .notDownloaded }
        return .failed(failure)
    }

    private static func preferredFailure(_ existing: ContentDownloadFailure?,
                                         _ incoming: ContentDownloadFailure) -> ContentDownloadFailure {
        guard let existing else { return incoming }
        guard existing != .noSpace, incoming != .noSpace else { return .noSpace }
        return existing
    }
}

// MARK: - Storage

extension QuranFullDownloadStatus {

    static func requiredFreeBytes(forRemaining remaining: Int64) -> Int64 {
        max(0, remaining) * 2 + spaceMarginBytes
    }

    static func hasRoom(forRemaining remaining: Int64, availableBytes: Int64?) -> Bool {
        guard let availableBytes else { return true }
        return availableBytes > requiredFreeBytes(forRemaining: remaining)
    }
}
