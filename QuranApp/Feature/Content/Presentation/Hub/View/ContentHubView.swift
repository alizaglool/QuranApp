//
//  ContentHubView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct ContentHubView: View {

    @StateObject private var viewModel: ContentHubViewModel

    init(coordinator: ContentCoordinating?) {
        _viewModel = StateObject(wrappedValue: ContentHubViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            VStack(spacing: 0) {
                navigationBar

                NoIndicatorsScrollView {
                    VStack(alignment: .leading, spacing: .xBig) {
                        header

                        if viewModel.hasEntries {
                            journeys
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, .md)
                    .padding(.top, .xSm)
                    .padding(.bottom, .xxxBig)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .customBackground(.background)
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: .no) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 17, weight: .semibold))
                    .customForeground(.onSurface)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.backAccessibilityLabel)

            Spacer(minLength: .no)
        }
        .padding(.horizontal, .sm)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(viewModel.screenTitle)
                .customStyle(.largeTitle, .onSurface)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.screenSubtitle)
                .customStyle(.subheadline, .primary)

            Text(viewModel.screenIntro)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Journeys

    private var journeys: some View {
        VStack(spacing: .sm) {
            ForEach(viewModel.entries) { entry in
                JourneyEntryCard(entry: entry) {
                    viewModel.onEntryTapped(entry)
                }
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        Text(viewModel.emptyMessage)
            .customStyle(.subheadline, .onSurfaceVariant)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, .xBig)
    }
}

// MARK: - JourneyEntryCard

private struct JourneyEntryCard: View {

    let entry: ContentHubEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: .sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: .cornerMd, style: .continuous)
                        .fill(entry.wash.color)
                        .frame(width: 48, height: 48)
                    Image(systemName: entry.icon)
                        .font(.system(size: 22))
                        .customForeground(entry.accent)
                }

                VStack(alignment: .leading, spacing: .xSm) {
                    Text(entry.title)
                        .customStyle(.heading3, .onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.subtitle)
                        .customStyle(.bodySmall, .onSurfaceVariant)
                        .lineSpacing(5)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: .xSm) {
                        ForEach(entry.metrics, id: \.self) { metric in
                            MetricChip(metric: metric)
                        }
                    }
                    .padding(.top, .xxSm)
                }

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .customForeground(.outline)
                    .padding(.top, .md)
            }
            .padding(.md)
            .contentCardChrome()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - MetricChip

struct MetricChip: View {

    let metric: GuideMetric

    var body: some View {
        HStack(spacing: .xxSm) {
            Text(metric.label)
                .customStyle(.caption2, .onSurfaceVariant)

            Text(metric.value)
                .customStyle(.caption1, .onSurface)
        }
        .padding(.horizontal, .xSm)
        .padding(.vertical, 5)
        .background(Color.surfaceRaised)
        .clipShape(Capsule())
    }
}

// MARK: - ContentCardChrome

struct ContentCardChrome: ViewModifier {

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: .cornerXxl).fill(Color.cardSurface))
            .clipShape(RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1))
    }
}

extension View {

    func contentCardChrome() -> some View {
        modifier(ContentCardChrome())
    }
}
