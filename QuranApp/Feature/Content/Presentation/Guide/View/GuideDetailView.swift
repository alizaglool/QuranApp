//
//  GuideDetailView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct GuideDetailView: View {

    @StateObject private var viewModel: GuideDetailViewModel

    init(key: GuideKey, coordinator: ContentCoordinating?) {
        _viewModel = StateObject(wrappedValue: GuideDetailViewModel(key: key, coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            VStack(spacing: 0) {
                navigationBar

                NoIndicatorsScrollView {
                    VStack(alignment: .leading, spacing: .xBig) {
                        header

                        if viewModel.hasContent {
                            if let overview = viewModel.overview {
                                overviewCard(overview)
                            }

                            if viewModel.canStart {
                                startButton
                            }

                            ForEach(viewModel.sections) { section in
                                sectionBlock(section)
                            }
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
                .customStyle(.bodySmall, .onSurfaceVariant)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Overview

    private func overviewCard(_ overview: GuideReaderNote) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(viewModel.overviewTitle)
                .customStyle(.caption2, .primary)

            if overview.hasSubtitle {
                Text(overview.subtitle)
                    .customStyle(.bodyMedium, .onSurfaceVariant)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GuideTextBlocksView(blocks: overview.blocks)

            if overview.hasSource {
                Text(overview.source)
                    .customStyle(.caption2, .outline)
            }
        }
        .padding(.md)
        .contentCardChrome()
    }

    // MARK: - Start

    private var startButton: some View {
        Button(action: viewModel.onStartTapped) {
            HStack(spacing: .xSm) {
                Text(viewModel.startTitle)
                    .customStyle(.buttonText)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .customForeground(.onPrimary)
            .background(ColorStyle.primary.color)
            .clipShape(RoundedRectangle(cornerRadius: .cornerMd, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sections

    private func sectionBlock(_ section: GuideIndexSection) -> some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(section.title)
                .customStyle(.heading3, .onSurface)

            VStack(spacing: .no) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { offset, row in
                    if offset > 0 {
                        Rectangle()
                            .fill(ColorStyle.outlineVariant.color)
                            .frame(height: 1)
                            .padding(.leading, .md)
                    }
                    GuideIndexRowView(row: row) {
                        viewModel.onRowTapped(row)
                    }
                }
            }
            .contentCardChrome()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty

    private var emptyState: some View {
        Text(viewModel.emptyMessage)
            .customStyle(.subheadline, .onSurfaceVariant)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, .xBig)
    }
}

// MARK: - GuideIndexRowView

private struct GuideIndexRowView: View {

    let row: GuideIndexRow
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                if row.hasMarker {
                    Text(row.marker)
                        .customStyle(.caption1, .primary)
                        .frame(width: 28, height: 28)
                        .background(Color.washPrimary)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.title)
                        .customStyle(.subheadline, .onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let detail = row.detail {
                        HStack(spacing: .xxSm) {
                            Text(detail.label)
                                .customStyle(.caption2, .onSurfaceVariant)

                            Text(detail.value)
                                .customStyle(.caption2, .onSurface)
                        }
                    }
                }

                Spacer(minLength: .xSm)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .customForeground(.outline)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
