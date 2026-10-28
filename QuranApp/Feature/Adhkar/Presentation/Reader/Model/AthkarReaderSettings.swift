//
//  AthkarReaderSettings.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import Foundation
import Combine

final class AthkarReaderSettings: ObservableObject {

    static let shared = AthkarReaderSettings()

    static let steps: [Int] = [85, 100, 115, 130, 140]

    private static let scaleKey = "athkar.reader.textScale"
    private static let translationKey = "athkar.reader.showsTranslation"

    private let defaults: UserDefaults

    @Published private(set) var percent: Int
    @Published private(set) var showsTranslation: Bool

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let stored = defaults.object(forKey: Self.scaleKey) as? Int ?? 0
        percent = Self.steps.contains(stored) ? stored : 100
        showsTranslation = defaults.object(forKey: Self.translationKey) as? Bool ?? true
    }

    // MARK: - Output

    var scale: CGFloat { CGFloat(percent) / 100 }

    var minimumPercent: Int { Self.steps.first ?? 100 }

    var maximumPercent: Int { Self.steps.last ?? 100 }

    var canShrink: Bool { percent > minimumPercent }

    var canGrow: Bool { percent < maximumPercent }

    // MARK: - Actions

    func shrink() {
        guard let index = Self.steps.lastIndex(where: { $0 < percent }) else { return }
        apply(percent: Self.steps[index])
    }

    func grow() {
        guard let index = Self.steps.firstIndex(where: { $0 > percent }) else { return }
        apply(percent: Self.steps[index])
    }

    func setShowsTranslation(_ value: Bool) {
        guard value != showsTranslation else { return }
        showsTranslation = value
        defaults.set(value, forKey: Self.translationKey)
    }

    // MARK: - Storage

    private func apply(percent value: Int) {
        guard value != percent else { return }
        percent = value
        defaults.set(value, forKey: Self.scaleKey)
    }
}
