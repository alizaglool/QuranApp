//
//  ProhibitedTimesViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import Foundation
import Combine
import UIKit

@MainActor
final class ProhibitedTimesViewModel: ObservableObject {

    @Published private(set) var content: ProhibitedTimesContent?
    @Published private(set) var activeWindowID: String?
    @Published var expandedWindowID: String?

    private let store = PrayerTimesStore.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    var windows: [ProhibitedWindow] { content?.windows ?? [] }

    var title: String { content?.titleAr ?? "" }

    /// Marks the window that is live right now. Text and shape carry the state
    /// alongside the red border, so it does not rest on colour alone.
    let activeBadgeTitle = "الآن"

    /// VoiceOver copy lives here rather than in the view, keeping the screen on
    /// one localisation mechanism.
    func accessibilityValue(for window: ProhibitedWindow) -> String {
        isActive(window) ? "\(window.subtitleAr)، الوقت الحالي" : window.subtitleAr
    }

    func accessibilityHint(for window: ProhibitedWindow) -> String {
        isExpanded(window) ? "إخفاء التفاصيل" : "عرض التفاصيل"
    }

    func isActive(_ window: ProhibitedWindow) -> Bool {
        window.id == activeWindowID
    }

    func isExpanded(_ window: ProhibitedWindow) -> Bool {
        window.id == expandedWindowID
    }

    func toggle(_ window: ProhibitedWindow) {
        expandedWindowID = isExpanded(window) ? nil : window.id
    }

    /// `onDisappear` normally stops the minute loop; this covers the case where
    /// the view model is released without the view ever disappearing.
    deinit {
        refreshTask?.cancel()
    }

    func onAppear() {
        if content == nil { content = ProhibitedTimesContent.bundled }
        store.load()
        observeStore()
        refreshActiveWindow()
        startRefresh()
    }

    func onDisappear() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Private

    private func observeStore() {
        guard cancellables.isEmpty else { return }
        store.$today
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshActiveWindow() }
            .store(in: &cancellables)
        // The minute loop is suspended while the app sits in the background, so
        // a screen left open overnight would still be showing last night's
        // window. Coming back to the foreground re-reads the clock.
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.store.load()
                self?.refreshActiveWindow()
            }
            .store(in: &cancellables)
    }

    private func refreshActiveWindow() {
        guard let times = store.today else {
            activeWindowID = nil
            return
        }
        let calculator = PrayerWindowCalculator(times: times)
        let active = calculator.activeProhibitedWindow(in: windows, atMinutes: times.minutes(at: Date()))
        guard active?.id != activeWindowID else { return }
        activeWindowID = active?.id
        // Opening on the live window saves the user a tap and answers the
        // question the card just raised. Done here rather than in `onAppear`
        // because on a cold launch the anchors arrive from the network a moment
        // after the screen is already up, when `activeWindowID` is still nil.
        if expandedWindowID == nil { expandedWindowID = active?.id }
    }

    private func startRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled, let self else { return }
                self.store.load()
                self.refreshActiveWindow()
            }
        }
    }
}
