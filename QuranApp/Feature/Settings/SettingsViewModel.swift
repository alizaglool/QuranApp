//
//  SettingsViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import UIKit
import Core

enum SettingsDestination: String {
    case quranPageSettings
    case reciterLibrary
    case downloads
    case worshipTracker
    case appearance
    case language
    case about
}

enum SettingsSheet: String, Identifiable {
    case quranPageSettings
    case reciterLibrary
    case appearance
    case language
    case about

    var id: String { rawValue }
}

struct SettingsRowItem: Identifiable {
    let id: String
    let destination: SettingsDestination
    let title: String
    let subtitle: String
    let iconName: String
    let iconAccent: ColorStyle
}

struct SettingsSection: Identifiable {
    let id: String
    let title: String
    let rows: [SettingsRowItem]
}

struct SettingsOptionItem: Identifiable {
    let id: String
    let title: String
    let iconName: String?
    let accent: ColorStyle
    let isSelected: Bool
}

@MainActor
final class SettingsViewModel: MainViewModel {

    @Published private(set) var sections: [SettingsSection] = []
    @Published private(set) var appearanceOptions: [SettingsOptionItem] = []
    @Published private(set) var languageOptions: [SettingsOptionItem] = []
    @Published var activeSheet: SettingsSheet?

    private let storage = StorageManager.shared
    private let localizationManager = LocalizationManager.shared
    private weak var coordinator: SettingsCoordinating?

    private var selectedReciterName: String = ""
    private var downloadsSummary: String = ""

    init(coordinator: SettingsCoordinating) {
        self.coordinator = coordinator
        reloadSettingsState()
    }

    func onAppear() {
        reloadSettingsState()
        refreshStorageSummary()
    }
}

// MARK: - Titles

extension SettingsViewModel {

    var screenTitle: String { AppLocalizedKeys.settings.value }
    var appTitle: String { AppLocalizedKeys.appName.value }
    var appTagline: String { AppLocalizedKeys.settingsAppTagline.value }
    var appInitial: String { String(appTitle.prefix(1)) }
    var appearanceSheetTitle: String { AppLocalizedKeys.appearance.value }
    var languageSheetTitle: String { AppLocalizedKeys.settingsLanguageTitle.value }
    var aboutSheetTitle: String { AppLocalizedKeys.settingsAboutTitle.value }
    var aboutBody: String { AppLocalizedKeys.settingsAboutBody.value }

    var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return String(format: AppLocalizedKeys.settingsAboutVersionFormat.value, version)
    }
}

// MARK: - Actions

extension SettingsViewModel {

    func onRowTapped(_ row: SettingsRowItem) {
        switch row.destination {
        case .quranPageSettings: activeSheet = .quranPageSettings
        case .reciterLibrary: activeSheet = .reciterLibrary
        case .downloads: coordinator?.coordinateToStorage()
        case .appearance: activeSheet = .appearance
        case .language: activeSheet = .language
        case .about: activeSheet = .about
        case .worshipTracker: coordinator?.coordinateToWorshipTracker()
        }
    }

    func onSheetDismissed() {
        reloadSettingsState()
    }

    func selectAppearance(_ optionIdentifier: String) {
        storage.updateSettings { $0.themeMode = optionIdentifier }
        applyInterfaceStyle(for: optionIdentifier)
        reloadSettingsState()
        dismissSheetAfterSelection()
    }

    func selectLanguage(_ optionIdentifier: String) {
        guard let language = LocalizationManager.Language(rawValue: optionIdentifier),
              language != localizationManager.currentLanguage else {
            activeSheet = nil
            return
        }
        activeSheet = nil
        localizationManager.setLanguage(language, fromTabBar: true)
    }
}

// MARK: - Interface Style

private extension SettingsViewModel {

    func dismissSheetAfterSelection() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 240_000_000)
            activeSheet = nil
        }
    }

    func applyInterfaceStyle(for optionIdentifier: String) {
        let style: UIUserInterfaceStyle
        switch optionIdentifier {
        case "light": style = .light
        case "dark": style = .dark
        default: style = .unspecified
        }

        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}

// MARK: - Loading

private extension SettingsViewModel {

    func reloadSettingsState() {
        let settings = storage.getSettings()

        selectedReciterName = settings?.selectedReciterName ?? ""
        downloadsSummary = makeDownloadsSummary()

        sections = [
            quranSection,
            worshipSection,
            generalSection(themeMode: settings?.themeMode ?? "system"),
            moreSection
        ]

        appearanceOptions = makeAppearanceOptions(themeMode: settings?.themeMode ?? "system")
        languageOptions = makeLanguageOptions()
    }

    func refreshStorageSummary() {
        let previous = StorageScanner.cachedTotalBytes
        Task { [weak self] in
            let scan = await StorageScanner.scan()
            guard let self, scan.totalBytes != previous else { return }
            self.reloadSettingsState()
        }
    }

