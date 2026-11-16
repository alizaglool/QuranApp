//
//  KhatmahScheduleView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahScheduleView: View {

    @StateObject private var viewModel: KhatmahScheduleViewModel

    init(coordinator: any KhatmahCoordinating, viewModel: KhatmahScheduleViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? KhatmahScheduleViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension KhatmahScheduleView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    summary
                    timeline
                }
                .padding(.horizontal, .big)
                .padding(.top, .xSm)
                .padding(.bottom, .xxxBig)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel(viewModel.backActionTitle)

            Text(viewModel.screenTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    var summary: some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack(alignment: .firstTextBaseline, spacing: .sm) {
                Text(viewModel.percentText)
                    .customStyle(.kitab(size: 28, bold: true), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .monospacedDigit()

                Spacer(minLength: 0)

                Text(viewModel.completedDaysText)
                    .customStyle(.caption1, .onSurfaceVariant)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            KhatmahProgressTrack(fraction: viewModel.progressFraction)
        }
        .padding(.big)
        .khatmahCardChrome()
        .accessibilityElement(children: .combine)
    }

    var timeline: some View {
        LazyVStack(alignment: .leading, spacing: .xxSm) {
            ForEach(viewModel.dayItems) { item in
                KhatmahDayRow(item: item) {
                    viewModel.onDayTapped(item)
                }
            }
        }
        .padding(.xSm)
        .khatmahCardChrome()
    }
}
