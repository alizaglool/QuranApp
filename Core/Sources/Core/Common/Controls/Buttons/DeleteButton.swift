//
//  DeleteButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct DeleteButton: View {
    
    var title: String
    
    var action: EmptyAction
    
    var leadingIcon: Image?
    
    var trailingIcon: Image?
    
    var height: CGFloat
    
    var cornerRadius: CGFloat
    
    var iconDimension: CGFloat
    
    var textColor: ColorStyle
    
    var borderColor: ColorStyle
    
    var borderWidth: CGFloat
    
    public init(title: String,
                action: EmptyAction,
                leadingIcon: Image? = nil,
                trailingIcon: Image? = nil,
                height: CGFloat = CoreConfig.Design.buttonHeight,
                cornerRadius: CGFloat = CoreConfig.Design.buttonRadius,
                iconDimension: CGFloat = CoreConfig.Design.buttonIconDimension,
                textColor: ColorStyle = .error,
                borderColor: ColorStyle = .error,
                borderWidth: CGFloat = 1.4) {
        self.title = title
        self.action = action
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.height = height
        self.cornerRadius = cornerRadius
        self.iconDimension = iconDimension
        self.textColor = textColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
    }
    
    public var body: some View {
        CustomButton(role: .destructive,
                     title: title,
                     action: action,
                     leadingIcon: leadingIcon,
                     trailingIcon: trailingIcon,
                     height: height,
                     cornerRadius: cornerRadius,
                     iconDimension: iconDimension,
                     textColor: textColor,
                     backgroundColor: .clear,
                     withBorder: true,
                     borderColor: borderColor,
                     borderWidth: borderWidth)
    }
}

#Preview {
    VStack {
        
        DeleteButton(title: "Title 1", action: nil)
        
        DeleteButton(title: "Title 2", action: nil)
        
        DeleteButton(title: "Title 3", action: nil)
        
        DeleteButton(title: "Title 4", action: nil)
            .disabled(true)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .customBackground(.surface)
}