    func makeDownloadsSummary() -> String {
        let usedBytes = StorageScanner.cachedTotalBytes
        guard usedBytes > 0 else { return AppLocalizedKeys.settingsDownloadsEmpty.value }

        let used = ByteCountFormatter.string(fromByteCount: usedBytes, countStyle: .file)
        return String(format: AppLocalizedKeys.settingsDownloadsUsedFormat.value, used)
    }

    var quranSection: SettingsSection {
        SettingsSection(
            id: "quran",
            title: AppLocalizedKeys.settingsSectionQuran.value,
            rows: [
                SettingsRowItem(id: "quranPage",
                                destination: .quranPageSettings,
                                title: AppLocalizedKeys.mushafSettings.value,
                                subtitle: AppLocalizedKeys.settingsQuranPageSubtitle.value,
                                iconName: "book.pages",
                                iconAccent: .quickAccentQuran),
                SettingsRowItem(id: "reciters",
                                destination: .reciterLibrary,
                                title: AppLocalizedKeys.reciters.value,
                                subtitle: selectedReciterName,
                                iconName: "waveform",
                                iconAccent: .quickAccentRecitations),
                SettingsRowItem(id: "downloads",
                                destination: .downloads,
                                title: AppLocalizedKeys.storageManagement.value,
                                subtitle: downloadsSummary,
                                iconName: "arrow.down.circle",
                                iconAccent: .quickAccentRadio)
            ]
        )
    }

    var worshipSection: SettingsSection {
        SettingsSection(
            id: "worship",
            title: AppLocalizedKeys.settingsSectionWorship.value,
            rows: [
                SettingsRowItem(id: "worshipTracker",
                                destination: .worshipTracker,
                                title: AppLocalizedKeys.worshipTracker.value,
                                subtitle: AppLocalizedKeys.settingsWorshipSubtitle.value,
                                iconName: "checkmark.seal",
                                iconAccent: .quickAccentWorship)
            ]
        )
    }

    func generalSection(themeMode: String) -> SettingsSection {
        SettingsSection(
            id: "general",
            title: AppLocalizedKeys.settingsSectionGeneral.value,
            rows: [
                SettingsRowItem(id: "appearance",
                                destination: .appearance,
                                title: AppLocalizedKeys.appearance.value,
                                subtitle: appearanceTitle(for: themeMode),
                                iconName: "circle.lefthalf.filled",
                                iconAccent: .secondary),
                SettingsRowItem(id: "language",
                                destination: .language,
                                title: AppLocalizedKeys.settingsLanguageTitle.value,
                                subtitle: currentLanguageTitle,
                                iconName: "globe",
                                iconAccent: .quickAccentHadith)
            ]
        )
    }

    var moreSection: SettingsSection {
        SettingsSection(
            id: "more",
            title: AppLocalizedKeys.settingsSectionMore.value,
            rows: [
                SettingsRowItem(id: "about",
                                destination: .about,
                                title: AppLocalizedKeys.settingsAboutTitle.value,
                                subtitle: versionText,
                                iconName: "info.circle",
                                iconAccent: .quickAccentLessons)
            ]
        )
    }
}

// MARK: - Options

private extension SettingsViewModel {

    func appearanceTitle(for themeMode: String) -> String {
        switch themeMode {
        case "light": return AppLocalizedKeys.lightAppearance.value
        case "dark": return AppLocalizedKeys.darkAppearance.value
        default: return AppLocalizedKeys.systemAppearance.value
        }
    }

    var currentLanguageTitle: String {
        localizationManager.currentLanguage == .Arabic
            ? AppLocalizedKeys.settingsLanguageArabic.value
            : AppLocalizedKeys.settingsLanguageEnglish.value
    }

    func makeAppearanceOptions(themeMode: String) -> [SettingsOptionItem] {
        [
            SettingsOptionItem(id: "light",
                               title: AppLocalizedKeys.lightAppearance.value,
                               iconName: "sun.max.fill",
                               accent: .quickAccentLessons,
                               isSelected: themeMode == "light"),
            SettingsOptionItem(id: "dark",
                               title: AppLocalizedKeys.darkAppearance.value,
                               iconName: "moon.fill",
                               accent: .quickAccentAdhkar,
                               isSelected: themeMode == "dark"),
            SettingsOptionItem(id: "system",
                               title: AppLocalizedKeys.systemAppearance.value,
                               iconName: "circle.lefthalf.filled",
                               accent: .secondary,
                               isSelected: themeMode != "light" && themeMode != "dark")
        ]
    }

    func makeLanguageOptions() -> [SettingsOptionItem] {
        let current = localizationManager.currentLanguage
        return [
            SettingsOptionItem(id: LocalizationManager.Language.Arabic.rawValue,
                               title: AppLocalizedKeys.settingsLanguageArabic.value,
                               iconName: nil,
                               accent: .quickAccentQuran,
                               isSelected: current == .Arabic),
            SettingsOptionItem(id: LocalizationManager.Language.English.rawValue,
                               title: AppLocalizedKeys.settingsLanguageEnglish.value,
                               iconName: nil,
                               accent: .quickAccentHadith,
                               isSelected: current == .English)
        ]
    }
}
