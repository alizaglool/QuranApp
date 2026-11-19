//
//  PrayerWidgetPalette.swift
//  WirdWidget
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI

enum PrayerWidgetPalette {

    static let accent = Color("Primary Color")
    static let title = Color.primary
    static let caption = Color.secondary
    static let separator = Color.primary.opacity(0.08)
    static let highlight = Color("Primary Color").opacity(0.12)
}

// MARK: - Gallery

enum PrayerWidgetGalleryText {

    static func text(_ keyPath: KeyPath<PrayerWidgetLabels, String>) -> String {
        let stored = PrayerWidgetSharedStore.loadSnapshot()?.labels[keyPath: keyPath] ?? ""
        return stored.isEmpty ? applicationName : stored
    }

    static var applicationName: String {
        let displayName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        return displayName ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
}

// MARK: - Localization

extension View {

    func prayerWidgetEnvironment(_ snapshot: PrayerWidgetSnapshot) -> some View {
        environment(\.layoutDirection, snapshot.isRightToLeft ? .rightToLeft : .leftToRight)
            .environment(\.locale, Locale(identifier: snapshot.languageCode))
    }
}
