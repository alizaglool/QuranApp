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
        guard dailyCategories.isEmpty else { return }
        loadCategories()
        loadAllahNames()
    }

    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "adhkar", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([DhikrCategory].self, from: data) else { return }

        let today = Date()
        dailyCategories = decoded.filter { ($0.section ?? "daily") == "daily" }
        moreCategories = decoded.filter { $0.section == "more" }
        specialCategories = decoded.filter { $0.section == "special" }.filter { cat in
            guard let condition = cat.condition else { return true }
            return satisfiesCondition(condition, on: today)
        }
    }

    private func loadAllahNames() {
        guard let url = Bundle.main.url(forResource: "allahNames", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([AllahName].self, from: data) else { return }
        allahNames = decoded
    }

    private func satisfiesCondition(_ condition: String, on date: Date) -> Bool {
        switch condition {
        case "dhul_hijjah_1_10":
            return isDhulHijjahFirstTenDays(date)
        default:
            return true
        }
    }

    private func isDhulHijjahFirstTenDays(_ date: Date) -> Bool {
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let components = hijriCalendar.dateComponents([.month, .day], from: date)
        let month = components.month ?? 0
        let day = components.day ?? 0
        return month == 12 && day >= 1 && day <= 10
    }
}
