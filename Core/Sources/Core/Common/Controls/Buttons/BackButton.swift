//
//  BackButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct BackButton: View {
    
    @Environment(\.dismiss) var dismiss
    
    var action: EmptyAction
    var foregroundColor: ColorStyle
    
    public init(action: EmptyAction = nil, foregroundColor: ColorStyle = .white) {
        self.action = action
        self.foregroundColor = foregroundColor
    }
    
    public var body: some View {
        Button(action: {
            if let action {
                action()
            } else {
                dismiss()
            }
        }, label: {
            Image.backArrow
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .customForeground(foregroundColor)
        })
    }
}

#Preview {
    BackButton()
}
