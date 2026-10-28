//
//  AthkarPackRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarPackRow: View {
    let pack: AthkarPack
    let countLabel: String
    let state: AthkarAudioState
    let onSelect: () -> Void
    let onDownload: () -> Void

    private var tint: AthkarPackTint { AthkarPackTint.tint(for: pack.mood) }

    var body: some View {
        HStack(spacing: .sm) {
            iconTile

            VStack(alignment: .leading, spacing: 3) {
                Text(pack.name)
                    .customStyle(.bodyMedium, .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(countLabel)
                    .customStyle(.caption2, .onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)

            Spacer(minLength: .xSm)

            if pack.hasAudio {
                AthkarDownloadControl(state: state, action: onDownload)
            }

            Image(systemName: "chevron.forward")
                .font(.system(size: 12, weight: .semibold))
                .customForeground(.outlineVariant)
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .frame(maxWidth: .infinity)
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
                .font(.system(size: 17))
                .customForeground(tint.accent)
        }
    }
}
