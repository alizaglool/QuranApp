//
//  HomeContinueReadingCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 22/10/2026
//

import SwiftUI
import Core

struct HomeContinueReadingCard: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        if viewModel.lastReadPage != nil {
            card
        } else {
            Color.clear.frame(height: 0)
        }
    }
}

// MARK: - Layout

private extension HomeContinueReadingCard {

    var card: some View {
        Button(action: { viewModel.onResumeTapped() }) {
            ZStack {
                RoundedRectangle(cornerRadius: .cornerXxl)
                    .fill(Color.primaryContainer)

                RoundedRectangle(cornerRadius: .cornerXxl)
                    .stroke(ColorStyle.primary.color.opacity(0.2), lineWidth: 1)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .offset(x: 60, y: -40)

                HStack {
                    VStack(alignment: .leading, spacing: .xSm) {
                        Text(viewModel.continueReadingTitle)
                            .customStyle(.kitab(size: 10, bold: true))
                            .foregroundColor(ColorStyle.onPrimaryContainer.color.opacity(0.6))
                            .tracking(viewModel.sectionTitleTracking)

                        Text(viewModel.lastReadSurahName)
                            .customStyle(.kitab(size: 18, bold: true))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        progressRow
                    }

                    Spacer()

                    resumeButton
                }
                .padding(.xBig)
            }
            .frame(height: 140)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, .big)
    }

    var progressRow: some View {
        HStack(spacing: .xSm) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 96, height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(ColorStyle.secondary.color)
                    .frame(width: max(4, CGFloat(96 * viewModel.lastReadProgress)), height: 4)
            }

            if let page = viewModel.lastReadPage {
                Text("\(viewModel.pageTitle) \(page)")
                    .customStyle(.kitab(size: 10, bold: true))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
    }

    var resumeButton: some View {
        Text(viewModel.resumeTitle)
            .customStyle(.kitab(size: 12, bold: true), .resumeLabel)
            .padding(.horizontal, .md)
            .padding(.vertical, .xSm)
            .background(Color.resumeSurface)
            .customCornerRadius(10)
    }
}
