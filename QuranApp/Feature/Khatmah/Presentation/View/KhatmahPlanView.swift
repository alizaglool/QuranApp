//
//  KhatmahPlanView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahPlanView: View {

    @StateObject private var viewModel: KhatmahPlanViewModel

    init(coordinator: any KhatmahCoordinating) {
        _viewModel = StateObject(wrappedValue: KhatmahPlanViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension KhatmahPlanView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    if viewModel.hasPlan {
                        planContent
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
        .sheet(isPresented: $viewModel.isSetupPresented) {
            KhatmahSetupView(
                onCancel: { viewModel.isSetupPresented = false },
                onCreate: viewModel.onSetupFinished
            )
            .environmentObject(LocalizationManager.shared)
        }
        .alert(viewModel.deleteConfirmationTitle, isPresented: $viewModel.isDeleteConfirmationPresented) {
            Button(viewModel.cancelActionTitle, role: .cancel) {}
            Button(viewModel.deleteActionTitle, role: .destructive, action: viewModel.onDeleteConfirmed)
        } message: {
            Text(viewModel.deleteConfirmationMessage)
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

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.screenTitle)
                    .customStyle(.heading3, .onSurface)
                Text(viewModel.completedCountText)
                    .customStyle(.caption1, .subtitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    @ViewBuilder
    var planContent: some View {
        if viewModel.isPlanCompleted {
            completedCard
        }

        todayCard
        progressCard

        if viewModel.isAuthorizationDenied {
            authorizationDeniedCard
        }

        reminderCard
        daysCard
        deleteButton
    }
}

// MARK: - Empty

private extension KhatmahPlanView {

    var emptyCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            AccentIconTile(icon: "book.closed.fill", accent: .quickAccentKhatmah)

            Text(viewModel.emptyTitle)
                .customStyle(.headline, .onSurface)

            Text(viewModel.emptyMessage)
                .customStyle(.bodySmall, .subtitle)
                .fixedSize(horizontal: false, vertical: true)

            accentButton(title: viewModel.newPlanActionTitle, action: viewModel.onStartPlanTapped)
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    var completedCard: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            Text(viewModel.completedTitle)
                .customStyle(.headline, .success)

            Text(viewModel.completedMessage)
                .customStyle(.bodySmall, .subtitle)
                .fixedSize(horizontal: false, vertical: true)

            accentButton(title: viewModel.newPlanActionTitle, action: viewModel.onStartPlanTapped)
        }
        .padding(.md)
        .khatmahCardChrome()
    }
}

// MARK: - Today

private extension KhatmahPlanView {

    var todayCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack(spacing: .xSm) {
                Text(viewModel.todayTitle)
                    .customStyle(.headline, .onSurface)

                Spacer(minLength: 0)

                Text(viewModel.dayOfTotalText)
                    .customStyle(.caption2, .subtitle)
            }

            Text(viewModel.todayPageRange)
                .customStyle(.heading3, .quickAccentKhatmah)

            Text(viewModel.todayPageCount)
                .customStyle(.caption1, .subtitle)

            if !viewModel.todaySurahNames.isEmpty {
                Text(viewModel.todaySurahNames)
                    .customStyle(.caption1, .subtitle)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.hasStarted {
                todayActions
            } else {
                Text(viewModel.startsOnText)
                    .customStyle(.caption1, .warning)
            }
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    @ViewBuilder
    var todayActions: some View {
        HStack(spacing: .xSm) {
            accentButton(title: viewModel.readActionTitle, action: viewModel.onReadTodayTapped)

            if viewModel.isTodayCompleted {
                Label(viewModel.todayDoneTitle, systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .customStyle(.caption1, .success)
                    .frame(maxWidth: .infinity)
            } else {
                outlineButton(title: viewModel.markCompleteActionTitle,
                              action: viewModel.onMarkTodayCompleteTapped)
            }
        }
    }
}

// MARK: - Progress

private extension KhatmahPlanView {

    var progressCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.progressTitle)
                .customStyle(.headline, .onSurface)

            HStack(alignment: .center, spacing: .md) {
                KhatmahProgressRing(
                    fraction: viewModel.progressFraction,
                    percentText: viewModel.percentText,
                    caption: viewModel.progressTitle
                )

                VStack(alignment: .leading, spacing: .xSm) {
                    Text(viewModel.remainingPagesText)
                        .customStyle(.bodyMedium, .onSurface)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.expectedCompletionTitle)
                            .customStyle(.caption2, .subtitle)
                        Text(viewModel.expectedCompletionText)
                            .customStyle(.bodySmall, .onSurface)
                    }

                    Text(viewModel.driftText)
                        .customStyle(.caption2, viewModel.driftAccent)
                        .padding(.horizontal, .xSm)
                        .padding(.vertical, .xxSm)
                        .background(viewModel.driftAccent.color.opacity(0.12))
                        .customCornerRadius(.cornerXxSm)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(.md)
        .khatmahCardChrome()
    }
}

// MARK: - Reminder

private extension KhatmahPlanView {

    var reminderCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.reminderSectionTitle)
                .customStyle(.headline, .onSurface)

            Toggle(isOn: reminderEnabledSelection) {
                Text(viewModel.reminderToggleTitle)
                    .customStyle(.bodyMedium, .onSurface)
            }
            .tint(ColorStyle.quickAccentKhatmah.color)

            if viewModel.isReminderEnabled {
                DatePicker(
                    viewModel.reminderTimeTitle,
                    selection: reminderTimeSelection,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .customStyle(.bodyMedium, .onSurface)
            }
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    var authorizationDeniedCard: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            Text(viewModel.authorizationDeniedTitle)
                .customStyle(.bodyMedium, .warning)

            Text(viewModel.authorizationDeniedBody)
                .customStyle(.caption1, .subtitle)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: viewModel.onOpenSystemSettingsTapped) {
                Text(viewModel.openSystemSettingsTitle)
                    .customStyle(.caption1, .primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.md)
        .khatmahCardChrome()
    }

    var reminderEnabledSelection: Binding<Bool> {
        Binding(
            get: { viewModel.isReminderEnabled },
            set: viewModel.onReminderToggled
        )
    }

    var reminderTimeSelection: Binding<Date> {
        Binding(
            get: { viewModel.reminderTime },
            set: viewModel.onReminderTimeChanged
        )
    }
}

