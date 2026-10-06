//
//  AdhkarCategoriesViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import Combine
import UIKit
import Core

@MainActor
final class AdhkarCategoriesViewModel: MainViewModel {

    @Published var dailyCategories: [DhikrCategory] = []
    @Published var specialCategories: [DhikrCategory] = []
    @Published var moreCategories: [DhikrCategory] = []
    @Published var allahNames: [AllahName] = []

    /// Set only while the clock sits inside one of the four windows in which
    /// voluntary prayer is not offered; `nil` hides the card entirely.
    @Published private(set) var activeProhibitedWindow: ProhibitedWindow?

    /// Read from the bundled document. `activeProhibitedWindow` keeps the card
    /// hidden until the content is in place, so the empty start value never shows.
    @Published private(set) var prohibitedCardTitle = ""

    private var conditionalCategories: [DhikrCategory] = []
    private var prohibitedWindows: [ProhibitedWindow] = []
    private let prayerTimesStore = PrayerTimesStore.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    var isTabBarVisible: Bool { true }

    var hasSpecialContent: Bool { !specialCategories.isEmpty || activeProhibitedWindow != nil }

    weak var coordinator: AdhkarCoordinating?

    init(coordinator: AdhkarCoordinating) {
        self.coordinator = coordinator
    }

    /// `onDisappear` normally stops the minute loop; this covers the case where
    /// the view model is released without the view ever disappearing.
    deinit {
        refreshTask?.cancel()
    }

    func selectCategory(_ category: DhikrCategory) {
        coordinator?.coordinateToAdhkarReading(category: category)
    }

    func selectAllahNames() {
        coordinator?.coordinateToAllahNames(names: allahNames)
    }

    func selectMyAdhkar() {
        coordinator?.coordinateToMyAdhkar()
    }

    func selectProhibitedTimes() {
        coordinator?.coordinateToProhibitedTimes()
    }

    func onAppear() {
        if dailyCategories.isEmpty {
            loadCategories()
            loadAllahNames()
            loadProhibitedTimes()
        }
        prayerTimesStore.load()
        observePrayerTimes()
        refreshSpecialCategories()
        startVisibilityRefresh()
    }

    func onDisappear() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "adhkar", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([DhikrCategory].self, from: data) else { return }

        dailyCategories = decoded.filter { ($0.section ?? "daily") == "daily" }
        moreCategories = decoded.filter { $0.section == "more" }
        conditionalCategories = decoded.filter { $0.section == "special" }
    }

    private func loadProhibitedTimes() {
        guard let content = ProhibitedTimesContent.bundled else { return }
        prohibitedWindows = content.windows
        prohibitedCardTitle = content.titleAr
    }

    private func loadAllahNames() {
        guard let url = Bundle.main.url(forResource: "allahNames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AllahName].self, from: data) else { return }
        allahNames = decoded
    }

    private func observePrayerTimes() {
        guard cancellables.isEmpty else { return }
        prayerTimesStore.$today
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshSpecialCategories() }
            .store(in: &cancellables)
        // Backgrounding suspends the minute loop, so returning to the tab hours
        // later would otherwise still show the window that was open on exit.
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.prayerTimesStore.load()
                self?.refreshSpecialCategories()
            }
            .store(in: &cancellables)
    }

    private func refreshSpecialCategories() {
        let now = Date()
        let times = prayerTimesStore.today
        let visibilityService = DhikrVisibilityService(prayerTimes: times)

        let visible = conditionalCategories.filter { category in
            guard let condition = category.condition else { return true }
            return visibilityService.isOpen(condition: condition, on: now)
        }
        if visible != specialCategories {
            specialCategories = visible
        }

        refreshProhibitedWindow(times: times, now: now)
    }

    private func refreshProhibitedWindow(times: DayPrayerTimes?, now: Date) {
        guard let times else {
            if activeProhibitedWindow != nil { activeProhibitedWindow = nil }
            return
        }
        let calculator = PrayerWindowCalculator(times: times)
        let active = calculator.activeProhibitedWindow(in: prohibitedWindows, atMinutes: times.minutes(at: now))
        guard active?.id != activeProhibitedWindow?.id else { return }
        activeProhibitedWindow = active
    }

    private func startVisibilityRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled, let self else { return }
                // Also rolls the day over: `load()` no-ops until the date key
                // moves, so a session left open past local midnight picks up
                // tomorrow's anchors instead of gating on yesterday's.
                self.prayerTimesStore.load()
                self.refreshSpecialCategories()
            }
        }
    }
}
