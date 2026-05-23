//
//  UIFont+CustomFont.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import UIKit

extension UIFont {
    
    static func custom(font: SupportedFonts, _ weight: CustomFontWeight, _ size: CGFloat) -> UIFont? {
        return custom(font.rawValue, weight, size)
    }
    
    static func custom(_ fontName: String, _ weight: CustomFontWeight, _ size: CGFloat) -> UIFont? {
        return UIFont(name: "\(fontName)-\(weight.weightName)", size: size)
    }
}
