//
//  LoadingView.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

struct LoadingView: View {
    
    var body: some View {
        ZStack {
            
            Color.gray.opacity(0.3)
                .ignoresSafeArea()
            
            ProgressView()
                .scaleEffect(2)
        }
    }
}

#Preview {
    LoadingView()
}

