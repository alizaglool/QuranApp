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

    init(key: GuideKey, coordinator: any ContentCoordinating) {
        _viewModel = StateObject(wrappedValue: GuideDetailViewModel(key: key, coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension GuideDetailView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    if viewModel.hasContent {
                        if let overview = viewModel.overview {
                            headerCard(overview)
                        }

                        ForEach(viewModel.sections) { section in
                            sectionBlock(section)
                        }

                        ForEach(viewModel.pages) { page in
                            pageCard(page)
                        }
                    } else {
                        emptyCard
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, .sm)
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
            .accessibilityLabel(viewModel.backAccessibilityLabel)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.screenTitle)
                    .customStyle(.heading3, .onSurface)
                Text(viewModel.screenSubtitle)
                    .customStyle(.caption1, .subtitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Sections

private extension GuideDetailView {

    func sectionBlock(_ section: GuideDetailSection) -> some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(section.title)
                .customStyle(.heading2, .onSurface)

            if let header = section.header {
                headerCard(header)
            }

            ForEach(section.stages) { stage in
                stageCard(stage)
            }
        }
    }

    func stageCard(_ stage: GuideDetailStage) -> some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(stage.title)
                .customStyle(.headline, .onSurface)
                .fixedSize(horizontal: false, vertical: true)

            if let header = stage.header {
                headerBody(header)
            }

            ForEach(stage.items) { item in
                itemBlock(item)
            }

            ForEach(stage.substages) { substage in
                substageCard(substage)
            }
        }
        .padding(.md)
        .contentCardChrome()
    }

    func substageCard(_ stage: GuideDetailStage) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(stage.title)
                .customStyle(.subheadline, .primary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(stage.items) { item in
                itemBlock(item)
            }
        }
        .padding(.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: .cornerMd)
                .fill(ColorStyle.surfaceContainerLow.color)
        )
    }
}

// MARK: - Items

private extension GuideDetailView {

    func itemBlock(_ item: GuideItem) -> some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            if item.hasTitle {
                Text(item.displayTitle)
                    .customStyle(.subheadline, .onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(viewModel.attributed(item.displayBody))
                .customStyle(.bodyMedium, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)

            if !item.source.isEmpty {
                Text(item.source)
                    .customStyle(.caption2, .outline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Headers

private extension GuideDetailView {

    func headerCard(_ header: GuideHeader) -> some View {
        headerBody(header)
            .padding(.md)
            .contentCardChrome()
    }

    func headerBody(_ header: GuideHeader) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            if !header.subtitle.isEmpty {
                Text(viewModel.attributed(header.subtitle))
                    .customStyle(.bodyMedium, .onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !header.text.isEmpty {
                Text(viewModel.attributed(header.text))
                    .customStyle(.adhkar(size: 18), .primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !header.source.isEmpty {
                Text(header.source)
                    .customStyle(.caption2, .outline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Pages

private extension GuideDetailView {

    func pageCard(_ page: GuidePage) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(page.displayTitle)
                .customStyle(.headline, .onSurface)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.attributed(page.displayBody))
                .customStyle(.adhkar(size: 17), .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.md)
        .contentCardChrome()
    }

    var emptyCard: some View {
        Text(viewModel.emptyMessage)
            .customStyle(.bodySmall, .subtitle)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.md)
            .contentCardChrome()
    }
}
