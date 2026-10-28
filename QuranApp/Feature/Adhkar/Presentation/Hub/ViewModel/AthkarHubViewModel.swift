//
//  AthkarHubViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import Foundation
import Combine
import UIKit
import Core

@MainActor
final class AthkarHubViewModel: MainViewModel {

    // MARK: - Output

    @Published private(set) var catalog: AthkarHubCatalog?
    @Published private(set) var specialCategories: [DhikrCategory] = []
    @Published private(set) var audioStates: [String: AthkarAudioState] = [:]
    @Published private(set) var banner: AthkarHubBanner?
    @Published private(set) var activeProhibitedWindow: ProhibitedWindow?
    @Published private(set) var prohibitedCardTitle = ""
    @Published private(set) var allahNames: [AllahName] = []

    private var tasbihCategory: DhikrCategory?
    private var moreCategories: [DhikrCategory] = []
    private var conditionalCategories: [DhikrCategory] = []
    private var prohibitedWindows: [ProhibitedWindow] = []

    private let manifestService = AthkarManifestService.shared
    private let packStore = AthkarPackStore.shared
    private let downloads = AthkarAudioDownloadManager.shared
    private let prayerTimesStore = PrayerTimesStore.shared
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    var isTabBarVisible: Bool { true }

    weak var coordinator: AdhkarCoordinating?

