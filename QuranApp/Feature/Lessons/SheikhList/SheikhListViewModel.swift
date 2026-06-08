//
//  SheikhListViewModel.swift
//  QuranApp
//

import Foundation
import Core

enum SheikhSortOption: String, CaseIterable {
    case subscribers = "الأكثر متابعين"
    case nameAZ      = "الاسم أ-ي"
    case nameZA      = "الاسم ي-أ"
    case videoCount  = "الأكثر فيديوهات"
}

enum SheikhFilter: String, CaseIterable {
    case all     = "ALL SHEIKHS"
    case tafsir  = "TAFSIR"
    case fiqh    = "FIQH"
    case hadith  = "HADITH"
    case seerah  = "SEERAH"
}

@MainActor
final class SheikhListViewModel: MainViewModel {

    @Published var sheikhs: [Sheikh] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var sortOption: SheikhSortOption = .subscribers
    @Published var hasMorePages: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    @Published var selectedFilter: SheikhFilter = .all

    var displayedSheikhs: [Sheikh] {
        guard !searchText.isEmpty else { return sheikhs }
        return allSheikhs.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.channelHandle.localizedCaseInsensitiveContains(searchText)
        }
    }

    weak var coordinator: (any LessonsCoordinating)?

    private var allSheikhs: [Sheikh] = []
    private var displayedPage: Int = 0
    private let pageSize = 20

    init(coordinator: (any LessonsCoordinating)?) {
        self.coordinator = coordinator
    }

    func onAppear() {
        guard allSheikhs.isEmpty else { return }
        Task { await loadInitialData() }
    }

    func onDisappear() {}

    var isTabBarVisible: Bool { true }
}

// MARK: - Data Loading

extension SheikhListViewModel {

    func loadInitialData() async {
        isLoading = true
        errorMessage = nil

        do {
            let ids = try await RemoteConfigService.shared.fetchChannelIds()
            let fetched = try await BatchService.shared.fetchSheikhs(from: ids)
            allSheikhs = sorted(fetched, by: sortOption)
            displayedPage = 0
            sheikhs = nextPage()
            hasMorePages = sheikhs.count < allSheikhs.count
        } catch {
            errorMessage = "تعذّر تحميل المشايخ، تحقق من الاتصال وأعد المحاولة."
        }

        isLoading = false
    }

    func loadNextPage() {
        guard !isLoadingMore, hasMorePages else { return }
        isLoadingMore = true

        let next = nextPage()
        sheikhs.append(contentsOf: next)
        hasMorePages = sheikhs.count < allSheikhs.count
        isLoadingMore = false
    }

    func refreshData() {
        RemoteConfigService.shared.invalidateCache()
        allSheikhs = []
        sheikhs = []
        displayedPage = 0
        Task { await loadInitialData() }
    }

    func updateSort(_ option: SheikhSortOption) {
        sortOption = option
        allSheikhs = sorted(allSheikhs, by: option)
        displayedPage = 0
        sheikhs = nextPage()
        hasMorePages = sheikhs.count < allSheikhs.count
    }

    // MARK: Navigation

    func onSheikhTapped(_ sheikh: Sheikh) {
        coordinator?.coordinateToSheikhDetail(sheikh: sheikh)
    }

    // MARK: Private helpers

    private func nextPage() -> [Sheikh] {
        let start = displayedPage * pageSize
        let end = Swift.min(start + pageSize, allSheikhs.count)
        guard start < allSheikhs.count else { return sheikhs }
        displayedPage += 1
        return Array(allSheikhs[start..<end])
    }

    private func sorted(_ list: [Sheikh], by option: SheikhSortOption) -> [Sheikh] {
        switch option {
        case .subscribers: return list.sorted { $0.subscriberCount > $1.subscriberCount }
        case .nameAZ:      return list.sorted { $0.name < $1.name }
        case .nameZA:      return list.sorted { $0.name > $1.name }
        case .videoCount:  return list.sorted { $0.videoCount > $1.videoCount }
        }
    }
}
