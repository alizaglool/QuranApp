//
//  AthkarHubView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarHubView: View {

    @StateObject private var viewModel: AthkarHubViewModel

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    init(coordinator: AdhkarCoordinating) {
        _viewModel = StateObject(wrappedValue: AthkarHubViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .sheet(item: $viewModel.downloadPrompt,
               onDismiss: viewModel.onDownloadPromptDismissed) { pack in
            AthkarAudioPromptSheet(pack: pack) { viewModel.openReaderWithoutAudio() }
                .presentationDetents([.height(380)])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Main Content

extension AthkarHubView {

    private var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .xBig) {
                    sectionAccent

                    if let banner = viewModel.banner {
                        AthkarTimeBanner(banner: banner) { viewModel.selectBanner() }
                            .padding(.horizontal, .big)
                    }

                    if viewModel.hasSpecialContent {
                        specialSection
                    }

                    AthkarQuickChipsRow(packs: viewModel.shortcutPacks) { viewModel.selectPack($0) }

                    quickAccessRow

                    ForEach(viewModel.sections) { section in
                        packSection(section)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .customBackground(.background)
    }

    private var navBar: some View {
        HStack {
            Text(viewModel.screenTitle)
                .customStyle(.heading2, .onSurface)
            Spacer()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    private var sectionAccent: some View {
        Rectangle()
            .fill(ColorStyle.secondary.color)
            .frame(width: 48, height: 3)
            .customCornerRadius(2)
            .padding(.horizontal, .big)
            .padding(.top, .sm)
    }
}

// MARK: - Special Section

extension AthkarHubView {

    private var specialSection: some View {
        VStack(alignment: .leading, spacing: .sm) {
            if let window = viewModel.activeProhibitedWindow {
                Button { viewModel.selectProhibitedTimes() } label: {
                    ProhibitedTimesBanner(
                        title: viewModel.prohibitedCardTitle,
                        subtitle: window.cardSubtitleAr
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, .big)
            }

            ForEach(viewModel.specialCategories) { category in
                Button { viewModel.selectCategory(category) } label: {
                    SpecialCategoryBanner(category: category)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, .big)
            }
        }
    }
}

// MARK: - Quick Access Row

extension AthkarHubView {

    private var quickAccessRow: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            AdhkarQuickCard(
                title: viewModel.allahNamesTitle,
                subtitle: viewModel.allahNamesSubtitle,
                icon: "star.fill",
                tint: .secondary
            ) {
                viewModel.selectAllahNames()
            }

            AdhkarQuickCard(
                title: viewModel.myAdhkarTitle,
                subtitle: viewModel.myAdhkarSubtitle,
                icon: "heart.fill",
                tint: .primary
            ) {
                viewModel.selectMyAdhkar()
            }

            if viewModel.hasTasbihCard {
                AdhkarQuickCard(
                    title: viewModel.tasbihTitle,
                    subtitle: viewModel.tasbihSubtitle,
                    icon: "circle.hexagongrid.fill",
                    tint: .primary
                ) {
                    viewModel.selectTasbih()
                }
            }
        }
        .padding(.horizontal, .big)
    }
}

// MARK: - Pack Sections

extension AthkarHubView {

    @ViewBuilder
    private func packSection(_ section: AthkarHubSection) -> some View {
        VStack(alignment: .leading, spacing: .sm) {
            AthkarSectionHeaderView(
                title: section.title,
                subtitle: section.subtitle,
                downloadTitle: viewModel.showsDownloadAll(section) ? viewModel.downloadAllLabel(for: section) : nil
            ) {
                viewModel.downloadAll(in: section)
            }
            .padding(.horizontal, .big)

            switch section.layout {
            case .grid: grid(for: section)
            case .list: list(for: section)
            }
        }
    }

    private func grid(for section: AthkarHubSection) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(section.packs) { pack in
                AthkarPackCard(
                    pack: pack,
                    countLabel: viewModel.countLabel(for: pack),
                    state: viewModel.state(for: pack),
                    onSelect: { viewModel.selectPack(pack) },
                    onDownload: { viewModel.toggleDownload(pack) }
                )
            }
        }
        .padding(.horizontal, .big)
    }

    private func list(for section: AthkarHubSection) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(section.packs.enumerated()), id: \.element.id) { index, pack in
                AthkarPackRow(
                    pack: pack,
                    countLabel: viewModel.countLabel(for: pack),
                    state: viewModel.state(for: pack),
                    onSelect: { viewModel.selectPack(pack) },
                    onDownload: { viewModel.toggleDownload(pack) }
                )

                if index < section.packs.count - 1 {
                    Rectangle()
                        .fill(ColorStyle.outlineVariant.color)
                        .frame(height: 1)
                        .padding(.leading, 68)
                }
            }
        }
        .background(Color.cardSurface)
        .customCornerRadius(.cornerXl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}
