//
//  AdhkarCategoryCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import SwiftUI
import Core

struct AdhkarCategoryCard: View {
    let category: DhikrCategory
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var localizationManager: LocalizationManager

    private var displayTitle: String {
        localizationManager.currentLanguage == .Arabic ? category.titleAr : category.titleEn
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorStyle.primary.color.opacity(colorScheme == .dark ? 0.15 : 0.06))
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .customForeground(.primary)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text(String(format: AppLocalizedKeys.adhkarCount.value, category.adhkar.count))
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
}
