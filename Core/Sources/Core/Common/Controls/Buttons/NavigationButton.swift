//
//  NavigationButton.swift
//
//
//  Created by Ali M. Zaghloul on 7/9/24.
//

import SwiftUI

import SwiftUI

public struct NavigationButton: View {
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    var title: String
    var icon: Image
    var trailingIcon: Image?
    
    var titleColor: Color
    var iconColor: Color
    var trailingIconColor: Color
    
    var action: EmptyAction
    
    public init(title: String,
                icon: Image,
                trailingIcon: Image? = nil,
                titleColor: Color = .primary,
                iconColor: Color = .primary,
                trailingIconColor: Color = .gray,
                action: EmptyAction = nil) {
        self.title = title
        self.icon = icon
        self.trailingIcon = trailingIcon
        self.titleColor = titleColor
        self.iconColor = iconColor
        self.trailingIconColor = trailingIconColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            action?()
        }) {
            content
        }
    }
    
    private var content: some View {
        HStack(spacing: 12) {
            iconLabel
            titleLabel
            Spacer()
            
            if let icon = trailingIconForCurrentLayout {
                icon
                    .foregroundColor(trailingIconColor)
            }
        }
    }
    
    private var iconLabel: some View {
        icon
            .resizable()
            .frame(width: 24, height: 24)
            .foregroundColor(iconColor)
    }
    
    private var titleLabel: some View {
        Text(title)
            .customStyle(.subheadline, .black)
    }
    
    private var trailingIconForCurrentLayout: Image? {
        if let trailingIcon = trailingIcon {
            return trailingIcon
        }
        return layoutDirection == .rightToLeft
            ? Image(systemName: "chevron.left")
            : Image(systemName: "chevron.right")
    }
}

#Preview {
    VStack(spacing: 16) {
        NavigationButton(title: "Edit Profile", icon: Image(systemName: "person"))
            .environment(\.layoutDirection, .leftToRight)

        NavigationButton(title: "تعديل الملف", icon: Image(systemName: "person"))
            .environment(\.layoutDirection, .rightToLeft)
    }
    .padding()
}
