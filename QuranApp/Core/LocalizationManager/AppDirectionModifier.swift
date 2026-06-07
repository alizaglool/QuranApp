//
//  AppDirectionModifier.swift
//  QuranApp
//

import SwiftUI
import Core

private struct AppDirectionModifier: ViewModifier {
    @ObservedObject private var localization = LocalizationManager.shared

    func body(content: Content) -> some View {
        content.environment(\.layoutDirection, localization.currentLanguage.direction)
    }
}

extension View {
    /// Applies the current app language direction reactively.
    /// Use this at the root of every screen and sheet.
    func appDirection() -> some View {
        modifier(AppDirectionModifier())
    }
}
