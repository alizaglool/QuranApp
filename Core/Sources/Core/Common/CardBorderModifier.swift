//
//  CardBorderModifier.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


import SwiftUI

struct CardBorderModifier: ViewModifier {
    
    var backgroundColor: ColorStyle
    
    var cornerRadius: CGFloat
    
    var bordered: Bool
    
    var borderColor: ColorStyle
    
    var borderWidth: CGFloat
    
    func body(content: Content) -> some View {
        
        CardContainer(backgroundColor: backgroundColor,
                      cornerRadius: cornerRadius,
                      bordered: bordered,
                      borderColor: borderColor,
                      borderWidth: borderWidth,
                      shadowed: false) {
            
            content
        }
    }
}

public extension View {
    
    func withCardBorder(backgroundColor: ColorStyle = .container,
                        cornerRadius: CGFloat = 12,
                        bordered: Bool = true,
                        borderColor: ColorStyle = .primary,
                        borderWidth: CGFloat = 1) -> some View {
        ModifiedContent(content: self, modifier: CardBorderModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius, bordered: bordered, borderColor: borderColor, borderWidth: borderWidth))
    }
}
