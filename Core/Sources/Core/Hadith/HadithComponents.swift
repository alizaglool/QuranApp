//
//  HadithComponents.swift
//  Core
//
//  Created by Ali M. Zaghloul on 2026-05-28.
//

import SwiftUI

// MARK: - HadithNavButton

/// 36×36 icon button styled for Hadith nav bars.
public struct HadithNavButton: View {

    let icon: String
    let action: () -> Void

    public init(icon: String, action: @escaping () -> Void) {
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .customForeground(.hadithNav)
                .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - HadithIconBadge

/// 36×36 rounded-square gold icon badge for Hadith scholarly rows.
public struct HadithIconBadge: View {

    let icon: String

    public init(icon: String) {
        self.icon = icon
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerSm)
                .fill(Color.hadithGold.opacity(0.15))
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .customForeground(.hadithGold)
        }
    }
}

// MARK: - HadithBottomBarButton

/// Icon + label button for the Hadith reading bottom bar.
public struct HadithBottomBarButton: View {

    let icon: String
    let label: String
    let tint: Color?
    let action: () -> Void

    public init(icon: String, label: String, tint: Color? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.tint = tint
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 19))
                    .foregroundColor(tint ?? Color.hadithNav)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(tint ?? Color.hadithSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
