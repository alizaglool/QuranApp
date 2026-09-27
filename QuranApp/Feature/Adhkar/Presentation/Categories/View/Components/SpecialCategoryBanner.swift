//
//  SpecialCategoryBanner.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import SwiftUI
import Core

struct SpecialCategoryBanner: View {
    let category: DhikrCategory
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorStyle.secondary.color.opacity(colorScheme == .dark ? 0.25 : 0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: category.icon)
                    .font(.system(size: 22))
                    .customForeground(.secondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.titleAr)
                    .customStyle(.headline, .onSurface)
                Text("\(category.adhkar.count) ذكر")
                    .customStyle(.caption2, .onSurfaceVariant)
            }

            Spacer()

            Image(systemName: "chevron.backward")
                .font(.system(size: 14, weight: .medium))
                .customForeground(.onSurfaceVariant)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark
                    ? ColorStyle.secondary.color.opacity(0.08)
                    : ColorStyle.secondary.color.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorStyle.secondary.color.opacity(0.3), lineWidth: 1)
        )
    }
}
