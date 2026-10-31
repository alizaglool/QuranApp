//
//  ContentCatalogRefresher.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import UIKit

// MARK: - Refresher

@MainActor
final class ContentCatalogRefresher {

    static let shared = ContentCatalogRefresher()

    private static let lastRefreshDefaultsKey = "contentCatalogLastRefreshTimestamp"
    private static let minimumRefreshInterval: TimeInterval = 6 * 60 * 60

    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private var foregroundObserver: NSObjectProtocol?
    private var isRefreshing = false

    init(defaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
    }

    // MARK: - Lifecycle

    func start() {
        guard foregroundObserver == nil else { return }

        foregroundObserver = notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { ContentCatalogRefresher.shared.resume() }
        }

        resume()
    }

    private func resume() {
        QuranImagePackStore.shared.resumeInterrupted()
        AthkarAudioDownloadManager.shared.resumeInterrupted()
        refreshIfDue()
    }

    // MARK: - Refresh

    func refreshIfDue(force: Bool = false) {
        guard !isRefreshing, force || isDue else { return }
        isRefreshing = true

        Task { [weak self] in
            await QuranImagePackStore.shared.refreshCatalog()
            await AthkarManifestService.shared.refresh()
            self?.finish()
        }
    }

    private func finish() {
        isRefreshing = false
        defaults.set(Date().timeIntervalSince1970, forKey: Self.lastRefreshDefaultsKey)
    }

    private var isDue: Bool {
        let last = defaults.double(forKey: Self.lastRefreshDefaultsKey)
        guard last > 0 else { return true }
        return Date().timeIntervalSince1970 - last >= Self.minimumRefreshInterval
    }
}
