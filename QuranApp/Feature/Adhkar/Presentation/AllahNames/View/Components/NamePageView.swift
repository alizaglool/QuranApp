//
//  NamePageView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import SwiftUI
import Core

struct NamePageView: View {
    let name: AllahName
    let isRTL: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 16)

                Text(name.nameAr.trimmingCharacters(in: .whitespaces))
                    .customStyle(.adhkar(size: 52, bold: true), .primary)
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, .big)

                Text(name.transliteration)
                    .customStyle(.heading3, .onSurfaceVariant)
                    .multilineTextAlignment(.center)

                if let meaning = name.meaning {
                    Text(meaning)
                        .customStyle(.bodySmall, .onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .big)
                }

                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)

                if let desc = name.descriptionAr {
                    Text(desc)
                        .customStyle(.adhkar(size: 17), .onSurface)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(6)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.horizontal, .big)
                }

                Spacer(minLength: 40)
            }
        }
    }
}
