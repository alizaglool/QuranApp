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
    /// Search-result match highlight. Light is byte-identical to `error` (#DC2626);
    /// dark lifts to #FF6B6B because #DC2626 over a translucent panel on the dark
    /// mushaf page measures 2.3:1 and fails AA. `Error` itself must keep its single
    /// value — error toasts and validation states app-wide depend on it.
    static let searchMatch = Color(.searchMatch)
    
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
    /// Muted ink for the mushaf + tafsir header bar labels. Pre-composed at 65%
    /// so the call site never applies `.opacity()`.
    static let mushafBarLabel = Color(.mushafBarLabel)
    static let verseMarkerGold = Color(.verseMarkerGold)
    static let verseMarkerCream = Color(.verseMarkerCream)
    static let verseMarkerDigits = Color(.verseMarkerDigits)

    static let playerControls = Color(.playerControls)
}

// Settings Pickers
public extension Color {
    /// Outer container background for scroll / theme / appearance picker segments
    static let pickerContainer = Color(.pickerContainer)
    /// Selected-item fill inside a picker segment
    static let pickerSelection = Color(.pickerSelection)
    /// Label color for the currently selected picker item
    static let pickerSelectedLabel = Color(.pickerSelectedLabel)
    /// Label color for unselected picker items
    static let pickerUnselectedLabel = Color(.pickerUnselectedLabel)
}

// Hadith Reading
public extension Color {

    static let hadithBg         = Color(.hadithBg)
    static let hadithCard       = Color(.hadithCard)
    static let hadithNav        = Color(.hadithNav)
    static let hadithPrimary    = Color(.hadithPrimary)
    static let hadithSecondary  = Color(.hadithSecondary)
    static let hadithMuted      = Color(.hadithMuted)
    static let hadithSeparator  = Color(.hadithSeparator)
    static let hadithArabicText = Color(.hadithArabicText)

    // Authenticity-grade badges. The same hue in both appearances by decision —
    // the colorsets still declare light and dark so a change stays in the catalog.
    static let hadithGold       = Color(.hadithGold)
    static let hadithGreen      = Color(.hadithGreen)
    static let hadithRed        = Color(.hadithRed)
    static let hadithOrange     = Color(.hadithOrange)
}

// Adhkar Reading
public extension Color {

    /// Same role and value as `surfaceRaised` — one colorset, named for both
    /// the module that introduced it and the shared token it became.
    static let adhkarSurface            = surfaceRaised
    static let adhkarSurfaceTranslucent = Color(.adhkarSurfaceTranslucent)
    static let adhkarHairline           = Color(.adhkarHairline)
    static let adhkarRingTrack          = Color(.adhkarRingTrack)
    static let adhkarShadow             = Color(.adhkarShadow)
    static let adhkarWatermark          = Color(.adhkarWatermark)
}

// Shared Tokens
//
// One declaration per role, light + dark resolved by the asset catalog.
// Views reference these directly — never `colorScheme == .dark ? x : y`.
public extension Color {

    /// Standard card fill. Replaces `dark ? surfaceContainerLow : surfaceContainerLowest`.
    static let cardSurface         = Color(.cardSurface)
    /// Hairline around a card. Replaces `outlineVariant.opacity(dark ? 0.2 : 0.1)`.
    static let cardBorder          = Color(.cardBorder)
    /// Tinted wash behind a leading icon, brand green.
    static let washPrimary         = Color(.washPrimary)
    /// Tinted wash behind a leading icon, brand gold.
    static let washSecondary       = Color(.washSecondary)
    /// Gold wash for a quick card, alpha-matched to `washPrimary` so the two
    /// tints of the same card read at equal strength.
    static let washSecondaryCard   = Color(.washSecondaryCard)
    /// Lighter gold wash for a full-width banner surface.
    static let washSecondarySubtle = Color(.washSecondarySubtle)
    /// Card fill that sits above `cardSurface` in the stack.
    static let surfaceRaised       = Color(.surfaceRaised)
    /// Solid brand fill marking the active item in a list.
    static let brandActive         = Color(.brandActive)
    static let resumeSurface       = Color(.resumeSurface)
    static let resumeLabel         = Color(.resumeLabel)

    /// Brand avatar circle. Same in both appearances — a saturated fill that
    /// carries white text either way.
    static let avatarGradientStart  = Color(.avatarGradientStart)
    static let avatarGradientEnd    = Color(.avatarGradientEnd)
}

// Hadith Library
public extension Color {

    static let hadithCardWash  = Color(.hadithCardWash)
    static let hadithBookIcon  = Color(.hadithBookIcon)
    static let hadithBookTitle = Color(.hadithBookTitle)
    static let hadithBookMeta  = Color(.hadithBookMeta)
    static let downloadStroke  = Color(.downloadStroke)
    static let downloadSurface = Color(.downloadSurface)
    static let downloadIcon    = Color(.downloadIcon)

    /// Download-button chrome on a surface that is dark in *both* appearances
    /// (the featured brand-gradient card), so it cannot follow the colour scheme.
    static let downloadStrokeOnDark  = Color(.downloadStrokeOnDark)
    static let downloadSurfaceOnDark = Color(.downloadSurfaceOnDark)
    static let downloadIconOnDark    = Color(.downloadIconOnDark)
}

// MARK: - Mushaf Ornaments

public extension Color {

    /// Ink on the ornamental page-number badge artwork.
    static let pageBadgeLabel     = Color(.pageBadgeLabel)
    /// Ink on the ornamental chapter-header banner artwork.
    static let chapterHeaderLabel = Color(.chapterHeaderLabel)
    /// Stroke of the scroll-direction preview tile in the page settings sheet.
    static let mushafPreviewStroke = Color(.mushafPreviewStroke)
}

// MARK: - Shorts Player

public extension Color {

    /// Chrome on the shorts player, which is `Color.black` in both appearances
    /// and so cannot follow the colour scheme.
    static let shortsChipSurface = Color(.shortsChipSurface)
    static let shortsPillSurface = Color(.shortsPillSurface)
    static let shortsAccent      = Color(.shortsAccent)
}