// MARK: - Days

private extension KhatmahPlanView {

    var daysCard: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(viewModel.daysSectionTitle)
                .customStyle(.headline, .onSurface)
                .padding(.horizontal, .md)
                .padding(.top, .md)

            LazyVStack(spacing: 0) {
                ForEach(viewModel.dayItems) { item in
                    KhatmahDayRow(item: item) {
                        viewModel.onDayTapped(item)
                    }

                    if item.id != viewModel.dayItems.last?.id {
                        Divider()
                            .padding(.horizontal, .md)
                    }
                }
            }
            .padding(.bottom, .xSm)
        }
        .khatmahCardChrome()
    }

    var deleteButton: some View {
        Button(action: viewModel.onDeleteTapped) {
            Text(viewModel.deleteActionTitle)
                .customStyle(.caption1, .error)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Buttons

private extension KhatmahPlanView {

    func accentButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .customStyle(.buttonText, .onPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .xSm)
                .background(
                    RoundedRectangle(cornerRadius: .cornerMd)
                        .fill(ColorStyle.quickAccentKhatmah.color)
                )
        }
        .buttonStyle(.plain)
    }

    func outlineButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .customStyle(.buttonText, .quickAccentKhatmah)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .xSm)
                .background(
                    RoundedRectangle(cornerRadius: .cornerMd)
                        .stroke(ColorStyle.quickAccentKhatmah.color, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
