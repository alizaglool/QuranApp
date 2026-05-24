//
//  HadithReadingViewModel.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import Foundation
import Core

@MainActor
final class HadithReadingViewModel: MainViewModel {

    @Published var currentIndex: Int
    @Published var isFavorite: Bool = false

    let hadiths: [HadithEntry]
    let book: HadithBook
    var isTabBarVisible: Bool { false }

    weak var coordinator: HadithCoordinating?

    var currentHadith: HadithEntry? {
        guard currentIndex < hadiths.count else { return nil }
        return hadiths[currentIndex]
    }

    var progress: Double {
        guard hadiths.count > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(hadiths.count)
    }

    var canGoNext: Bool { currentIndex < hadiths.count - 1 }
    var canGoPrevious: Bool { currentIndex > 0 }

    init(coordinator: HadithCoordinating, hadiths: [HadithEntry], startIndex: Int, book: HadithBook) {
        self.coordinator = coordinator
        self.hadiths = hadiths
        self.book = book
        self.currentIndex = min(startIndex, max(0, hadiths.count - 1))
    }

    func onAppear() {}

    func goBack() {
        coordinator?.coordinateBack()
    }

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

    func share() {
        guard let hadith = currentHadith else { return }
        let text = "\(hadith.arabicText)\n\n\(hadith.translation)\n\n— \(hadith.narrator)"
        // Stub: share sheet handled in View
        _ = text
    }
}
