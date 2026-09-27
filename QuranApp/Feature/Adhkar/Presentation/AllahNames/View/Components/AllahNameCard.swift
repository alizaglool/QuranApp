//
//  AllahNameCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import SwiftUI
import Core

struct AllahNameCard: View {
    let name: AllahName
    let colorScheme: ColorScheme
    let isRTL: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(String(format: "%d", name.id))
                .customStyle(.adhkar(size: 10), .onSurfaceVariant)

            Text(name.nameAr.trimmingCharacters(in: .whitespaces))
                .customStyle(.adhkar(size: 17, bold: true), .primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.layoutDirection, .rightToLeft)

            if isRTL {
                Text(name.nameAr.trimmingCharacters(in: .whitespaces))
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let meaning = name.meaning {
                Text(meaning)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(name.transliteration)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ColorStyle.outlineVariant.color.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
        )
    }
}
