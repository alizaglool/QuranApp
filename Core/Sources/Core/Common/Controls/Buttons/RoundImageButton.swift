//
//  RoundImageButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct RoundImageButton: View {
    
    var image: Image
    
    var action: EmptyAction
    
    var iconSize: CGSize
    var buttonSize: CGSize
    var tapAreaSize: CGSize
    
    public init(image: Image,
                action: EmptyAction = nil,
                iconSize: CGSize = CGSize(width: 10, height: 10),
                buttonSize: CGSize = CGSize(width: 24, height: 24),
                tapAreaSize: CGSize = CGSize(width: 24, height: 24)) {
        self.image = image
        self.action = action
        self.iconSize = iconSize
        self.buttonSize = buttonSize
        self.tapAreaSize = tapAreaSize
    }
    
    public var body: some View {
        Button(action: {
            action?()
        }, label: {
            
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize.width,
                       height: iconSize.height)
                .customForeground(.onSurface)
                .frame(width: buttonSize.width,
                       height: buttonSize.height)
                .background {
                    Circle()
                        .customFill(.neutral)
                }
                .frame(width: tapAreaSize.width,
                       height: tapAreaSize.height)
        })
    }
}

#Preview {
    RoundImageButton(image: .search)
}
