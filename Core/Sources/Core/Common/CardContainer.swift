//
//  CardContainer.swift
//  Core
//
//  Created by Ali M. Zaghloul on 05/05/2025.
//


import SwiftUI

public struct CardContainer<Content: View>: View {
    
    var backgroundColor: ColorStyle
    
    var cornerRadius: CGFloat
    
    var bordered: Bool
    
    var borderColor: ColorStyle
    
    var borderWidth: CGFloat
    
    var shadowed: Bool
    
    @ViewBuilder var content: () -> Content
    
    public init(backgroundColor: ColorStyle = .background,
                cornerRadius: CGFloat = 12,
                bordered: Bool = true,
                borderColor: ColorStyle = .success,
                borderWidth: CGFloat = 1,
                shadowed: Bool = false,
                @ViewBuilder content: @escaping () -> Content) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.bordered = bordered
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowed = shadowed
        self.content = content
    }
    
    public var body: some View {
        content()
            .background(backgroundRectangle)
            .customCornerRadius(cornerRadius)
            .overlay {
                if bordered {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .customStroke(borderColor, lineWidth: borderWidth)
                }
            }
    }
    
    @ViewBuilder
    var backgroundRectangle: some View {
        
        if shadowed {
            
            Rectangle()
                .customForeground(backgroundColor)
                .customCornerRadius(cornerRadius)
                .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        else {
            Rectangle()
                .customFill(backgroundColor)
        }
    }
}

#Preview {
    CardContainer {
        
    }
}
