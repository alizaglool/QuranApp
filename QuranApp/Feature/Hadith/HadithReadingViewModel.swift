//
//  HadithReadingViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import Core

@MainActor
final class HadithReadingViewModel: MainViewModel {

    @Published var currentIndex: Int = 0
    @Published var isFavorite: Bool = false

    let collection: HadithCollection
    var isTabBarVisible: Bool { false }

    var currentHadith: Hadith? {
        guard currentIndex < collection.hadiths.count else { return nil }
        return collection.hadiths[currentIndex]
    }

    var progress: Double {
        let total = collection.hadiths.count
        guard total > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(total)
    }

    var canGoNext: Bool { currentIndex < collection.hadiths.count - 1 }
    var canGoPrevious: Bool { currentIndex > 0 }

    init(collection: HadithCollection) {
        self.collection = collection
    }

    func onAppear() {}

    func next() {
        guard canGoNext else { return }
        currentIndex += 1
    }

    func previous() {
        guard canGoPrevious else { return }
        currentIndex -= 1
    }

    func toggleFavorite() {
        isFavorite.toggle()
    }
}
