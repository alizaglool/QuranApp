//
//  AdhkarQuickCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import SwiftUI
import Core

struct AdhkarQuickCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Tint
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tint.wash.color)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .customForeground(tint.accent)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .customStyle(.headline, .onSurface)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .customStyle(.caption2, .onSurfaceVariant)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .frame(minHeight: 130)
            .background(Color.cardSurface)
            .customCornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

extension AdhkarQuickCard {

    /// Brand accent a quick card is tinted with. Each case names both the icon
    /// colour and the wash behind it, so neither is composed at the call site.
    enum Tint {
        case primary
        case secondary

        var accent: ColorStyle {
            switch self {
            case .primary:   return .primary
            case .secondary: return .secondary
            }
        }

        var wash: ColorStyle {
            switch self {
            case .primary:   return .washPrimary
            case .secondary: return .washSecondaryCard
            }
        }
    }
}
