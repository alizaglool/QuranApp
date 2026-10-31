//
//  KhatmahCardChrome.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahCardChrome: ViewModifier {

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: .cornerXxl)
                    .fill(Color.cardSurface)
            )
            .clipShape(RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXxl)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
    }
}

extension View {

    func khatmahCardChrome() -> some View {
        modifier(KhatmahCardChrome())
    }
}
