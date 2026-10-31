//
//  SettingsView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import SwiftUI
import Core

struct SettingsView: View {

    @StateObject private var viewModel: SettingsViewModel

    init(coordinator: any SettingsCoordinating) {
        _viewModel = StateObject(wrappedValue: SettingsViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .sheet(item: $viewModel.activeSheet, onDismiss: viewModel.onSheetDismissed) { sheet in
            sheetContent(for: sheet)
        }
    }
}

// MARK: - Layout

private extension SettingsView {

    var mainContent: some View {
        NoIndicatorsScrollView {
            VStack(alignment: .leading, spacing: .big) {
                profileHeader

                ForEach(viewModel.sections) { section in
                    settingsSection(section)
                }
            }
            .padding(.horizontal, .big)
            .padding(.top, .big)
            .padding(.bottom, .xxxBig)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }

    var profileHeader: some View {
        VStack(alignment: .leading, spacing: .md) {
            Text(viewModel.screenTitle)
                .customStyle(.kitab(size: 30, bold: true), .onSurface)

            HStack(spacing: .sm) {
                appMark

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.appTitle)
                        .customStyle(.kitab(size: 18, bold: true), .onSurface)

                    Text(viewModel.appTagline)
                        .customStyle(.kitab(size: 13, bold: false), .onSurfaceVariant)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: 0)
            }
            .padding(.md)
            .background(Color.cardSurface)
            .customCornerRadius(.cornerXl)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXl)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
        }
    }

    var appMark: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: [.avatarGradientStart, .avatarGradientEnd],
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )

            Text(viewModel.appInitial)
                .customStyle(.kitab(size: 24, bold: true), .onPrimary)
        }
        .frame(width: 54, height: 54)
    }

    func settingsSection(_ section: SettingsSection) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(section.title)
                .customStyle(.kitab(size: 13, bold: true), .onSurfaceVariant)
                .padding(.horizontal, .xSm)

            VStack(spacing: .no) {
                ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
                    SettingsRowView(item: row) {
                        viewModel.onRowTapped(row)
                    }

                    if index < section.rows.count - 1 {
                        rowDivider
                    }
                }
            }
            .background(Color.cardSurface)
            .customCornerRadius(.cornerXl)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXl)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
        }
    }

    var rowDivider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color)
            .frame(height: 0.5)
            .padding(.leading, 68)
    }
}

// MARK: - Sheets

private extension SettingsView {

    @ViewBuilder
    func sheetContent(for sheet: SettingsSheet) -> some View {
        switch sheet {
        case .quranPageSettings:
            QuranPageSettingsSheet()

        case .reciterLibrary:
            ReciterLibraryView()
                .environmentObject(AudioEngine.shared)

        case .appearance:
            SettingsAppearancePickerSheet(title: viewModel.appearanceSheetTitle,
                                          options: viewModel.appearanceOptions,
                                          onSelect: viewModel.selectAppearance)
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.hidden)

        case .language:
            SettingsLanguagePickerSheet(title: viewModel.languageSheetTitle,
                                        options: viewModel.languageOptions,
                                        onSelect: viewModel.selectLanguage)
                .presentationDetents([.height(260)])
                .presentationDragIndicator(.hidden)

        case .about:
            SettingsAboutSheet(title: viewModel.aboutSheetTitle,
                               appName: viewModel.appTitle,
                               appInitial: viewModel.appInitial,
                               tagline: viewModel.appTagline,
                               versionText: viewModel.versionText,
                               descriptionText: viewModel.aboutBody)
                .presentationDetents([.medium])
                .presentationDragIndicator(.hidden)
        }
    }
}

// MARK: - Prayer Notification Settings

struct PrayerNotificationSettingsView: View {

    @StateObject private var viewModel: PrayerNotificationSettingsViewModel

