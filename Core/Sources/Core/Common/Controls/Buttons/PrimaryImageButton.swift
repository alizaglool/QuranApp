//
//  PrimaryImageButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct PrimaryImageButton: View {
    
    var image: Image
    
    var action: EmptyAction
    
    var cornerRadius: CGFloat
    
    public init(image: Image,
                action: EmptyAction = nil,
                cornerRadius: CGFloat = 5) {
        self.image = image
        self.action = action
        self.cornerRadius = cornerRadius
    }
    
    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .customForeground(.onPrimary)
                .padding(.all, 8)
        })
        .customBackground(.primary)
        .customCornerRadius(cornerRadius)
    }
}

#Preview {
//    PrimaryImageButton(image: .search)
}
