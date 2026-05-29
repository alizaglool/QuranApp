//
//  Color+App.swift
//  QuranApp
//

import SwiftUI

extension Color {
    // The app's primary green (#78C262) — from "Primary Color" in Colors.xcassets.
    // Use this instead of ColorStyle.primary.color in app-layer views; the Core module's
    // .primary asset resolves to a dark forest green (#012D1D) which is a different token.
    static let quranGreen = Color("Primary Color")
}
