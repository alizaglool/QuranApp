//
//  SheikhListView.swift
//  QuranApp
//

import SwiftUI
import Core

struct SheikhListView: View {
    @StateObject var viewModel: SheikhListViewModel

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
                loadingList
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else {
                sheikhList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension SheikhListView {

    var navBar: some View {
        Text("Islamic Lessons")
            .customStyle(.subheadline, .onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .big)
            .padding(.vertical, .sm)
    }
}

// MARK: - Sheikh List

extension SheikhListView {

    var sheikhList: some View {
        NoIndicatorsScrollView {
            VStack(spacing: 0) {
                heroSection
                searchBar
                filterPills

                LazyVStack(spacing: 10) {
                    ForEach(viewModel.displayedSheikhs) { sheikh in
                        SheikhCardView(sheikh: sheikh)
                            .onTapGesture { viewModel.onSheikhTapped(sheikh) }
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, 4)

                if viewModel.hasMorePages && viewModel.searchText.isEmpty {
                    ProgressView()
                        .padding(.vertical, 16)
                        .onAppear { viewModel.loadNextPage() }
                }
            }
            .padding(.bottom, 32)
        }
    }

    var heroSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Explore the")
                .font(.system(size: 34, weight: .bold))
                .customForeground(.onSurface)
            Text("Wisdom")
                .font(.system(size: 34, weight: .bold).italic())
                .foregroundColor(ColorStyle.hadithGold.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .big)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .customForeground(.subtitle)
                .font(.system(size: 15))
            TextField("Search by Sheikh or specialty...", text: $viewModel.searchText)
                .font(.system(size: 15))
                .customForeground(.onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .customFill(.surface)
        )
        .padding(.horizontal, .big)
        .padding(.bottom, 16)
    }

    var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SheikhFilter.allCases, id: \.self) { filter in
                    filterPill(filter)
                }
            }
            .padding(.horizontal, .big)
        }
        .padding(.bottom, 20)
    }

    func filterPill(_ filter: SheikhFilter) -> some View {
        let isSelected = viewModel.selectedFilter == filter
        return Button {
            viewModel.selectedFilter = filter
        } label: {
            Text(filter.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .white : ColorStyle.subtitle.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? ColorStyle.secondary.color : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : ColorStyle.neutral.color, lineWidth: 1)
                        )
                )
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.selectedFilter)
    }
}

// MARK: - Loading List

extension SheikhListView {

    var loadingList: some View {
        NoIndicatorsScrollView {
            VStack(spacing: 0) {
                heroSection
                loadingSearchBar
                LazyVStack(spacing: 10) {
                    ForEach(0..<8, id: \.self) { _ in
                        sheikhCardSkeleton
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, 4)
            }
        }
    }

    var loadingSearchBar: some View {
        RoundedRectangle(cornerRadius: 12)
            .customFill(.surface)
            .frame(height: 44)
            .withShimmerOverlay().redacted(reason: .placeholder)
            .padding(.horizontal, .big)
            .padding(.bottom, 16)
    }

    var sheikhCardSkeleton: some View {
        HStack(spacing: 14) {
            Circle()
                .customFill(.container)
                .frame(width: 64, height: 64)
                .withShimmerOverlay().redacted(reason: .placeholder)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(width: 160, height: 14)
                    .withShimmerOverlay().redacted(reason: .placeholder)
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(width: 100, height: 10)
                    .withShimmerOverlay().redacted(reason: .placeholder)
                RoundedRectangle(cornerRadius: 4)
                    .customFill(.container)
                    .frame(width: 130, height: 10)
                    .withShimmerOverlay().redacted(reason: .placeholder)
            }
            Spacer()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).customFill(.surface))
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
