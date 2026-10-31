//
//  KhatmahSetupView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahSetupView: View {

    @StateObject private var viewModel = KhatmahSetupViewModel()

    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension KhatmahSetupView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    paceCard
                    startCard
                    reminderCard
                    createButton
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
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.screenTitle)
                    .customStyle(.heading3, .onSurface)
                Text(viewModel.paceCaption)
                    .customStyle(.caption1, .subtitle)
            }

            Spacer(minLength: 0)

            Button(action: onCancel) {
                Text(viewModel.cancelActionTitle)
                    .customStyle(.caption1, .primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .md)
    }
}

// MARK: - Pace

private extension KhatmahSetupView {

    var paceCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.paceTitle)
                .customStyle(.headline, .onSurface)

            Picker(viewModel.paceTitle, selection: $viewModel.paceMode) {
                Text(viewModel.durationSectionTitle).tag(KhatmahPaceMode.duration)
                Text(viewModel.targetDateSectionTitle).tag(KhatmahPaceMode.targetDate)
            }
            .pickerStyle(.segmented)

            if viewModel.paceMode == .duration {
                durationPresets
            } else {
                targetDatePicker
            }

            paceSummary
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    var durationPresets: some View {
        NoIndicatorsScrollView(.horizontal) {
            HStack(spacing: .xSm) {
                ForEach(KhatmahDurationPreset.allCases) { preset in
                    presetChip(preset)
                }
            }
            .padding(.vertical, .xxSm)
        }
    }

    func presetChip(_ preset: KhatmahDurationPreset) -> some View {
        let isSelected = viewModel.selectedPreset == preset

        return Button {
            viewModel.selectPreset(preset)
        } label: {
            Text(viewModel.durationTitle(for: preset))
                .customStyle(.caption1, isSelected ? .onPrimary : .onSurface)
                .padding(.horizontal, .sm)
                .padding(.vertical, .xSm)
                .background(
                    RoundedRectangle(cornerRadius: .cornerSm)
                        .fill(isSelected
                              ? ColorStyle.quickAccentKhatmah.color
                              : ColorStyle.surfaceContainerLow.color)
                )
        }
        .buttonStyle(.plain)
    }

    var targetDatePicker: some View {
        DatePicker(
            viewModel.targetDateSectionTitle,
            selection: $viewModel.targetDate,
            in: viewModel.earliestTargetDate...,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .customStyle(.bodyMedium, .onSurface)
    }

    var paceSummary: some View {
        HStack(spacing: .xSm) {
            summaryChip(viewModel.totalDaysText)
            summaryChip(viewModel.pagesPerDayText)
        }
    }

    func summaryChip(_ text: String) -> some View {
        Text(text)
            .customStyle(.caption2, .quickAccentKhatmah)
            .padding(.horizontal, .xSm)
            .padding(.vertical, .xxSm)
            .background(ColorStyle.quickAccentKhatmah.color.opacity(0.12))
            .customCornerRadius(.cornerXxSm)
    }
}

// MARK: - Start

private extension KhatmahSetupView {

    var startCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.startTitle)
                .customStyle(.headline, .onSurface)

            DatePicker(
                viewModel.startDateTitle,
                selection: $viewModel.startDate,
                in: viewModel.earliestStartDate...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .customStyle(.bodyMedium, .onSurface)

            Divider()

            Text(viewModel.startPageTitle)
                .customStyle(.bodyMedium, .onSurface)

            Text(viewModel.startPageText)
                .customStyle(.caption1, .subtitle)

            startPagePicker
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    var startPagePicker: some View {
        Picker(viewModel.startPageTitle, selection: startPageSelection) {
            ForEach(KhatmahPageBounds.firstPage...KhatmahPageBounds.lastPage, id: \.self) { page in
                Text(viewModel.pageNumberText(for: page)).tag(page)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 110)
        .clipped()
    }

    var startPageSelection: Binding<Int> {
        Binding(
            get: { viewModel.startPage },
            set: viewModel.selectStartPage
        )
    }
}

// MARK: - Reminder

private extension KhatmahSetupView {

    var reminderCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.reminderSectionTitle)
                .customStyle(.headline, .onSurface)

            Toggle(isOn: $viewModel.isReminderEnabled) {
                Text(viewModel.reminderToggleTitle)
                    .customStyle(.bodyMedium, .onSurface)
            }
            .tint(ColorStyle.quickAccentKhatmah.color)

            if viewModel.isReminderEnabled {
                DatePicker(
                    viewModel.reminderTimeTitle,
                    selection: $viewModel.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .customStyle(.bodyMedium, .onSurface)
            }
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    var createButton: some View {
        Button {
            guard viewModel.createPlan() != nil else { return }
            onCreate()
        } label: {
            Text(viewModel.createActionTitle)
                .customStyle(.buttonText, .onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .background(
                    RoundedRectangle(cornerRadius: .cornerMd)
                        .fill(ColorStyle.quickAccentKhatmah.color)
                )
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdvance)
        .opacity(viewModel.canAdvance ? 1 : 0.5)
    }
}
