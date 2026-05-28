//
//  Color+Hex.swift
//
//  Created by Ali M. Zaghloul on 2026-05-28.
//

import SwiftUI
import UIKit

public extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   CGFloat((int >> 16) & 0xFF) / 255,
            green: CGFloat((int >> 8)  & 0xFF) / 255,
            blue:  CGFloat(int         & 0xFF) / 255,
            alpha: 1
        )
    }
}

public extension Color {
    init(hex: String) {
        self.init(UIColor(hex: hex))
    }

    init(lightHex: String, darkHex: String) {
        self.init(UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(hex: darkHex)
                : UIColor(hex: lightHex)
        })
    }
}
