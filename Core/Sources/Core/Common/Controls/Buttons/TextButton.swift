//
//  TextButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct TextButton: View {
    
    var title: String
    
    var action: EmptyAction
    
    var leadingIcon: Image?
    
    var trailingIcon: Image?
    
    var height: CGFloat
    
    var cornerRadius: CGFloat
    
    var iconDimension: CGFloat
    
    var textColor: ColorStyle
    
    public init(title: String,
                action: EmptyAction,
                leadingIcon: Image? = nil,
                trailingIcon: Image? = nil,
                height: CGFloat = CoreConfig.Design.buttonHeight,
                cornerRadius: CGFloat = CoreConfig.Design.buttonRadius,
                iconDimension: CGFloat = CoreConfig.Design.buttonIconDimension,
                textColor: ColorStyle = .primary) {
        self.title = title
        self.action = action
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.height = height
        self.cornerRadius = cornerRadius
        self.iconDimension = iconDimension
        self.textColor = textColor
    }
    
    public var body: some View {
        CustomButton(title: title,
                     action: action,
                     leadingIcon: leadingIcon,
                     trailingIcon: trailingIcon,
                     height: height,
                     cornerRadius: cornerRadius,
                     iconDimension: iconDimension,
                     textColor: textColor,
                     backgroundColor: .clear,
                     withBorder: false)
    }
}

#Preview {
    VStack {
        TextButton(title: "Title 1", action: nil)
        
        TextButton(title: "Title 2", action: nil)
        
        TextButton(title: "Title 3", action: nil)
        
        TextButton(title: "Title 4", action: nil)
            .disabled(true)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .customBackground(.surface)
}
