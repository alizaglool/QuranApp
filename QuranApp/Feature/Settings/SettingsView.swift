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
