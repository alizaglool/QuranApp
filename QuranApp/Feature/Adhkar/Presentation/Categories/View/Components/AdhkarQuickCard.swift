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
    let color: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(colorScheme == .dark ? 0.15 : 0.06))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
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
            .background(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
            .customCornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorStyle.outlineVariant.color.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
