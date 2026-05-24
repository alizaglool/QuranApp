//
//  HadithLibraryViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import Core

@MainActor
final class HadithLibraryViewModel: MainViewModel {

    @Published var collections: [HadithCollection] = []

    var isTabBarVisible: Bool { true }

    weak var coordinator: HadithCoordinating?

    init(coordinator: HadithCoordinating) {
        self.coordinator = coordinator
    }

    func selectCollection(_ collection: HadithCollection) {
        coordinator?.coordinateToHadithReading(collection: collection)
    }

    func onAppear() {
        guard collections.isEmpty else { return }
        loadCollections()
    }

    private func loadCollections() {
        guard let url = Bundle.main.url(forResource: "hadith", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([HadithCollection].self, from: data) else { return }
        collections = decoded
    }
}
