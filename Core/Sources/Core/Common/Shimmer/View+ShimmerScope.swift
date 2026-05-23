//
//  View+ShimmerScope.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

//import SwiftUI
//import ShimmerView

import SwiftUI
import ShimmerView

struct ShimmerScopeViewModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        ShimmerScope(style: .custom, isAnimating: .constant(true)) {
            content
        }
    }
}

public extension View {
    func inShimmerScope() -> some View {
        ModifiedContent(content: self, modifier: ShimmerScopeViewModifier())
    }
}
