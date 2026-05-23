//
//  Shape+CustomStroke.swift
//
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//

import SwiftUI

public extension Shape {
    
    func customStroke(_ color: ColorStyle, lineWidth: CGFloat = 1) -> some View {
        self
            .stroke(color.color, lineWidth: lineWidth)
    }
    
    func customStroke(_ color: ColorStyle, style: StrokeStyle) -> some View {
        self
            .stroke(color.color, style: style)
    }
}
