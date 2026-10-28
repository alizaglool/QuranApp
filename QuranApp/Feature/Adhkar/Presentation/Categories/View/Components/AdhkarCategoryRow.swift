//
//  AdhkarCategoryRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 14/10/2026
//

import SwiftUI
import Core

struct AdhkarCategoryRow: View {
    let category: DhikrCategory
    @EnvironmentObject private var localizationManager: LocalizationManager

    private var displayTitle: String {
        localizationManager.currentLanguage == .Arabic ? category.titleAr : category.titleEn
    }

    private var countText: String {
        String(format: AppLocalizedKeys.adhkarCount.value, category.adhkar.count)
    }

    var body: some View {
        HStack(spacing: .sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorStyle.washPrimary.color)
                    .frame(width: 40, height: 40)
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .customForeground(.primary)
            }

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(displayTitle)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text(countText)
                    .customStyle(.caption2, .onSurfaceVariant)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.backward")
                .font(.system(size: 14, weight: .medium))
                .customForeground(.onSurfaceVariant)
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(displayTitle)
        .accessibilityValue(countText)
    }
}
