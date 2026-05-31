//
//  FontsManager.swift
//  Core
//

import Foundation
import CoreGraphics
import CoreText

public struct FontsManager {

    // UI fonts stored in Core/Resources/Fonts
    private static let uiFontFileNames: [String] = [
        "NotoSerif-Regular", "NotoSerif-Medium", "NotoSerif-SemiBold", "NotoSerif-Bold",
        "Manrope-Regular",   "Manrope-Medium",   "Manrope-SemiBold",   "Manrope-Bold",
        "ElMessiri-Regular", "ElMessiri-Medium", "ElMessiri-SemiBold", "ElMessiri-Bold",
        "Kitab-Regular",     "Kitab-Bold"
    ]

    // Quran fonts stored in Core/Resources/Fonts
    // UthmanTN1 Ver20, UthmanTN1B Ver20, UthmanicHafs1 Ver17 must be placed
    // in Core/Sources/Core/Resources/Fonts/ before they register successfully.
    private static let quranFontFileNames: [String] = [
        "HafsSmart_08",
        "HafsSmart_08_fixed",
        "QuranNumbers",
        "QuranTitles",
        "UthmanTN1 Ver20",
        "UthmanTN1B Ver20",
        "UthmanicHafs1 Ver17"
    ]

    /// Call once from AppDelegate.didFinishLaunchingWithOptions.
    public static func registerFonts() {
        (uiFontFileNames + quranFontFileNames).forEach {
            register(bundle: .module, fileName: $0)
        }
    }

    private static func register(bundle: Bundle, fileName: String) {
        guard let url = bundle.url(forResource: fileName, withExtension: "ttf") else {
            // File not yet in bundle — skip silently (no crash).
            return
        }
        guard
            let provider = CGDataProvider(url: url as CFURL),
            let cgFont  = CGFont(provider)
        else { return }

        var error: Unmanaged<CFError>?
        CTFontManagerRegisterGraphicsFont(cgFont, &error)
        // Ignore CFError — duplicate registration is harmless.
    }
}
