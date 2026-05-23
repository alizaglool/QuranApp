//
//  Shape+CustomFill.swift
//
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//

import SwiftUI

public extension Shape {
    
    func customFill(_ color: ColorStyle) -> some View {
        self
            .fill(color.color)
    }
    
    func customFill(_ fill: ColorStyle, _ stroke: ColorStyle, lineWidth: CGFloat = 1) -> some View {
        
        self
            .customStroke(stroke, lineWidth: lineWidth)
            .background(self.customFill(fill))
    }
}
