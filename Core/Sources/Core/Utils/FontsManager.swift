//
//  FontsManager.swift
//
//
//  Created by Ali M. Zaghloul on 7/9/24.
//

import Foundation
import CoreGraphics
import CoreText

struct FontsManager {
    
    public static func registerFonts() {
        
        FontStyle.allCases.forEach {
            registerFont(bundle: .module, fontName: $0.customFont.fontFullName, fontExtension: "otf")
        }
    }
    
    fileprivate static func registerFont(bundle: Bundle,
                                         fontName: String,
                                         fontExtension: String) {
        
        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            fatalError("Couldn't create font from filename: \(fontName) with extension \(fontExtension)")
        }
        
        var error: Unmanaged<CFError>?
        
        CTFontManagerRegisterGraphicsFont(font, &error)
    }
}
