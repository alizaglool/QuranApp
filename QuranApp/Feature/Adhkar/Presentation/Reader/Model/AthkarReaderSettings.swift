//
//  AthkarReaderSettings.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import Foundation
import Combine

// MARK: - Layout

enum AthkarReaderLayout: String, CaseIterable, Hashable {
    case horizontal
    case vertical
}

// MARK: - Settings

final class AthkarReaderSettings: ObservableObject {

    static let shared = AthkarReaderSettings()

    static let steps: [Int] = [85, 100, 115, 130, 140]

    private static let scaleKey = "athkar.reader.textScale"
    private static let translationKey = "athkar.reader.showsTranslation"
    private static let layoutKey = "athkar.reader.layoutMode"

    private let defaults: UserDefaults

    @Published private(set) var percent: Int
    @Published private(set) var showsTranslation: Bool
    @Published private(set) var layout: AthkarReaderLayout

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let stored = defaults.object(forKey: Self.scaleKey) as? Int ?? 0
        percent = Self.steps.contains(stored) ? stored : 100
        showsTranslation = defaults.object(forKey: Self.translationKey) as? Bool ?? true

        let storedLayout = defaults.string(forKey: Self.layoutKey) ?? ""
        layout = AthkarReaderLayout(rawValue: storedLayout) ?? .horizontal
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

    func setLayout(_ value: AthkarReaderLayout) {
        guard value != layout else { return }
        layout = value
        defaults.set(value.rawValue, forKey: Self.layoutKey)
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
