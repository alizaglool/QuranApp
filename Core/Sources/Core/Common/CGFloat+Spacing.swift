//
//  CGFloat+Spacing.swift
//
//
//  Created by Ali M. Zaghloul on 7/10/24.
//

import Foundation

public extension CGFloat {
    
    static var no: CGFloat = 0
    
    static var xxSm: CGFloat = 4
    
    static var xSm: CGFloat = 8
    
    static var sm: CGFloat = 12
    
    static var md: CGFloat = 16
    
    static var big: CGFloat = 20
    
    static var xBig: CGFloat = 24
    
    static var xxBig: CGFloat = 28
    
    static var xxxBig: CGFloat = 32

    // MARK: - Corner Radius
    static var cornerXxSm: CGFloat = 6
    static var cornerXSm: CGFloat  = 8
    static var cornerSm: CGFloat   = 9
    static var cornerMd: CGFloat   = 12
    static var cornerLg: CGFloat   = 14
    static var cornerXl: CGFloat   = 16
    static var cornerCard: CGFloat = 18
    static var cornerXxl: CGFloat  = 20
}

// MARK: - Arabic Numerals

public extension Int {
    var arabicNumerals: String {
        let digits = ["٠","١","٢","٣","٤","٥","٦","٧","٨","٩"]
        return String(self).map { c in
            guard let d = c.wholeNumberValue else { return String(c) }
            return digits[d]
        }.joined()
    }
}
