//
//  CustomButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/7/24.
//

import SwiftUI

public struct CustomButton: View {
    
    @Environment(\.isEnabled) private var isEnabled
    
    var role: ButtonRole?
    
    var title: String
    
    var action: EmptyAction
    
    var leadingIcon: Image?
    
    var trailingIcon: Image?
    
    var height: CGFloat = CoreConfig.Design.buttonHeight
    
    var cornerRadius: CGFloat = CoreConfig.Design.buttonRadius
    
    var iconDimension: CGFloat = CoreConfig.Design.buttonIconDimension
    
    var textColor: ColorStyle
    
    var backgroundColor: ColorStyle
    
    var withBorder: Bool
    
    var borderColor: ColorStyle = .onSecondary
    
    var borderWidth: CGFloat = 1
    
    public var body: some View {
        if isEnabled {
            
            if withBorder {
                
                borderedButton
            }
            else {
                defaultButton
            }
        }
        else {
            disabledButton
        }
    }
    
    private var button: some View {
        Button(role: role, action: {
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
    }
    
    private var defaultButton: some View {
        button
            .customBackground(backgroundColor)
            .customCornerRadius(cornerRadius)
    }
    
    private var borderedButton: some View {
        button
            .withCardBorder(backgroundColor: .clear,
                            cornerRadius: cornerRadius,
                            borderColor: borderColor,
                            borderWidth: borderWidth)
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
    
    private var disabledButton: some View {
        DisabledButton(title: title,
                       action: action,
                       leadingIcon:
                        leadingIcon,
                       trailingIcon: trailingIcon,
                       height: height,
                       cornerRadius: cornerRadius)
    }
}

#Preview {
    VStack {
//        CustomButton(title: "Title 1", action: nil)
//        
//        CustomButton(title: "Title 2", action: nil)
//        
//        CustomButton(title: "Title 3", action: nil)
//        
//        CustomButton(title: "Title 4", action: nil)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .customBackground(.surface)
}
