//
//  ColorStyle.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public enum ColorStyle {
    
    // Primary
    case primary
    case primaryDark
    case primaryLight
    case primaryWhite
    case primaryOpacity(opacity: Double)
    case primaryContainer
    case onPrimaryContainer
    
    // Secondary
    case secondary
    case secondary80
    case secondary60
    case secondary50
    case secondary40
    case secondaryDark
    case secondaryLight
    
    // Tertiary
    case tertiary
    
    // Core
    case onSurface
    case onSurfaceVariant
    case container
    case background
    case surface
    case surfaceContainerLow
    case surfaceContainerHigh
    case surfaceContainerLowest
    case success
    case success50
    case warning
    case error
    case error50
    case neutral
    case clear
    case white
    case subtitle
    case onSecondary
    case onPrimary
    case outline
    case outlineVariant
    case surfaceContainer

    // Overlays
    case black
    case blackOverlay68
    case containerBlack40
    
    // Quran
    case mushafPage
    case quranText
    case verseNumber
    case surahDivider

    // Hadith
    case hadithBg
    case hadithCard
    case hadithNav
    case hadithPrimary
    case hadithSecondary
    case hadithMuted
    case hadithSeparator
    case hadithArabicText
    case hadithGold
    case hadithGreen
    case hadithRed
    case hadithOrange
    
    public var color: Color {
        switch self {
        // Primary
        case .primary:
            return .primaryColor
        case .primaryDark:
            return .primaryDark
        case .primaryLight:
            return .primaryLight
        case .primaryWhite:
            return .primaryWhite
        case .primaryOpacity(let opacity):
            return .primaryColor.opacity(opacity)
        case .primaryContainer:
            return .primaryContainer
        case .onPrimaryContainer:
            return .onPrimaryContainer
            
        // Secondary
        case .secondary:
            return .secondaryColor
        case .secondary80:
            return .secondary80
        case .secondary60:
            return .secondary60
        case .secondary50:
            return .secondary50
        case .secondary40:
            return .secondary40
        case .secondaryDark:
            return .secondaryDark
        case .secondaryLight:
            return .secondaryLight
        case .surfaceContainer:
            return .surfaceContainer
            
        // Tertiary
        case .tertiary:
            return .tertiary
            
        // Core
        case .onSurface:
            return .onSurface
        case .onSurfaceVariant:
            return .onSurfaceVariant
        case .container:
            return .background
        case .background:
            return .background
        case .surface:
            return .surface
        case .surfaceContainerLow:
            return .surfaceContainerLow
        case .surfaceContainerHigh:
            return .surfaceContainerHigh
        case .surfaceContainerLowest:
            return .surfaceContainerLowest
        case .success:
            return .success
        case .success50:
            return .success50
        case .warning:
            return .warning
        case .error:
            return .error
        case .error50:
            return .error50
        case .neutral:
            return .neutral
        case .clear:
            return .clear
        case .white:
            return .white
        case .subtitle:
            return .subtitleText
        case .onSecondary:
            return .onSecondary
        case .onPrimary:
            return .onPrimary
        case .outline:
            return .outline
        case .outlineVariant:
            return .outlineVariant
            
        // Overlays
        case .black:
            return .black
        case .blackOverlay68:
            return .blackOverlay68
        case .containerBlack40:
            return .containerBlack40
            
        // Quran
        case .mushafPage:
            return .mushafPage
        case .quranText:
            return .quranText
        case .verseNumber:
            return .verseNumber
        case .surahDivider:
            return .surahDivider

        // Hadith
        case .hadithBg:         return .hadithBg
        case .hadithCard:       return .hadithCard
        case .hadithNav:        return .hadithNav
        case .hadithPrimary:    return .hadithPrimary
        case .hadithSecondary:  return .hadithSecondary
        case .hadithMuted:      return .hadithMuted
        case .hadithSeparator:  return .hadithSeparator
        case .hadithArabicText: return .hadithArabicText
        case .hadithGold:       return .hadithGold
        case .hadithGreen:      return .hadithGreen
        case .hadithRed:        return .hadithRed
        case .hadithOrange:     return .hadithOrange
        }
    }
    
    func withOpacity(_ opacity: Double) -> Color {
        return self.color.opacity(opacity)
    }
}
