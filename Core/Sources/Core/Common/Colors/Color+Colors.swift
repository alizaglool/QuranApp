//
//  UIColor+Colors.swift
//  
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public extension Color {
    
    static let primaryColor = Color(.primary)
    static let primaryDark = Color(.primaryDark)
    static let primaryLight = Color(.primaryLight)
    static let primaryWhite = Color(.primaryWhite)
    static let primaryContainer = Color(.primaryContainer)
    static let onPrimaryContainer = Color(.onPrimaryContainer)

    static let secondaryColor = Color(.secondary)
    static let secondary80 = Color(.secondary80)
    static let secondary60 = Color(.secondary60)
    static let secondary50 = Color(.secondary50)
    static let secondary40 = Color(.secondary40)
    static let secondaryDark = Color(.secondaryDark)
    static let secondaryLight = Color(.secondaryLight)
    
    static let tertiary = Color(.tertiary)
    
    static let onSurface = Color(.onSurface)
    static let onSurfaceVariant = Color(.onSurfaceVariant)
    static let subtitleText = Color(.subtitleText)
    static let onSecondary = Color(.onSecondary)
    static let onPrimary = Color(.onPrimary)
}


// Core
public extension Color {
    
    static let blackOverlay40 = Color(.blackOverlay40)
    static let blackOverlay68 = Color(.blackOverlay68)
    static let containerBlack40 = Color(.containerBlack40)
    
    static let neutral = Color(.neutral)
    
    static let surface = Color(.surface)
    static let surfaceContainerLow = Color(.surfaceContainerLow)
    static let surfaceContainerHigh = Color(.surfaceContainerHigh)
    static let surfaceContainerLowest = Color(.surfaceContainerLowest)
    
    static let outline = Color(.outline)
    static let outlineVariant = Color(.outlineVariant)
    
    static let warning = Color(.warning)
    
    static let error = Color(.error)
    static let error50 = Color(.error50)
    
    static let success = Color(.success100)
    static let success50 = Color(.success50)
    static let background = Color(.background)
    static let surfaceContainer = Color(.surfaceContainer)
}

// Quran
public extension Color {

    static let mushafPage = Color(.mushafPage)
    static let quranText = Color(.quranText)
    static let verseNumber = Color(.verseNumber)
    static let surahDivider = Color(.surahDivider)
    static let verseMarkerGold = Color(.verseMarkerGold)
    static let verseMarkerCream = Color(.verseMarkerCream)
    static let verseMarkerDigits = Color(.verseMarkerDigits)

    static let playerControls = Color(.playerControls)
}

// Settings Pickers
public extension Color {
    /// Outer container background for scroll / theme / appearance picker segments
    static let pickerContainer = Color(lightHex: "FCFBF9", darkHex: "28282A")
    /// Selected-item fill inside a picker segment
    static let pickerSelection = Color(lightHex: "DFD1C2", darkHex: "3A3A3C")
    /// Label color for the currently selected picker item
    static let pickerSelectedLabel = Color(lightHex: "1E6B47", darkHex: "13BC7C")
    /// Label color for unselected picker items
    static let pickerUnselectedLabel = Color(lightHex: "000000", darkHex: "FFFFFF")
}

// Hadith Reading
public extension Color {

    static let hadithBg         = Color(lightHex: "F6F2E8", darkHex: "133C26")
    static let hadithCard       = Color(lightHex: "FFFFFF", darkHex: "0B2D1A")
    static let hadithNav        = Color(lightHex: "133C26", darkHex: "FFFFFF")
    static let hadithPrimary    = Color(lightHex: "1C1C1C", darkHex: "FFFFFF")
    static var hadithSecondary: Color { hadithPrimary.opacity(0.65) }
    static var hadithMuted: Color     { hadithPrimary.opacity(0.38) }
    static let hadithSeparator  = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.14)
            : UIColor.black.withAlphaComponent(0.08)
    })
    static let hadithArabicText = Color(lightHex: "133C26", darkHex: "CCAB4C")
    static let hadithGold       = Color(hex: "CCAB4C")
    static let hadithGreen      = Color(hex: "29AD61")
    static let hadithRed        = Color(hex: "E84D3D")
    static let hadithOrange     = Color(hex: "E67D21")
}