    init(coordinator: any PrayerNotificationSettingsCoordinating) {
        _viewModel = StateObject(wrappedValue: PrayerNotificationSettingsViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
        .sheet(item: $viewModel.activeSheet, onDismiss: viewModel.onSheetDismissed) { sheet in
            PrayerNotificationPickerSheet(title: viewModel.sheetTitle(for: sheet),
                                          options: viewModel.sheetOptions(for: sheet)) { identifier in
                viewModel.onSheetOptionSelected(sheet, optionIdentifier: identifier)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }
}

// MARK: - Prayer Notification Layout

private extension PrayerNotificationSettingsView {

    var mainContent: some View {
        VStack(spacing: .no) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    masterSection

                    if viewModel.isAuthorizationDenied {
                        deniedBanner
                    }

                    if viewModel.isNotificationEnabled {
                        prayersSection
                        voluntarySection
                        reminderSection
                        alertSection
                        inAppSection
                    }

                    calculationSection

                    if !viewModel.windowFooter.isEmpty {
                        Text(viewModel.windowFooter)
                            .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                            .padding(.horizontal, .xSm)
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, .xSm)
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

    var masterSection: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            card {
                PrayerNotificationToggleRow(title: viewModel.masterToggleTitle,
                                            caption: "",
                                            iconName: "bell.badge",
                                            isOn: viewModel.isNotificationEnabled,
                                            isEnabled: true,
                                            onChange: viewModel.setNotificationEnabled)
            }

            Text(viewModel.masterToggleCaption)
                .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                .padding(.horizontal, .xSm)
        }
    }

    var deniedBanner: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(viewModel.authorizationDeniedTitle)
                .customStyle(.kitab(size: 15, bold: true), .onSurface)

            Text(viewModel.authorizationDeniedBody)
                .customStyle(.kitab(size: 13, bold: false), .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: viewModel.onOpenSystemSettingsTapped) {
                Text(viewModel.openSystemSettingsTitle)
                    .customStyle(.kitab(size: 14, bold: true), .primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.md)
        .background(ColorStyle.warning.color.opacity(0.12))
        .customCornerRadius(.cornerXl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXl)
                .stroke(ColorStyle.warning.color.opacity(0.35), lineWidth: 1)
        )
    }

    var prayersSection: some View {
        section(viewModel.prayersSectionTitle) {
            slotRows(viewModel.obligatorySlots)
        }
    }

    var voluntarySection: some View {
        section(viewModel.voluntarySectionTitle) {
            slotRows(viewModel.voluntarySlots)
        }
    }

    var reminderSection: some View {
        section(viewModel.reminderSectionTitle) {
            PrayerNotificationToggleRow(title: viewModel.reminderToggleTitle,
                                        caption: "",
                                        iconName: "clock.badge",
                                        isOn: viewModel.isReminderEnabled,
                                        isEnabled: true,
                                        onChange: viewModel.setReminderEnabled)

            if viewModel.isReminderEnabled {
                rowDivider

                PrayerNotificationStepperRow(value: viewModel.reminderLeadText,
                                             canDecrease: viewModel.canDecreaseReminderLead,
                                             canIncrease: viewModel.canIncreaseReminderLead,
                                             onDecrease: viewModel.decreaseReminderLead,
                                             onIncrease: viewModel.increaseReminderLead)
            }
        }
    }

    var alertSection: some View {
        section(viewModel.alertSectionTitle) {
            ForEach(Array(viewModel.alertStyles.enumerated()), id: \.element.id) { index, item in
                PrayerNotificationAlertStyleRow(item: item) {
                    viewModel.selectAlertStyle(item.style)
                }

                if index < viewModel.alertStyles.count - 1 {
                    rowDivider
                }
            }
        }
    }

    var inAppSection: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            section(viewModel.inAppSectionTitle) {
                PrayerNotificationToggleRow(title: viewModel.inAppAdhanTitle,
                                            caption: "",
                                            iconName: "speaker.wave.3",
                                            isOn: viewModel.isInAppAdhanEnabled,
                                            isEnabled: viewModel.isInAppAdhanAvailable,
                                            onChange: viewModel.setInAppAdhanEnabled)
            }

            Text(viewModel.isInAppAdhanAvailable ? viewModel.inAppAdhanCaption : viewModel.inAppAdhanMissing)
                .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, .xSm)
        }
    }

    var calculationSection: some View {
        section(viewModel.calculationSectionTitle) {
            PrayerNotificationValueRow(title: viewModel.methodRowTitle,
                                       value: viewModel.methodValue,
                                       action: viewModel.onMethodRowTapped)

            rowDivider

            PrayerNotificationValueRow(title: viewModel.schoolRowTitle,
                                       value: viewModel.schoolValue,
                                       action: viewModel.onSchoolRowTapped)
        }
    }

    @ViewBuilder
    func slotRows(_ items: [PrayerNotificationSlotItem]) -> some View {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
            PrayerNotificationToggleRow(title: item.title,
                                        caption: item.caption,
                                        iconName: item.iconName,
                                        isOn: item.isOn,
                                        isEnabled: true,
                                        onChange: { viewModel.setSlotEnabled(item.slot, isEnabled: $0) })

            if index < items.count - 1 {
                rowDivider
            }
        }
    }

    func section<Content: View>(_ title: String,
                                @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(title)
                .customStyle(.kitab(size: 13, bold: true), .onSurfaceVariant)
                .padding(.horizontal, .xSm)

            card(content: content)
        }
    }

    func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: .no) {
            content()
        }
        .background(Color.cardSurface)
        .customCornerRadius(.cornerXl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }

    var rowDivider: some View {
        Rectangle()
            .fill(ColorStyle.outlineVariant.color)
            .frame(height: 0.5)
            .padding(.leading, 68)
    }
}

