//
//  TasbihCounterViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import Foundation
import Combine

@MainActor
final class TasbihCounterViewModel: ObservableObject {

    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var currentCount: Int = 0
    @Published private(set) var isComplete: Bool = false
    @Published private(set) var justCompleted: Bool = false

    let category: DhikrCategory
    weak var coordinator: AdhkarCoordinating?

    init(coordinator: AdhkarCoordinating, category: DhikrCategory) {
        self.category = category
        self.coordinator = coordinator
    }

    var currentDhikr: Dhikr? {
        guard currentIndex < category.adhkar.count else { return nil }
        return category.adhkar[currentIndex]
    }

    var targetCount: Int { currentDhikr?.count ?? 33 }

    var tapProgress: CGFloat {
        guard targetCount > 0 else { return 0 }
        return min(CGFloat(currentCount) / CGFloat(targetCount), 1.0)
    }

    var totalDhikr: Int { category.adhkar.count }

    func tap() {
        guard targetCount > 0 else { return }
        currentCount += 1
        if currentCount >= targetCount {
            justCompleted = true
            Task {
                try? await Task.sleep(nanoseconds: 700_000_000)
                justCompleted = false
                advance()
            }
        }
    }

    func reset() {
        currentCount = 0
    }

    func advance() {
        currentCount = 0
        if currentIndex + 1 < category.adhkar.count {
            currentIndex += 1
        } else {
            isComplete = true
        }
    }

    func restart() {
        currentIndex = 0
        currentCount = 0
        isComplete = false
        justCompleted = false
    }

    func goBack() {
        coordinator?.coordinateBack()
    }
}
