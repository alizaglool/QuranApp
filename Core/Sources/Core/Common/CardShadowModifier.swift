//
//  CardShadowModifier.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


import SwiftUI

struct CardShadowModifier: ViewModifier {
    
    var backgroundColor: ColorStyle
    
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        
        CardContainer(backgroundColor: backgroundColor,
                      cornerRadius: cornerRadius,
                      bordered: false,
                      shadowed: true) {
            content
        }
    }
}

public extension View {
    
    func withCardShadow(backgroundColor: ColorStyle = .secondary50,
                        cornerRadius: CGFloat = 8) -> some View {
        ModifiedContent(content: self, modifier: CardShadowModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }
}
