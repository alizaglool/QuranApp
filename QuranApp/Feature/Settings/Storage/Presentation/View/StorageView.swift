//
//  StorageView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 28/10/2026.
//

import SwiftUI
import Core

struct StorageView: View {

    @StateObject private var viewModel: StorageViewModel

    init(coordinator: any StorageCoordinating) {
        _viewModel = StateObject(wrappedValue: StorageViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension StorageView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            if viewModel.isScanning {
                scanningState
            } else if viewModel.isLibraryEmpty {
                emptyState
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .alert(viewModel.deletionRequest?.title ?? "",
               isPresented: Binding(get: { viewModel.deletionRequest != nil },
                                    set: { if !$0 { viewModel.cancelDeletion() } }),
               presenting: viewModel.deletionRequest) { request in
            Button(request.confirmTitle, role: .destructive) {
                viewModel.confirmDeletion(request.target)
            }
            Button(request.cancelTitle, role: .cancel) {
                viewModel.cancelDeletion()
            }
        } message: { request in
            Text(request.message)
        }
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            Text(viewModel.screenTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Content

private extension StorageView {

    var content: some View {
        NoIndicatorsScrollView {
            VStack(alignment: .leading, spacing: .big) {
                StorageUsageHeaderCard(caption: viewModel.totalCaption,
                                       totalLabel: viewModel.totalSizeLabel,
                                       legend: viewModel.legend,
                                       captionTracking: viewModel.captionTracking)
                    .padding(.horizontal, .big)

                if !viewModel.chips.isEmpty {
                    StorageFilterChips(items: viewModel.chips,
                                       onSelect: viewModel.selectCategory)
                }

                ForEach(viewModel.sections) { section in
                    sectionView(section)
                }
            }
            .padding(.top, .sm)
            .padding(.bottom, .xxxBig)
        }
    }

    func sectionView(_ section: StorageSectionItem) -> some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(section.title)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(viewModel.captionTracking)

            ForEach(section.groups) { group in
                StorageGroupCard(group: group,
                                 deleteAllTitle: viewModel.deleteAllTitle,
                                 deleteLabel: viewModel.deleteLabel,
                                 showMoreTitle: viewModel.showMoreTitle,
                                 showLessTitle: viewModel.showLessTitle,
                                 onDeleteAll: { viewModel.requestDeleteAll(group) },
                                 onDeleteRow: viewModel.requestDelete,
                                 onToggleExpanded: { viewModel.toggleGroup(group.id) })
            }
        }
        .padding(.horizontal, .big)
    }
}

// MARK: - States

private extension StorageView {

    var scanningState: some View {
        VStack(spacing: .sm) {
            ProgressView()

            Text(viewModel.scanningTitle)
                .customStyle(.bodySmall, .onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var emptyState: some View {
        VStack(spacing: .sm) {
            Image(systemName: "internaldrive")
                .font(.system(size: 42, weight: .light))
                .customForeground(.onSurfaceVariant)

            Text(viewModel.emptyTitle)
                .customStyle(.headline, .onSurface)
                .multilineTextAlignment(.center)

            Text(viewModel.emptyMessage)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .xxxBig)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