    init(coordinator: AdhkarCoordinating) {
        self.coordinator = coordinator
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Strings

    var screenTitle: String { AppLocalizedKeys.adhkar.value }

    var allahNamesTitle: String { AppLocalizedKeys.allahNamesTitle.value }

    var allahNamesSubtitle: String { AppLocalizedKeys.allahNamesSubtitle.value }

    var myAdhkarTitle: String { AppLocalizedKeys.myAdhkarTitle.value }

    var myAdhkarSubtitle: String { AppLocalizedKeys.myAdhkarSubtitle.value }

    var tasbihTitle: String { tasbihCategory.map(title(of:)) ?? "" }

    var tasbihSubtitle: String { AppLocalizedKeys.tapToCount.value }

    var hasTasbihCard: Bool { tasbihCategory != nil }

    var hasSpecialContent: Bool { !specialCategories.isEmpty || activeProhibitedWindow != nil }

    // MARK: - Sections

    var sections: [AthkarHubSection] {
        guard let catalog else { return [] }

        return [
            AthkarHubSection(id: .daily,
                             title: AppLocalizedKeys.athkarHubDailyTitle.value,
                             subtitle: AppLocalizedKeys.athkarHubDailySubtitle.value,
                             layout: .grid,
                             packs: catalog.daily),
            AthkarHubSection(id: .count,
                             title: AppLocalizedKeys.athkarHubCountTitle.value,
                             subtitle: AppLocalizedKeys.athkarHubCountSubtitle.value,
                             layout: .list,
                             packs: catalog.countable),
            AthkarHubSection(id: .duaa,
                             title: AppLocalizedKeys.athkarHubDuaaTitle.value,
                             subtitle: AppLocalizedKeys.athkarHubDuaaSubtitle.value,
                             layout: .list,
                             packs: catalog.duaa)
        ].filter { !$0.isEmpty }
    }

    var shortcutPacks: [AthkarPack] {
        ["morning", "evening", "sleep"].compactMap { manifestService.pack(key: $0) }
    }

    func title(of category: DhikrCategory) -> String {
        LocalizationManager.shared.currentLanguage == .Arabic ? category.titleAr : category.titleEn
    }

    func countLabel(for pack: AthkarPack) -> String {
        let key: AppLocalizedKeys = pack.kind == .list ? .athkarDuaaCount : .adhkarCount
        return String(format: key.value, pack.itemCount)
    }

    func downloadAllLabel(for section: AthkarHubSection) -> String {
        String(format: AppLocalizedKeys.athkarDownloadAll.value, section.downloadablePacks.count)
    }

    func showsDownloadAll(_ section: AthkarHubSection) -> Bool {
        section.downloadablePacks.contains { state(for: $0) != .downloaded }
    }

    func state(for pack: AthkarPack) -> AthkarAudioState {
        audioStates[pack.key] ?? .notDownloaded
    }

    // MARK: - Lifecycle

    func onAppear() {
        if catalog == nil {
            loadCatalog()
            loadCategories()
            loadAllahNames()
            loadProhibitedTimes()
        }
        prayerTimesStore.loadTodayForSelectedLocation()
        observe()
        refreshVisibility()
        startVisibilityRefresh()
    }

    func onDisappear() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Actions

    func selectPack(_ pack: AthkarPack) {
        let items = packStore.items(forKey: pack.key)
        guard !items.isEmpty else { return }
        coordinator?.coordinateToAthkarReader(pack: pack, items: items)
    }

    func selectBanner() {
        guard let banner, let pack = manifestService.pack(key: banner.packKey) else { return }
        selectPack(pack)
    }

    func selectCategory(_ category: DhikrCategory) {
        coordinator?.coordinateToAdhkarReading(category: category)
    }

    func selectTasbih() {
        guard let tasbihCategory else { return }
        coordinator?.coordinateToAdhkarReading(category: tasbihCategory)
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

    func toggleDownload(_ pack: AthkarPack) {
        switch state(for: pack) {
        case .downloading:  downloads.cancel(key: pack.key)
        case .installing:   break
        case .downloaded:   break
        default:            downloads.download(pack: pack)
        }
    }

    func downloadAll(in section: AthkarHubSection) {
        for pack in section.downloadablePacks where state(for: pack) != .downloaded {
            downloads.download(pack: pack)
        }
    }

    // MARK: - Loading

    private func loadCatalog() {
        catalog = AthkarHubCatalog(manifest: manifestService.load())
    }

    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "adhkar", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([DhikrCategory].self, from: data) else { return }

        moreCategories = decoded.filter { $0.section == "more" }
        conditionalCategories = decoded.filter { $0.section == "special" }
        tasbihCategory = moreCategories.first { $0.id == "tasbih_extra" }
    }

    private func loadAllahNames() {
        guard let url = Bundle.main.url(forResource: "allahNames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AllahName].self, from: data) else { return }
        allahNames = decoded
    }

    private func loadProhibitedTimes() {
        guard let content = ProhibitedTimesContent.bundled else { return }
        prohibitedWindows = content.windows
        prohibitedCardTitle = content.titleAr
    }

    // MARK: - Observation

    private func observe() {
        guard cancellables.isEmpty else { return }

        downloads.$states
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.audioStates = $0 }
            .store(in: &cancellables)

        prayerTimesStore.$today
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshVisibility() }
            .store(in: &cancellables)

        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.prayerTimesStore.loadTodayForSelectedLocation()
                self?.refreshVisibility()
            }
            .store(in: &cancellables)
    }

    private func refreshVisibility() {
        let now = Date()
        let times = prayerTimesStore.today
        let service = DhikrVisibilityService(prayerTimes: times)

        let visible = conditionalCategories.filter { category in
            guard let condition = category.condition else { return true }
            return service.isOpen(condition: condition, on: now)
        }
        if visible != specialCategories { specialCategories = visible }

        refreshBanner(service: service, now: now)
        refreshProhibitedWindow(times: times, now: now)
    }

    private func refreshBanner(service: DhikrVisibilityService, now: Date) {
        let windows: [(DhikrCondition, AppLocalizedKeys, String)] = [
            (.morning, .athkarMorningTitle, "morning"),
            (.evening, .athkarEveningTitle, "evening"),
            (.afterIsha, .athkarAfterIshaTitle, "sleep"),
            (.lastThirdOfNight, .athkarLastThirdTitle, "sleep")
        ]

        guard let open = windows.first(where: { service.isOpen($0.0, on: now) }),
              let pack = manifestService.pack(key: open.2) else {
            if banner != nil { banner = nil }
            return
        }

        let next = AthkarHubBanner(badge: AppLocalizedKeys.homeNowBadge.value,
                                   title: open.1.value,
                                   icon: AthkarPackIcon.symbol(for: pack.key),
                                   packKey: pack.key)
        if next != banner { banner = next }
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
                self.prayerTimesStore.loadTodayForSelectedLocation()
                self.refreshVisibility()
            }
        }
    }
}
