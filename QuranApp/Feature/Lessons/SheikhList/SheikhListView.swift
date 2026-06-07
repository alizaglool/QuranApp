//
//  SheikhListView.swift
//  QuranApp
//

import SwiftUI
import Core

struct SheikhListView: View {
    @StateObject var viewModel: SheikhListViewModel
    @State private var showSortPicker = false

    init(coordinator: any LessonsCoordinating) {
        _viewModel = StateObject(wrappedValue: SheikhListViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Main Content

extension SheikhListView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            if viewModel.isLoading {
                loadingGrid
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                sheikhGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .sheet(isPresented: $showSortPicker) {
            SheikhSortPickerView(selected: Binding(
                get: { viewModel.sortOption },
                set: { viewModel.updateSort($0) }
            ), onDismiss: { showSortPicker = false })
        }
    }
}

// MARK: - Nav Bar

extension SheikhListView {

    var navBar: some View {
        HStack {
            Text("المشايخ")
                .customStyle(.heading3, .primary)
            Spacer()
            Button {
                showSortPicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 14, weight: .medium))
                    Text(viewModel.sortOption.rawValue)
                        .customStyle(.caption2, .subtitle)
                }
                .customForeground(.subtitle)
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Sheikh Grid

extension SheikhListView {

    var sheikhGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return NoIndicatorsScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.sheikhs) { sheikh in
                    SheikhCardView(sheikh: sheikh)
                        .onTapGesture { viewModel.onSheikhTapped(sheikh) }
                }
            }
            .padding(.horizontal, .big)
            .padding(.top, 8)
            .padding(.bottom, 32)

            if viewModel.hasMorePages {
                ProgressView()
                    .padding(.bottom, 16)
                    .onAppear { viewModel.loadNextPage() }
            }
        }
    }
}

// MARK: - Loading Grid

extension SheikhListView {

    var loadingGrid: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<9, id: \.self) { _ in
                sheikhCardSkeleton
            }
        }
        .padding(.horizontal, .big)
        .padding(.top, 8)
    }

    var sheikhCardSkeleton: some View {
        VStack(spacing: 8) {
            Circle()
                .customFill(.container)
                .frame(width: 80, height: 80)
                .withShimmerOverlay().redacted(reason: .placeholder)
            RoundedRectangle(cornerRadius: 4)
                .customFill(.container)
                .frame(height: 12)
                .withShimmerOverlay().redacted(reason: .placeholder)
            RoundedRectangle(cornerRadius: 4)
                .customFill(.container)
                .frame(width: 50, height: 10)
                .withShimmerOverlay().redacted(reason: .placeholder)
        }
        .padding(12)
    }
}

// MARK: - Error View

extension SheikhListView {

    func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .customForeground(.subtitle)
            Text(message)
                .customStyle(.bodySmall, .subtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                viewModel.refreshData()
            } label: {
                Text("إعادة المحاولة")
                    .customStyle(.subheadline, .onPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).customFill(.primary))
            }
            Spacer()
        }
    }
}
