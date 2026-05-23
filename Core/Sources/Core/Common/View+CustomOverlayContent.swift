//
//  View+CustomOverlayContent.swift
//  Core
//
//  Created by Ali M. Zaghloul on 18/06/2025.
//

import SwiftUI

struct OverlayContentViewModifier<OverlayContent: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    var dismissable: Bool
    var overlayContent: () -> OverlayContent
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    
                    ZStack {
                        
                        Color.blackOverlay68
                            .ignoresSafeArea()
                            .onTapGesture {
                                if dismissable {
                                    withOptionalAnimation {
                                        isPresented = false
                                    }
                                }
                            }
                        
                        overlayContent()
                    }
                }
            }
    }
}

public extension View {
    
    func withCustomOverlayContent<OverlayContent: View>(isPresented: Binding<Bool>, dismissable: Bool = true, overlayContent: @escaping () -> OverlayContent) -> some View {
        ModifiedContent(content: self, modifier: OverlayContentViewModifier(isPresented: isPresented, dismissable: dismissable, overlayContent: overlayContent))
    }
}
