//
//  AthkarQuickChipsRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarQuickChipsRow: View {
    let packs: [AthkarPack]
    let onSelect: (AthkarPack) -> Void

    var body: some View {
        NoIndicatorsScrollView(.horizontal) {
            HStack(spacing: .xSm) {
                ForEach(packs) { pack in
                    chip(for: pack)
                }
            }
            .padding(.horizontal, .big)
            .padding(.vertical, 2)
        }
    }

    private func chip(for pack: AthkarPack) -> some View {
        let tint = AthkarPackTint.tint(for: pack.mood)

        return HStack(spacing: .xxSm) {
            Image(systemName: AthkarPackIcon.symbol(for: pack.key))
                .font(.system(size: 13, weight: .medium))
                .customForeground(tint.accent)

            Text(pack.name)
                .customStyle(.caption1, .onSurface)
                .lineLimit(1)
        }
        .padding(.horizontal, .sm)
        .padding(.vertical, .xSm)
        .background(tint.wash.color)
        .clipShape(Capsule())
        .contentShape(Capsule())
        .onTapGesture { onSelect(pack) }
    }
}