// MARK: - Prayer Notification Rows

struct PrayerNotificationToggleRow: View {

    let title: String
    let caption: String
    let iconName: String
    let isOn: Bool
    let isEnabled: Bool
    let onChange: (Bool) -> Void

    private var binding: Binding<Bool> {
        Binding(get: { isOn }, set: { onChange($0) })
    }

    var body: some View {
        Toggle(isOn: binding) {
            HStack(spacing: .sm) {
                PrayerNotificationIconTile(iconName: iconName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .customStyle(.kitab(size: 16, bold: false), .onSurface)

                    if !caption.isEmpty {
                        Text(caption)
                            .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .tint(ColorStyle.primary.color)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
    }
}

struct PrayerNotificationAlertStyleRow: View {

    let item: PrayerNotificationAlertStyleItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                PrayerNotificationIconTile(iconName: item.iconName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .customStyle(.kitab(size: 16, bold: item.isSelected), .onSurface)

                    Text(item.caption)
                        .customStyle(.kitab(size: 12, bold: false), .onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: .xSm)

                if item.isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .customForeground(.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
        }
        .buttonStyle(SettingsRowButtonStyle())
        .disabled(!item.isAvailable)
        .opacity(item.isAvailable ? 1 : 0.5)
        .accessibilityAddTraits(item.isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

struct PrayerNotificationValueRow: View {

    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                Text(title)
                    .customStyle(.kitab(size: 16, bold: false), .onSurface)

                Spacer(minLength: .xSm)

                Text(value)
                    .customStyle(.kitab(size: 14, bold: false), .onSurfaceVariant)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .customForeground(.outline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
        }
        .buttonStyle(SettingsRowButtonStyle())
    }
}

struct PrayerNotificationStepperRow: View {

    let value: String
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: .sm) {
            Text(value)
                .customStyle(.kitab(size: 15, bold: false), .onSurface)

            Spacer(minLength: .xSm)

            stepperButton(iconName: "minus", isEnabled: canDecrease, action: onDecrease)
            stepperButton(iconName: "plus", isEnabled: canIncrease, action: onIncrease)
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
    }

    func stepperButton(iconName: String,
                       isEnabled: Bool,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 13, weight: .semibold))
                .customForeground(.primary)
                .frame(width: 32, height: 32)
                .background(ColorStyle.primary.color.opacity(0.12))
                .customCornerRadius(.cornerMd)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

struct PrayerNotificationIconTile: View {

    let iconName: String

    var body: some View {
        RoundedRectangle(cornerRadius: .cornerMd, style: .continuous)
            .fill(ColorStyle.qiblaAccent.color.opacity(0.14))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.qiblaAccent)
            )
    }
}

// MARK: - Prayer Notification Picker Sheet

struct PrayerNotificationPickerSheet: View {

    let title: String
    let options: [SettingsOptionItem]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(spacing: .big) {
            SettingsSheetGrabber()

            Text(title)
                .customStyle(.kitab(size: 18, bold: true), .onSurface)

            NoIndicatorsScrollView {
                VStack(spacing: .no) {
                    ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                        Button {
                            onSelect(option.id)
                        } label: {
                            HStack(spacing: .sm) {
                                Text(option.title)
                                    .customStyle(.kitab(size: 16, bold: option.isSelected), .onSurface)
                                    .multilineTextAlignment(.leading)

                                Spacer(minLength: .xSm)

                                if option.isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .customForeground(.primary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, .md)
                            .padding(.vertical, .sm)
                        }
                        .buttonStyle(SettingsRowButtonStyle())
                        .accessibilityAddTraits(option.isSelected ? [.isButton, .isSelected] : .isButton)

                        if index < options.count - 1 {
                            Rectangle()
                                .fill(ColorStyle.outlineVariant.color)
                                .frame(height: 0.5)
                                .padding(.horizontal, .md)
                        }
                    }
                }
                .background(Color.cardSurface)
                .customCornerRadius(.cornerLg)
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerLg)
                        .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
                )
                .padding(.bottom, .big)
            }
        }
        .padding(.horizontal, .big)
        .padding(.top, .sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .customBackground(.background)
    }
}
