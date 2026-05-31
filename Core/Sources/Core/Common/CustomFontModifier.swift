//
//  CustomFontModifier.swift
//  Core
//
//  Created by Ali M. Zaghloul on 03/06/2025.
//


import SwiftUI

struct CustomFontModifier: ViewModifier {
    
    let size: CGFloat
    let weight: CustomFontWeight
    let lineHeight: CGFloat
    let font: UIFont
    
    init(fontStyle: FontStyle) {
        size = fontStyle.customFont.size
        weight = fontStyle.customFont.weight
        lineHeight = fontStyle.customFont.lineHeight
        self.font = .systemFont(ofSize: size, weight: weight.weight)
    }

    init(supportedFont: SupportedFonts,
         size: CGFloat,
         weight: CustomFontWeight,
         lineHeight: CGFloat) {
        self.size = size
        self.weight = weight
        self.lineHeight = lineHeight
        self.font = .systemFont(ofSize: size, weight: weight.weight)
    }
    
    func body(content: Content) -> some View {
        content
            .font(Font(font))
            .lineSpacing(lineHeight - font.lineHeight)
            .padding(.vertical, (lineHeight - font.lineHeight) / 2)
    }
}

