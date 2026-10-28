//
//  ReciterCardView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct ReciterCardView: View {

    let reciter: ReciterInfo
    let detail: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 14) {
            avatarView
            infoView
            Spacer(minLength: 8)
            trailingView
        }
        .padding(16)
        .background(Color.cardSurface)
        .customCornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive ? ColorStyle.primary.color.opacity(0.45) : ColorStyle.cardBorder.color,
                    lineWidth: isActive ? 1.5 : 1
                )
        )
    }

    // MARK: - Avatar

    private var avatarView: some View {
        WebImage(url: URL(string: reciter.imageURL ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .fill(Color.surfaceContainerHigh)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .customForeground(.onSurfaceVariant)
                )
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(ColorStyle.secondary.color.opacity(0.2), lineWidth: 2)
        )
    }

    // MARK: - Info

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reciter.arabicName)
                .customStyle(.kitab(size: 16, bold: true), .onSurface)
                .lineLimit(1)

            Text(reciter.englishName)
                .customStyle(.caption1, .subtitle)
                .lineLimit(1)

            Text(detail)
                .customStyle(.caption2, .onSurfaceVariant)
                .lineLimit(1)
        }
    }

    // MARK: - Trailing

    private var trailingView: some View {
        HStack(spacing: 8) {
            if isActive {
                Image(systemName: "waveform")
                    .font(.system(size: 14, weight: .semibold))
                    .customForeground(.primary)
            }

            Image(systemName: "chevron.forward")
                .font(.system(size: 13, weight: .semibold))
                .customForeground(.subtitle)
        }
    }
}
