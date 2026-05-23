//
//  View+ShimmerOverlay.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI
import ShimmerView

struct ShimmerOverlayViewModifier: ViewModifier {
    
    @Environment(\.redactionReasons) var redactionReasons
    
    var synced: Bool
    
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        
        content
            .overlay {
                if redactionReasons.contains(.placeholder) {
                    
                    if synced {
                        shimmer
                    }
                    else {
                        shimmer
                            .inShimmerScope()
                    }
                }
            }
    }
    
    private var shimmer: some View {
        ShimmerElement()
            .customCornerRadius(cornerRadius)
    }
}

public extension View {
    
    func withShimmerOverlay(synced: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        ModifiedContent(content: self, modifier: ShimmerOverlayViewModifier(synced: synced, cornerRadius: cornerRadius))
    }
}
