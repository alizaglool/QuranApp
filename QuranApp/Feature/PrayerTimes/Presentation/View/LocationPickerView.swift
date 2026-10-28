//
//  LocationPickerView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import SwiftUI
import Core

struct LocationPickerView: View {

    @StateObject private var viewModel: LocationPickerViewModel

    init(coordinator: any PrayerTimesCoordinating) {
        _viewModel = StateObject(wrappedValue: LocationPickerViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension LocationPickerView {

    var mainContent: some View {
        VStack(spacing: .no) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    searchField
                    currentLocationSection

                    if viewModel.isDeviceLocationDenied {
                        permissionDeniedCard
                    }

                    resultsSection
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

            Text(viewModel.screenTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Search Field

private extension LocationPickerView {

    var searchField: some View {
        HStack(spacing: .xSm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .customForeground(.onSurfaceVariant)

            TextField(viewModel.searchPlaceholder, text: $viewModel.searchQuery)
                .customStyle(.kitab(size: 15, bold: false), .onSurface)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(0.7)
            } else if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .customForeground(.outline)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .md)
        .padding(.vertical, 12)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerLg)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Current Location

private extension LocationPickerView {

    var currentLocationSection: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.currentLocationSectionTitle)
                .customStyle(.subheadline, .onSurface)

            VStack(spacing: .no) {
                selectedLocationRow

                Rectangle()
                    .fill(ColorStyle.outlineVariant.color)
                    .frame(height: 1)

                useDeviceLocationRow
            }
            .background(Color.cardSurface)
            .customCornerRadius(.cornerLg)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
        }
    }

    var selectedLocationRow: some View {
        HStack(spacing: .sm) {
            iconTile(systemName: "mappin.circle.fill")

            Text(viewModel.selectedLocationLabel)
                .customStyle(.kitab(size: 16, bold: false), .onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 0)

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .customForeground(.primary)
        }
        .padding(.horizontal, .md)
        .padding(.vertical, 14)
    }

    var useDeviceLocationRow: some View {
        Button(action: viewModel.onUseDeviceLocationTapped) {
            HStack(spacing: .sm) {
                iconTile(systemName: "location.fill")

                Text(viewModel.useDeviceLocationTitle)
                    .customStyle(.kitab(size: 16, bold: false), .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                if viewModel.isResolvingDeviceLocation {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 13, weight: .semibold))
                        .customForeground(.outline)
                }
            }
            .padding(.horizontal, .md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isResolvingDeviceLocation)
    }

    func iconTile(systemName: String) -> some View {
        RoundedRectangle(cornerRadius: .cornerMd, style: .continuous)
            .fill(ColorStyle.primary.color.opacity(0.14))
            .frame(width: 38, height: 38)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.primary)
            )
    }
}

// MARK: - Results

private extension LocationPickerView {

    @ViewBuilder
    var resultsSection: some View {
        if !viewModel.searchResults.isEmpty {
            VStack(alignment: .leading, spacing: .sm) {
                Text(viewModel.resultsSectionTitle)
                    .customStyle(.subheadline, .onSurface)

                resultsList
            }
        } else if viewModel.hasNoSearchResults {
            emptyResultsCard
        }
    }

    var resultsList: some View {
        VStack(spacing: .no) {
            ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { offset, item in
                if offset > 0 {
                    Rectangle()
                        .fill(ColorStyle.outlineVariant.color)
                        .frame(height: 1)
                }

                searchResultRow(item)
            }
        }
        .background(Color.cardSurface)
        .customCornerRadius(.cornerLg)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }

    func searchResultRow(_ item: LocationSearchResultItem) -> some View {
        Button {
            viewModel.onSearchResultSelected(item)
        } label: {
            HStack(spacing: .sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.cityName)
                        .customStyle(.kitab(size: 16, bold: false), .onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if !item.countryName.isEmpty {
                        Text(item.countryName)
                            .customStyle(.caption1, .onSurfaceVariant)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                if item.isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .customForeground(.primary)
                }
            }
            .padding(.horizontal, .md)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(item.isSelected ? [.isButton, .isSelected] : .isButton)
    }

    var emptyResultsCard: some View {
        HStack(spacing: .xSm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .customForeground(.onSurfaceVariant)

            Text(viewModel.noResultsTitle)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.md)
        .frame(maxWidth: .infinity)
        .background(ColorStyle.outlineVariant.color.opacity(0.18))
        .customCornerRadius(.cornerLg)
    }
}

// MARK: - Permission

private extension LocationPickerView {

    var permissionDeniedCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack(spacing: .xSm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .customForeground(.warning)

                Text(viewModel.permissionDeniedTitle)
                    .customStyle(.bodySmall, .onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: viewModel.onOpenDeviceSettingsTapped) {
                Text(viewModel.openSettingsTitle)
                    .customStyle(.buttonText, .primary)
                    .padding(.vertical, .xSm)
                    .padding(.horizontal, .md)
                    .background(ColorStyle.primary.color.opacity(0.08))
                    .customCornerRadius(.cornerMd)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .background(ColorStyle.warning.color.opacity(0.10))
        .customCornerRadius(.cornerLg)
    }
}
