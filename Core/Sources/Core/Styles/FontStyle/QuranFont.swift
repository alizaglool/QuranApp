//
//  QuranFont.swift
//  Core
//

import SwiftUI

/// All Quran-specific fonts available in the app.
/// PostScript names match the font binaries bundled in Core/Resources/Fonts.
public enum QuranFont: String, CaseIterable {

    // Main Quran page text (Hafs script)
    case hafs             = "KFGQPCHafsSmart-Regular"
    case hafsFixed        = "HafsSmart_08_fixed"

    // Uthmanic Naskh script (two weights)
    case uthmanicNaskh    = "KFGQPCUthmanTahaNaskh"
    case uthmanicNaskhBold = "KFGQPCUthmanTahaNaskh-Bold"

    // Uthmanic Hafs script
    case uthmanicHafs     = "KFGQPCHAFSUthmanicScript-Regula"

    // Ornamental: verse numbers and surah title banners
    case numbers          = "QuranNumbers"
    case titles           = "QuranTitles"

    /// File name (without extension) used for registration from the Core bundle.
    var fileName: String {
        switch self {
        case .hafs:              return "HafsSmart_08"
        case .hafsFixed:         return "HafsSmart_08_fixed"
        case .uthmanicNaskh:     return "UthmanTN1 Ver20"
        case .uthmanicNaskhBold: return "UthmanTN1B Ver20"
        case .uthmanicHafs:      return "UthmanicHafs1 Ver17"
        case .numbers:           return "QuranNumbers"
        case .titles:            return "QuranTitles"
        }
    }

    /// Convenience SwiftUI Font at a given size.
    public func font(size: CGFloat) -> Font {
        .custom(postScriptName, size: size)
    }

    /// The actual PostScript name embedded in the font binary.
    /// Needed because HafsSmart_08_fixed.ttf shares the same PS name as HafsSmart_08.ttf.
    private var postScriptName: String {
        switch self {
        case .hafsFixed: return "KFGQPCHafsSmart-Regular"
        default:         return rawValue
        }
    }
}
