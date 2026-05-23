//
//  View+Disabled.swift
//
//
//  Created by Ali M. Zaghloul on 7/9/24.
//

import SwiftUI

public extension View {
    
    func disabled(_ loadingState: LoadingState) -> some View {
        disabled(loadingState.isLoading)
    }
}
