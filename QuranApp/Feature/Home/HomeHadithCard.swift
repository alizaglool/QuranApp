//
//  HomeHadithCard.swift
//  QuranApp
//

import SwiftUI
import Core

extension HomeView {

    var hadithOfTheDayCard: some View {
        VStack(spacing: 24) {
            Image(systemName: "quote.opening")
                .font(.system(size: 28))
                .foregroundColor(ColorStyle.secondary.color)

            Text(viewModel.hadithArabic)
                .customStyle(.heading3, .primary)
                .multilineTextAlignment(.center)
                .lineSpacing(10)

            Text(viewModel.hadithTranslation)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)

            HStack {
                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                    .frame(height: 0.5)

                Text(viewModel.hadithReference)
                    .customStyle(.kitab(size: 10, bold: true))
                    .foregroundColor(ColorStyle.onSurfaceVariant.color.opacity(0.6))
                    .tracking(1.5)
                    .lineLimit(1)
                    .fixedSize()

                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                    .frame(height: 0.5)
            }
        }
        .padding(32)
        .background(Color.surfaceContainerLowest)
        .customCornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}
