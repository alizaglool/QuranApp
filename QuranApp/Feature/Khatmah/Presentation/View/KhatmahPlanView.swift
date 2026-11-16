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

    init(coordinator: any KhatmahCoordinating, viewModel: KhatmahPlanViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? KhatmahPlanViewModel(coordinator: coordinator))
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

            if viewModel.hasPlan {
                planScroll
            } else {
                emptyScroll
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
            .environment(\.layoutDirection, LocalizationManager.shared.currentLanguage.direction)
        }
        .alert(viewModel.deleteConfirmationTitle, isPresented: $viewModel.isDeleteConfirmationPresented) {
            Button(viewModel.cancelActionTitle, role: .cancel) {}
            Button(viewModel.deleteActionTitle, role: .destructive, action: viewModel.onDeleteConfirmed)
        } message: {
            Text(viewModel.deleteConfirmationMessage)
        }
    }

    var planScroll: some View {
        NoIndicatorsScrollView {
            VStack(alignment: .leading, spacing: .big) {
                planContent
            }
            .padding(.horizontal, .big)
            .padding(.top, .xSm)
            .padding(.bottom, .xxxBig)
        }
    }

    var emptyScroll: some View {
        GeometryReader { proxy in
            NoIndicatorsScrollView {
                emptyContent
                    .padding(.horizontal, .big)
                    .padding(.vertical, .xBig)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
            }
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
            .accessibilityLabel(viewModel.backActionTitle)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.screenTitle)
                    .customStyle(.heading3, .onSurface)

                if !viewModel.completedCountText.isEmpty {
                    Text(viewModel.completedCountText)
                        .customStyle(.caption1, .onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
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
        } else {
            todayCard
        }

        planRows
        deleteRow
    }
}

// MARK: - Today

private extension KhatmahPlanView {

    var todayCard: some View {
        KhatmahTodayCard(
            sectionTitle: viewModel.todayTitle,
            captionTracking: viewModel.captionTracking,
            statusText: viewModel.driftText,
            isBehindSchedule: viewModel.isBehindSchedule,
            percentText: viewModel.percentText,
            progressFraction: viewModel.progressFraction,
            dayOfTotalText: viewModel.dayOfTotalText,
            portionText: viewModel.todayPortionText,
            pageRangeText: viewModel.todayPageRangeText,
            metrics: viewModel.metrics,
            metricsAccessibilityLabel: viewModel.metricsAccessibilityLabel,
            hasStarted: viewModel.hasStarted,
            startsOnText: viewModel.startsOnText,
            isTodayCompleted: viewModel.isTodayCompleted,
            todayDoneTitle: viewModel.todayDoneTitle,
            readActionTitle: viewModel.readActionTitle,
            markCompleteActionTitle: viewModel.markCompleteActionTitle,
            onReadTapped: viewModel.onReadTodayTapped,
            onMarkCompleteTapped: viewModel.onMarkTodayCompleteTapped
        )
    }
}

// MARK: - Rows

private extension KhatmahPlanView {

    var planRows: some View {
        VStack(spacing: .no) {
            KhatmahSettingRow(
                icon: "list.bullet",
                accent: .primary,
                title: viewModel.allDaysText,
                detail: viewModel.todayWorkloadText,
                action: viewModel.onAllDaysTapped
            ) {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .customForeground(.outline)
            }

            if !viewModel.isPlanCompleted {
                rowDivider

                KhatmahSettingRow(
                    icon: "bell.fill",
                    accent: .secondary,
                    title: viewModel.reminderToggleTitle
                ) {
                    Toggle("", isOn: reminderEnabledSelection)
                        .labelsHidden()
                        .tint(ColorStyle.primary.color)
                }

                if viewModel.isReminderEnabled {
                    rowDivider

                    KhatmahSettingRow(
                        icon: "clock",
                        accent: .secondary,
                        title: viewModel.reminderTimeTitle
                    ) {
                        DatePicker("", selection: reminderTimeSelection, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .environment(\.locale, viewModel.pickerLocale)
                            .environment(\.timeZone, viewModel.pickerTimeZone)
                    }
                }

                if viewModel.isAuthorizationDenied {
                    rowDivider
                    authorizationDeniedNotice
                }
            }
        }
        .modifier(KhatmahRowGroup())
        .animation(.easeInOut(duration: 0.2), value: viewModel.isReminderEnabled)
    }

    var deleteRow: some View {
        KhatmahSettingRow(
            icon: "trash",
            accent: .error,
            title: viewModel.deleteActionTitle,
            action: viewModel.onDeleteTapped
        ) {
            EmptyView()
        }
        .modifier(KhatmahRowGroup())
    }

    var rowDivider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color)
            .frame(height: 0.5)
            .padding(.leading, 68)
    }

    var authorizationDeniedNotice: some View {
        VStack(alignment: .leading, spacing: .xxSm) {
            Text(viewModel.authorizationDeniedBody)
                .customStyle(.caption1, .warning)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: viewModel.onOpenSystemSettingsTapped) {
                Text(viewModel.openSystemSettingsTitle)
                    .customStyle(.caption1, .primary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 68)
        .padding(.trailing, .md)
        .padding(.vertical, .sm)
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

// MARK: - Empty

private extension KhatmahPlanView {

    var emptyContent: some View {
        VStack(spacing: .big) {
            VStack(spacing: .xSm) {
                Image(systemName: "book.closed")
                    .font(.system(size: 42, weight: .light))
                    .customForeground(.onSurfaceVariant)

                Text(viewModel.emptyTitle)
                    .customStyle(.heading3, .onSurface)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.emptyMessage)
                    .customStyle(.bodySmall, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, .xxSm)

            howItWorksCard

            primaryButton(title: viewModel.newPlanActionTitle, action: viewModel.onStartPlanTapped)
        }
    }

    var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.howItWorksTitle)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(viewModel.captionTracking)

            ForEach(Array(viewModel.howItWorksSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: .sm) {
                    Text(viewModel.stepNumberText(index + 1))
                        .customStyle(.caption1, .primary)
                        .monospacedDigit()
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(ColorStyle.washPrimary.color))

                    Text(step)
                        .customStyle(.bodySmall, .onSurface)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.big)
        .khatmahCardChrome()
    }

    var completedCard: some View {
        VStack(alignment: .leading, spacing: .md) {
            HStack(spacing: .sm) {
                AccentIconTile(icon: "checkmark.seal.fill", accent: .primary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.completedTitle)
                        .customStyle(.kitab(size: 17, bold: true), .onSurface)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(viewModel.percentText)
                        .customStyle(.caption1, .primary)
                        .monospacedDigit()
                }

                Spacer(minLength: 0)
            }

            Text(viewModel.completedMessage)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)

            primaryButton(title: viewModel.newPlanActionTitle, action: viewModel.onStartPlanTapped)
        }
        .padding(.big)
        .khatmahCardChrome()
    }
}

// MARK: - Buttons

private extension KhatmahPlanView {

    func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .customStyle(.buttonText, .onPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .background(Capsule().fill(ColorStyle.primary.color))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Row Group

private struct KhatmahRowGroup: ViewModifier {

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardSurface)
            .customCornerRadius(.cornerXl)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXl, style: .continuous)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
    }
}
