//
//  AthkarTimeBanner.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarTimeBanner: View {
    let banner: AthkarHubBanner
    let action: () -> Void

    var body: some View {
        HStack(spacing: .sm) {
            ZStack {
                Circle()
                    .fill(ColorStyle.washSecondary.color)
                    .frame(width: 44, height: 44)

                Image(systemName: banner.icon)
                    .font(.system(size: 19))
                    .customForeground(.secondary)
            }

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(banner.badge)
                    .customStyle(.caption2)
                    .customForeground(.secondary)
                    .padding(.horizontal, .xSm)
                    .padding(.vertical, 2)
                    .background(ColorStyle.washSecondary.color)
                    .clipShape(Capsule())

                Text(banner.title)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: .xSm)

            Image(systemName: "chevron.forward")
                .font(.system(size: 13, weight: .semibold))
                .customForeground(.secondary)
        }
        .padding(.md)
        .frame(maxWidth: .infinity)
        .background(ColorStyle.washSecondarySubtle.color)
        .customCornerRadius(.cornerCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard)
                .strokeBorder(ColorStyle.secondary.color.opacity(0.22), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
        .accessibilityElement(children: .combine)
    }
}
