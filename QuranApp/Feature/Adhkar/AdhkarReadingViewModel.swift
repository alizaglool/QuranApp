//
//  AdhkarReadingViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import Foundation
import Core

@MainActor
final class AdhkarReadingViewModel: MainViewModel {

    @Published var currentIndex: Int = 0
    @Published var currentTapCount: Int = 0
    @Published var isComplete: Bool = false

    let category: DhikrCategory
    var isTabBarVisible: Bool { false }

    var currentDhikr: Dhikr? {
        guard currentIndex < category.adhkar.count else { return nil }
        return category.adhkar[currentIndex]
    }

    var overallProgress: Double {
        let total = category.adhkar.count
        guard total > 0 else { return 0 }
        return Double(currentIndex) / Double(total)
    }

    var tapProgress: Double {
        guard let dhikr = currentDhikr, dhikr.count > 0 else { return 0 }
        return Double(currentTapCount) / Double(dhikr.count)
    }

    init(category: DhikrCategory) {
        self.category = category
    }

    func onAppear() {}

    func onTap() {
        guard let dhikr = currentDhikr else { return }
        currentTapCount += 1
        if currentTapCount >= dhikr.count {
            advanceToNext()
        }
    }

    func reset() {
        currentIndex = 0
        currentTapCount = 0
        isComplete = false
    }

    private func advanceToNext() {
        currentTapCount = 0
        if currentIndex < category.adhkar.count - 1 {
            currentIndex += 1
        } else {
            isComplete = true
        }
    }
}
