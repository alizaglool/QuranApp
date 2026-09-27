//
//  AdhkarCategoriesViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import Core

@MainActor
final class AdhkarCategoriesViewModel: MainViewModel {

    @Published var dailyCategories: [DhikrCategory] = []
    @Published var specialCategories: [DhikrCategory] = []
    @Published var moreCategories: [DhikrCategory] = []
    @Published var allahNames: [AllahName] = []

    private var conditionalCategories: [DhikrCategory] = []
    private let visibilityService = DhikrVisibilityService()
    private var refreshTask: Task<Void, Never>?

    var isTabBarVisible: Bool { true }

    var hasSpecialContent: Bool { !specialCategories.isEmpty }

    weak var coordinator: AdhkarCoordinating?

    init(coordinator: AdhkarCoordinating) {
        self.coordinator = coordinator
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

    func onAppear() {
        if dailyCategories.isEmpty {
            loadCategories()
            loadAllahNames()
        }
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

    private func loadAllahNames() {
        guard let url = Bundle.main.url(forResource: "allahNames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AllahName].self, from: data) else { return }
        allahNames = decoded
    }

    private func refreshSpecialCategories() {
        let now = Date()
        let visible = conditionalCategories.filter { category in
            guard let condition = category.condition else { return true }
            return visibilityService.isOpen(condition: condition, on: now)
        }
        guard visible != specialCategories else { return }
        specialCategories = visible
    }

    private func startVisibilityRefresh() {
        guard refreshTask == nil else { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled else { return }
                self?.refreshSpecialCategories()
            }
        }
    }
}
