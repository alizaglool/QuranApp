//
//  View+CustomColor.swift
//
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//

import SwiftUI

enum ColorPlace {
    case foreground
    case background
}

struct CustomColorModifier: ViewModifier {
    
    var colorStyle: ColorStyle
    var place: ColorPlace
    
    func body(content: Content) -> some View {
        
        switch place {
        case .foreground:
            
            content
                .foregroundStyle(colorStyle.color)
            
        case .background:
            
            content
                .background(colorStyle.color)
        }
    }
}

public extension View {
    
    func customForeground(_ color: ColorStyle) -> some View {
        ModifiedContent(content: self, modifier: CustomColorModifier(colorStyle: color, place: .foreground))
    }
    
    func customBackground(_ color: ColorStyle) -> some View {
        ModifiedContent(content: self, modifier: CustomColorModifier(colorStyle: color, place: .background))
    }
}

