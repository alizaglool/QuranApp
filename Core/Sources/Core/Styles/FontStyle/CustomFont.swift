//
//  CustomFont.swift
//  
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import UIKit

struct CustomFont {
    
    var supportedFont: SupportedFonts = .notoSerif
    
    var weight: CustomFontWeight
    
    var size: CGFloat
    
    var lineHeight: CGFloat
    
    var fontFullName: String {
        "\(supportedFont.rawValue)-\(weight.weightName)"
    }
    
    var font: UIFont? {
        UIFont.custom(font: supportedFont, weight, size)
    }
}

extension CustomFont {
    
    // Display — Noto Serif (grand, immersive)
    static let largeTitle = CustomFont(supportedFont: .notoSerif, weight: ._700, size: 36, lineHeight: 41)
    static let heading1 = CustomFont(supportedFont: .notoSerif, weight: ._700, size: 28, lineHeight: 34)
    static let heading2 = CustomFont(supportedFont: .notoSerif, weight: ._600, size: 22, lineHeight: 28)
    static let heading3 = CustomFont(supportedFont: .notoSerif, weight: ._600, size: 20, lineHeight: 24)
    
    // UI — Manrope (clean, functional)
    static let headline = CustomFont(weight: ._700, size: 17, lineHeight: 22)
    static let buttonText = CustomFont(weight: ._600, size: 16, lineHeight: 22)
    static let subheadline = CustomFont(weight: ._600, size: 14, lineHeight: 20)
    static let bodyMedium = CustomFont(weight: ._500, size: 16, lineHeight: 21)
    static let bodySmall = CustomFont(weight: ._500, size: 14, lineHeight: 18)
    static let caption1 = CustomFont(weight: ._500, size: 12, lineHeight: 16)
    static let caption2 = CustomFont(weight: ._400, size: 11, lineHeight: 13)
}
