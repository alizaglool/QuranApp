//
//  HeaderView.swift
//  Core
//
//  Created by Ali M. Zaghloul on 03/05/2025.
//


import SwiftUI

public struct QuranAppNavBar: View {
    let logo: Image
    let chatIcon: Image
    let bellIcon: Image
    let chatCount: Int
    let bellCount: Int
    
    var onChatTap: EmptyAction
    var onBellTap: EmptyAction
    
    public init(logo: Image, chatIcon: Image, bellIcon: Image, chatCount: Int, bellCount: Int, onChatTap: EmptyAction, onBellTap: EmptyAction) {
        self.logo = logo
        self.chatIcon = chatIcon
        self.bellIcon = bellIcon
        self.chatCount = chatCount
        self.bellCount = bellCount
        self.onChatTap = onChatTap
        self.onBellTap = onBellTap
    }
    
    public var body: some View {
        HStack {
            logo
                .resizable()
                .frame(width: 150, height: 32)
                .scaledToFit()
            
            Spacer()
            
            HStack(spacing: 16) {
                iconWithBadge(icon: chatIcon, count: chatCount, action: onChatTap)
                iconWithBadge(icon: bellIcon, count: bellCount, action: onBellTap)
            }
        }
        .padding(.horizontal, 0)
        .padding(12)
//        .padding(16)
        .background(Color.white)
    }
    
    private func iconWithBadge(icon: Image, count: Int, action: (() -> Void)?) -> some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                action?()
            }) {
                icon
                    .resizable()
                    .frame(width: 28, height: 28)
            }
            
            if count > 0 {
                Text("\(count)")
                    .customStyle(.caption2)                    .foregroundColor(.white)
                    .padding(4)
                    .background(Circle().fill(Color.red))
                    .offset(x: 8, y: -8)
            }
        }
    }
}
