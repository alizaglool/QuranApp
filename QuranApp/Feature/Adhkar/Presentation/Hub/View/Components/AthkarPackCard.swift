//
//  AthkarPackCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarPackCard: View {
    let pack: AthkarPack
    let countLabel: String
    let state: AthkarAudioState
    let onSelect: () -> Void
    let onDownload: () -> Void

    private var tint: AthkarPackTint { AthkarPackTint.tint(for: pack.mood) }

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack(alignment: .top, spacing: .xSm) {
                iconTile
                Spacer(minLength: .no)
                if pack.hasAudio {
                    AthkarDownloadControl(state: state, action: onDownload)
                }
            }

            Spacer(minLength: .no)

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(pack.name)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Text(countLabel)
                    .customStyle(.caption2, .onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .frame(minHeight: 134, alignment: .topLeading)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerXl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXl)
                .strokeBorder(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(pack.name)
    }

    private var iconTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerXSm)
                .fill(tint.wash.color)
                .frame(width: 40, height: 40)

            Image(systemName: AthkarPackIcon.symbol(for: pack.key))
                .font(.system(size: 18))
                .customForeground(tint.accent)
        }
    }
}
