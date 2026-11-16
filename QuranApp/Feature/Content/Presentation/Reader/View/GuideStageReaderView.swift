//
//  GuideStageReaderView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct GuideStageReaderView: View {

    @StateObject private var viewModel: GuideStageReaderViewModel

    init(key: GuideKey, pageIndex: Int, coordinator: ContentCoordinating?) {
        _viewModel = StateObject(wrappedValue: GuideStageReaderViewModel(key: key,
                                                                        pageIndex: pageIndex,
                                                                        coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            VStack(spacing: 0) {
                navigationBar

                if viewModel.hasContent {
                    progressBar
                    pager
                } else {
                    emptyState
                }
            }
            .safeAreaInset(edge: .bottom, spacing: .no) {
                if viewModel.hasContent {
                    footer
                }
            }
            .customBackground(.background)
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: .sm) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 17, weight: .semibold))
                    .customForeground(.onSurface)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.backAccessibilityLabel)

            VStack(alignment: .leading, spacing: 1) {
                Text(viewModel.screenTitle)
                    .customStyle(.headline, .onSurface)
                    .lineLimit(1)
                if !viewModel.positionText.isEmpty {
                    Text(viewModel.positionText)
                        .customStyle(.caption2, .onSurfaceVariant)
                }
            }

            Spacer(minLength: .no)
        }
        .padding(.horizontal, .sm)
        .padding(.bottom, .xSm)
    }

    // MARK: - Progress

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorStyle.outlineVariant.color)
                Capsule()
                    .fill(ColorStyle.primary.color)
                    .frame(width: max(proxy.size.width * viewModel.progress, 3))
            }
        }
        .frame(height: 3)
        .padding(.horizontal, .md)
        .animation(.easeInOut(duration: 0.25), value: viewModel.progress)
    }

    // MARK: - Pager

    private var pager: some View {
        TabView(selection: $viewModel.pageIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                NoIndicatorsScrollView {
                    GuideReaderPageView(page: page)
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: .sm) {
            stepButton(title: viewModel.previousTitle,
                       icon: "chevron.backward",
                       isEnabled: viewModel.canGoPrevious,
                       isLeading: true,
                       action: viewModel.onPreviousTapped)

            stepButton(title: viewModel.nextTitle,
                       icon: "chevron.forward",
                       isEnabled: viewModel.canGoNext,
                       isLeading: false,
                       action: viewModel.onNextTapped)
        }
        .padding(.horizontal, .md)
        .padding(.top, .sm)
        .padding(.bottom, .xSm)
        .background(Color.surface)
    }

    private func stepButton(title: String,
                            icon: String,
                            isEnabled: Bool,
                            isLeading: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: .xSm) {
                if isLeading { Image(systemName: icon).font(.system(size: 13, weight: .semibold)) }
                Text(title).customStyle(.buttonText)
                if !isLeading { Image(systemName: icon).font(.system(size: 13, weight: .semibold)) }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .customForeground(isEnabled ? .onSurface : .outline)
            .background(Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: .cornerMd, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: .cornerMd)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack {
            Spacer()
            Text(viewModel.emptyMessage)
                .customStyle(.subheadline, .onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .xBig)
            Spacer()
        }
    }
}

// MARK: - GuideReaderPageView

private struct GuideReaderPageView: View {

    let page: GuideReaderPage

    var body: some View {
        VStack(alignment: .leading, spacing: .big) {
            heading

            if let note = page.note {
                GuideReaderNoteView(note: note)
            }

            if !page.steps.isEmpty {
                GuideReaderStepsView(steps: page.steps)
            }

            ForEach(page.groups) { group in
                GuideReaderGroupView(group: group)
            }
        }
        .padding(.horizontal, .md)
        .padding(.top, .md)
        .padding(.bottom, .xxxBig)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(page.sectionTitle)
                .customStyle(.caption2, .primary)
                .textCase(.uppercase)

            HStack(alignment: .firstTextBaseline, spacing: .sm) {
                if page.hasMarker {
                    Text(page.marker)
                        .customStyle(.heading3, .primary)
                }
                Text(page.title)
                    .customStyle(.heading2, .onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - GuideReaderNoteView

private struct GuideReaderNoteView: View {

    let note: GuideReaderNote

    var body: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            if note.hasSubtitle {
                Text(note.subtitle)
                    .customStyle(.bodyMedium, .onSurfaceVariant)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)
            }

            GuideTextBlocksView(blocks: note.blocks)

            if note.hasSource {
                Text(note.source)
                    .customStyle(.caption2, .outline)
            }
        }
        .padding(.md)
        .contentCardChrome()
    }
}

// MARK: - GuideReaderStepsView

private struct GuideReaderStepsView: View {

    let steps: [GuideReaderStep]

    var body: some View {
        VStack(alignment: .leading, spacing: .no) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { offset, step in
                if offset > 0 {
                    Rectangle()
                        .fill(ColorStyle.outlineVariant.color)
                        .frame(height: 1)
                        .padding(.vertical, .md)
                }
                GuideReaderStepView(step: step)
            }
        }
    }
}

// MARK: - GuideReaderStepView

private struct GuideReaderStepView: View {

    let step: GuideReaderStep

    var body: some View {
        HStack(alignment: .top, spacing: .sm) {
            if step.hasMarker {
                Text(step.marker)
                    .customStyle(.caption1, .primary)
                    .frame(width: 26, height: 26)
                    .background(Color.washPrimary)
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: .sm) {
                if step.hasTitle {
                    Text(GuideTextParser.attributed(step.title))
                        .customStyle(.headline, .onSurface)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 26)
                }

                GuideTextBlocksView(blocks: step.blocks)

                if step.hasSource {
                    Text(step.source)
                        .customStyle(.caption2, .outline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - GuideReaderGroupView

private struct GuideReaderGroupView: View {

    let group: GuideReaderGroup

    var body: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(group.title)
                .customStyle(.heading3, .onSurface)
                .fixedSize(horizontal: false, vertical: true)

            if let note = group.note {
                GuideReaderNoteView(note: note)
            }

            GuideReaderStepsView(steps: group.steps)
        }
        .padding(.top, .xSm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
