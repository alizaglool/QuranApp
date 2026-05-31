//
//  View+CustomStyle.swift
//
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//

import SwiftUI

struct CustomStyleModifier: ViewModifier {
    
    var fontStyle: FontStyle
    var colorStyle: ColorStyle
    
    func body(content: Content) -> some View {
        content
            .modifier(CustomFontModifier(fontStyle: fontStyle))
            .customForeground(colorStyle)
    }
}

public extension View {
    
    func customStyle(_ font: FontStyle, _ color: ColorStyle) -> some View {
        ModifiedContent(content: self, modifier: CustomStyleModifier(fontStyle: font, colorStyle: color))
    }
}
