//
//  FailureView.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

struct FailureView: View {
    
    var body: some View {
        ZStack {
            
            Color.black
                .ignoresSafeArea()
            
            dialog
        }
        .overlay(alignment: .topLeading) {
            
//            BackButton()
//                .padding(.leading, 16)
        }
        .navigationBarHidden(true)
    }
    
    private var dialog: some View {
        VStack(spacing: 32) {
            
//            Image.failure
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: 230, height: 230)
            
            Text("Whoops!")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 32)
    }
}

#Preview {
    FailureView()
}
