//
//  ProhibitedTimesBanner.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/09/2026
//

import SwiftUI
import Core

/// Shown in the Adhkar special section only while the clock sits inside one of
/// the four windows in which voluntary prayer is not offered. The subtitle names
/// the live window, so the card answers "which one am I in" without a tap.
struct ProhibitedTimesBanner: View {

    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: .md) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorStyle.error.color.opacity(0.14))
                    .frame(width: 52, height: 52)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 22))
                    .customForeground(.error)
            }

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(title)
                    .customStyle(.headline, .onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.backward")
                .font(.system(size: 14, weight: .medium))
                .customForeground(.onSurfaceVariant)
        }
        .padding(.md)
        .background(Color.cardSurface)
        .customCornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        // Inset rather than a full-height edge: a 4pt bar behind a 16pt corner
        // radius gets cut from y=16 down to y=5.4 at its outer edge, so it
        // renders as a lens instead of a marker.
        .overlay(alignment: .leading) {
            Capsule()
                .fill(ColorStyle.error.color)
                .frame(width: 4)
                .padding(.vertical, .md)
                .padding(.leading, .xxSm)
        }
        // No `.isButton` trait here — the caller already wraps this in a Button,
        // and adding it again makes VoiceOver say "button" twice.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle)
    }
}
