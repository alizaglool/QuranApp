//
//  DisabledButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct DisabledButton: View {
    
    var title: String
    
    var action: EmptyAction
    
    var leadingIcon: Image?
    
    var trailingIcon: Image?
    
    var height: CGFloat
    
    var cornerRadius: CGFloat
    
    var iconDimension: CGFloat
    
    var textColor: ColorStyle
    
    var backgroundColor: ColorStyle
    
    public init(title: String,
                action: EmptyAction,
                leadingIcon: Image? = nil,
                trailingIcon: Image? = nil,
                height: CGFloat = CoreConfig.Design.buttonHeight,
                cornerRadius: CGFloat = CoreConfig.Design.buttonRadius,
                iconDimension: CGFloat = CoreConfig.Design.buttonIconDimension,
                textColor: ColorStyle = .onSecondary,
                backgroundColor: ColorStyle = .neutral) {
        self.title = title
        self.action = action
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
        self.height = height
        self.cornerRadius = cornerRadius
        self.iconDimension = iconDimension
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        button
    }
    
    private var button: some View {
        Button(action: {
            action?()
        }, label: {
            
            HStack(spacing: 16) {
                
                if leadingIcon != nil {
                    
                    leadingIconView
                }
                
                titleView
                
                if trailingIcon != nil {
                    
                    trailingIconView
                }
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
        })
        .customBackground(backgroundColor)
        .customCornerRadius(cornerRadius)
    }
    
    private var titleView: some View {
        Text(title)
            .customStyle(.buttonText, textColor)
    }
    
    private var leadingIconView: some View {
        leadingIcon!
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconDimension, height: iconDimension)
            .customForeground(textColor)
    }
    
    private var trailingIconView: some View {
        trailingIcon!
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: iconDimension, height: iconDimension)
            .customForeground(textColor)
    }
}

#Preview {
    VStack {
        DisabledButton(title: "Title 1", action: nil)
        
        DisabledButton(title: "Title 2", action: nil)
        
        DisabledButton(title: "Title 3", action: nil)
        
        DisabledButton(title: "Title 4", action: nil)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .customBackground(.surface)
}
