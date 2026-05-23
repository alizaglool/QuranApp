//
//  RedactedViewModifier.swift
//  Core
//
//  Created by Ali M. Zaghloul on 12/06/2025.
//


import SwiftUI

struct RedactedViewModifier: ViewModifier {
    
    var isRedacted: Bool
    var withDisabled: Bool
    
    func body(content: Content) -> some View {
        
        if withDisabled {
            
            content
                .redacted(reason: isRedacted ? .placeholder : [])
                .disabled(isRedacted)
        }
        else {
            content
                .redacted(reason: isRedacted ? .placeholder : [])
        }
    }
}

public extension View {
    
    func redacted(_ isRedacted: Bool, withDisabled: Bool = true) -> some View {
        ModifiedContent(content: self, modifier: RedactedViewModifier(isRedacted: isRedacted, withDisabled: withDisabled))
    }
    
    func redacted(_ loadingState: LoadingState, withDisabled: Bool = true) -> some View {
        ModifiedContent(content: self, modifier: RedactedViewModifier(isRedacted: loadingState.isLoading, withDisabled: withDisabled))
    }
}
