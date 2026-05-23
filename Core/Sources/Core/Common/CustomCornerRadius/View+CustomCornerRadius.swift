//
//  View+CustomCornerRadius.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

struct CornerRadiusStyleModifier: ViewModifier {
    
    var radius: CGFloat
    var corners: UIRectCorner
    
    func body(content: Content) -> some View {
        
        content
            .clipShape(CornerRadiusShape(radius: radius, corners: corners))
    }
}

public extension View {
    
    func customCornerRadii(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyleModifier(radius: radius, corners: corners))
    }
    
    func customCornerRadius(_ radius: CGFloat) -> some View {
        ModifiedContent(content: self, modifier: CornerRadiusStyleModifier(radius: radius, corners: .allCorners))
    }
}
