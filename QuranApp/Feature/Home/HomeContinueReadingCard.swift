//
//  HomeContinueReadingCard.swift
//  QuranApp
//

import SwiftUI
import Core

extension HomeView {

    var continueReadingCard: some View {
        Button(action: { viewModel.onResumeTapped() }) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.primaryContainer)

                RoundedRectangle(cornerRadius: 20)
                    .stroke(ColorStyle.primary.color.opacity(0.2), lineWidth: 1)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .blur(radius: 40)
                    .offset(x: 60, y: -40)

                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppLocalizedKeys.continueReading.value)
                            .customStyle(.kitab(size: 10, bold: true))
                            .foregroundColor(ColorStyle.onPrimaryContainer.color.opacity(0.6))
                            .tracking(1.5)

                        Text(viewModel.lastReadSurahName)
                            .customStyle(.kitab(size: 18, bold: true))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(spacing: 10) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 96, height: 4)

                                RoundedRectangle(cornerRadius: 2)
                                    .fill(ColorStyle.secondary.color)
                                    .frame(width: max(4, CGFloat(96 * viewModel.lastReadProgress)), height: 4)
                            }

                            if let page = viewModel.lastReadPage {
                                Text("\(AppLocalizedKeys.page.value) \(page)")
                                    .customStyle(.kitab(size: 10, bold: true))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }

                    Spacer()

                    resumeButton
                }
                .padding(24)
            }
            .frame(height: 140)
        }
        .padding(.horizontal, .big)
    }

    var resumeButton: some View {
        Group {
            if colorScheme == .dark {
                Text(AppLocalizedKeys.resume.value)
                    .customStyle(.kitab(size: 12, bold: true), .onSurface)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ColorStyle.secondary.color)
                    .customCornerRadius(10)
            } else {
                Text(AppLocalizedKeys.resume.value)
                    .customStyle(.kitab(size: 12, bold: true), .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .customCornerRadius(10)
            }
        }
    }
}
