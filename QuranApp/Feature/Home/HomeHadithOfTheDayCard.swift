//
//  HomeHadithOfTheDayCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 22/10/2026
//

import SwiftUI
import Core

struct HomeHadithOfTheDayCard: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "quote.opening")
                .font(.system(size: 28))
                .foregroundColor(ColorStyle.secondary.color)

            Text(viewModel.hadithArabic)
                .customStyle(.heading3, .primary)
                .multilineTextAlignment(.center)
                .lineSpacing(10)

            referenceRow
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

// MARK: - Layout

private extension HomeHadithOfTheDayCard {

    var referenceRow: some View {
        HStack {
            Rectangle()
                .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                .frame(height: 0.5)

            Text(viewModel.hadithReference)
                .customStyle(.kitab(size: 11, bold: true))
                .foregroundColor(ColorStyle.onSurfaceVariant.color.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .truncationMode(.tail)
                .layoutPriority(1)

            Rectangle()
                .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                .frame(height: 0.5)
        }
    }
}
