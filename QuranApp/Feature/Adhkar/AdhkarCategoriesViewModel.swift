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

    @Published var categories: [DhikrCategory] = []

    var isTabBarVisible: Bool { true }
    
    func onAppear() {
        guard categories.isEmpty else { return }
        loadCategories()
    }

    private func loadCategories() {
        guard let url = Bundle.main.url(forResource: "adhkar", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([DhikrCategory].self, from: data) else {
            return
        }
        categories = decoded
    }
}
