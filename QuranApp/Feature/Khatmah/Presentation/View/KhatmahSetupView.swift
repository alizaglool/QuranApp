//
//  KhatmahSetupView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahSetupView: View {

    @StateObject private var viewModel: KhatmahSetupViewModel

    private let onCancel: () -> Void
    private let onCreate: () -> Void

    init(viewModel: KhatmahSetupViewModel? = nil,
         onCancel: @escaping () -> Void,
         onCreate: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel ?? KhatmahSetupViewModel())
        self.onCancel = onCancel
        self.onCreate = onCreate
    }

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
            stepIndicator

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    stepHeader

                    switch viewModel.step {
                    case .pace:
                        paceCard
                    case .startingPoint:
                        startingPointStep
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, .md)
                .padding(.bottom, .xBig)
            }
            .animation(.easeInOut(duration: 0.25), value: viewModel.step)

            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }

    var navBar: some View {
        HStack(spacing: 10) {
            if viewModel.step == .startingPoint {
                Button(action: viewModel.onBackTapped) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 15, weight: .semibold))
                        .customForeground(.primary)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel(viewModel.backActionTitle)
            }

            Text(viewModel.screenTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)

            Button(action: onCancel) {
                Text(viewModel.cancelActionTitle)
                    .customStyle(.caption1, .primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    var stepIndicator: some View {
        HStack(spacing: .xxSm) {
            ForEach(KhatmahSetupStep.allCases) { step in
                Capsule()
                    .fill(step.rawValue <= viewModel.step.rawValue
                          ? ColorStyle.primary.color
                          : ColorStyle.outlineVariant.color.opacity(0.25))
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, .big)
        .animation(.easeInOut(duration: 0.25), value: viewModel.step)
    }

    var stepHeader: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            Text(viewModel.stepText)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(viewModel.captionTracking)

            Text(viewModel.stepTitle)
                .customStyle(.heading3, .onSurface)

            Text(viewModel.stepCaption)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var footer: some View {
        VStack(spacing: 0) {
            rowDivider

            primaryButton
                .padding(.horizontal, .big)
                .padding(.top, .sm)
                .padding(.bottom, .xSm)
        }
        .background(ColorStyle.background.color)
    }
}

// MARK: - Pace

private extension KhatmahSetupView {

    var paceCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            DatePicker(
                viewModel.startDateTitle,
                selection: $viewModel.startDate,
                in: viewModel.earliestStartDate...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .customStyle(.subheadline, .onSurface)
            .environment(\.locale, viewModel.pickerLocale)
            .environment(\.timeZone, viewModel.pickerTimeZone)

            rowDivider

            Picker(viewModel.paceSegmentTitle, selection: $viewModel.paceMode) {
                Text(viewModel.durationSectionTitle).tag(KhatmahPaceMode.duration)
                Text(viewModel.targetDateSectionTitle).tag(KhatmahPaceMode.targetDate)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, .xxSm)

            if viewModel.paceMode == .duration {
                durationOptions
            } else {
                targetDatePicker
                paceSummary
            }
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    var durationOptions: some View {
        VStack(spacing: 0) {
            ForEach(KhatmahDurationPreset.allCases) { preset in
                KhatmahSelectableRow(
                    title: viewModel.durationTitle(for: preset),
                    detail: viewModel.workloadText(for: preset),
                    isSelected: viewModel.selectedPreset == preset
                ) {
                    viewModel.selectPreset(preset)
                }

                if preset != KhatmahDurationPreset.allCases.last {
                    rowDivider
                }
            }
        }
    }

    var targetDatePicker: some View {
        DatePicker(
            viewModel.lastDayTitle,
            selection: $viewModel.targetDate,
            in: viewModel.earliestTargetDate...,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .customStyle(.subheadline, .onSurface)
        .environment(\.locale, viewModel.pickerLocale)
        .environment(\.timeZone, viewModel.pickerTimeZone)
    }

    var paceSummary: some View {
        Text(viewModel.paceSummaryText)
            .customStyle(.caption1, .onSurfaceVariant)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Starting Point

private extension KhatmahSetupView {

    var startingPointStep: some View {
        VStack(alignment: .leading, spacing: .md) {
            startOptionsCard
            reminderCard
        }
    }

    var startOptionsCard: some View {
        VStack(spacing: 0) {
            KhatmahSelectableRow(
                title: viewModel.juzSelectionTitle,
                detail: viewModel.juzSelectionDetailText,
                isSelected: viewModel.isJuzSelected,
                action: viewModel.toggleJuzPicker
            )

            if viewModel.isJuzPickerExpanded {
                juzPicker
            }

            rowDivider

            KhatmahSelectableRow(
                title: viewModel.customPageTitle,
                detail: viewModel.customPageDetailText,
                isSelected: viewModel.isCustomPageSelected,
                action: viewModel.toggleCustomPage
            )

            if viewModel.isCustomPageExpanded {
                startPagePicker
            }
        }
        .padding(.md)
        .khatmahCardChrome()
        .animation(.easeInOut(duration: 0.25), value: viewModel.isJuzPickerExpanded)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isCustomPageExpanded)
    }

    var juzPicker: some View {
        Picker(viewModel.juzPickerTitle, selection: juzPageSelection) {
            ForEach(viewModel.startOptions) { option in
                Text(option.title).tag(option.page)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 110)
        .clipped()
    }

    var juzPageSelection: Binding<Int> {
        Binding(
            get: { viewModel.selectedJuzOption?.page ?? KhatmahPageBounds.firstPage },
            set: viewModel.selectStartPage
        )
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

    var reminderCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Toggle(isOn: $viewModel.isReminderEnabled) {
                Text(viewModel.reminderToggleTitle)
                    .customStyle(.subheadline, .onSurface)
            }
            .tint(ColorStyle.primary.color)

            if viewModel.isReminderEnabled {
                rowDivider

                DatePicker(
                    viewModel.reminderTimeTitle,
                    selection: $viewModel.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .customStyle(.subheadline, .onSurface)
                .environment(\.locale, viewModel.pickerLocale)
                .environment(\.timeZone, viewModel.pickerTimeZone)
            }
        }
        .padding(.md)
        .khatmahCardChrome()
    }
}

// MARK: - Shared

private extension KhatmahSetupView {

    var rowDivider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color)
            .frame(height: 0.5)
    }

    var primaryButton: some View {
        Button(action: onPrimaryTapped) {
            Text(viewModel.primaryActionTitle)
                .customStyle(.buttonText, .onPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .background(Capsule().fill(ColorStyle.primary.color))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canAdvance)
        .opacity(viewModel.canAdvance ? 1 : 0.45)
    }

    func onPrimaryTapped() {
        guard viewModel.isFinalStep else {
            viewModel.onPrimaryTapped()
            return
        }

        guard viewModel.onPrimaryTapped() != nil else { return }
        onCreate()
    }
}
