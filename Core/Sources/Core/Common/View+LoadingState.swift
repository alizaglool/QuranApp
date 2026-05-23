//
//  View+LoadingState.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

struct LoadingViewModifier: ViewModifier {
    
    var loadingState: LoadingState
    
    var failureViewClickAction: EmptyAction
    
    func body(content: Content) -> some View {
        ZStack {
            
            content
            
            if loadingState.isLoading {
                LoadingView()
            }
            else if loadingState == .failed {
                FailureView()
                    .onTapGesture {
                        failureViewClickAction?()
                    }
            }
        }
    }
}

public extension View {
    
    func withLoadingState(loadingState: LoadingState = .loaded, failureViewClickAction: EmptyAction = nil) -> some View {
        ModifiedContent(content: self, modifier: LoadingViewModifier(loadingState: loadingState, failureViewClickAction: failureViewClickAction))
    }
}


