//
//  HomeQiblaCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import SwiftUI
import Core

struct HomeQiblaCard: View {

    @ObservedObject var homeViewModel: HomeViewModel

    @StateObject private var viewModel = QiblaCompassViewModel()

    var body: some View {
        HStack(spacing: .big) {
            QiblaCompassDial(viewModel: viewModel)
            detailsColumn
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.big)
        .background(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .fill(Color.surfaceContainerLow)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .padding(.horizontal, .big)
        .contentShape(Rectangle())
        .onTapGesture {
            homeViewModel.onPrayerTimesTapped()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

// MARK: - Details

private extension HomeQiblaCard {

    var detailsColumn: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            Text(viewModel.title)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(viewModel.titleTracking)
                .lineLimit(1)

            Text(viewModel.bearingText)
                .customStyle(.kitab(size: 24, bold: true), .primary)
                .monospacedDigit()
                .lineLimit(1)

            Text(viewModel.statusText)
                .customStyle(.caption1, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
