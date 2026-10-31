//
//  SettingsViewModel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 18/10/2026.
//

import UIKit
import Combine
import Core

enum SettingsDestination: String {
    case quranPageSettings
    case quranPacks
    case reciterLibrary
    case downloads
    case worshipTracker
    case prayerNotifications
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
    private var quranPacksSummary: String = ""
    private var downloadsSummary: String = ""
    private var prayerNotificationsSummary: String = ""

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
        case .quranPacks: coordinator?.coordinateToQuranPacks()
        case .reciterLibrary: activeSheet = .reciterLibrary
        case .downloads: coordinator?.coordinateToStorage()
        case .appearance: activeSheet = .appearance
        case .language: activeSheet = .language
        case .about: activeSheet = .about
        case .worshipTracker: coordinator?.coordinateToWorshipTracker()
        case .prayerNotifications: coordinator?.coordinateToPrayerNotifications()
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
        quranPacksSummary = makeQuranPacksSummary()
        prayerNotificationsSummary = makePrayerNotificationsSummary()

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

    func makeQuranPacksSummary() -> String {
        let store = QuranImagePackStore.shared
        let total = store.downloadablePacks.count
        guard total > 0 else { return "" }

        let missing = store.missingJuzs().count
        guard missing > 0 else { return AppLocalizedKeys.quranDownloadsAllDone.value }

        let isArabic = LocalizationManager.shared.currentLanguage == .Arabic
        let installed = total - missing
        return String(format: AppLocalizedKeys.quranDownloadsProgressFormat.value,
                      isArabic ? installed.arabicNumerals : "\(installed)",
                      isArabic ? total.arabicNumerals : "\(total)")
    }

    func makePrayerNotificationsSummary() -> String {
        let preferences = PrayerNotificationManager.shared.preferences
        guard preferences.isPrayerNotificationEnabled else {
            return AppLocalizedKeys.prayerNotificationsSummaryOff.value
        }

        let isArabic = localizationManager.currentLanguage == .Arabic
        let enabled = preferences.enabledSlots.count
        let total = PrayerSlot.allCases.count
        return String(format: AppLocalizedKeys.prayerNotificationsSummaryCountFormat.value,
                      isArabic ? enabled.arabicNumerals : "\(enabled)",
                      isArabic ? total.arabicNumerals : "\(total)")
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
                SettingsRowItem(id: "quranPacks",
                                destination: .quranPacks,
                                title: AppLocalizedKeys.quranDownloadsSettingsRow.value,
                                subtitle: quranPacksSummary,
                                iconName: "arrow.down.doc",
                                iconAccent: .quickAccentAdhkar),
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
                                iconAccent: .quickAccentWorship),
                SettingsRowItem(id: "prayerNotifications",
                                destination: .prayerNotifications,
                                title: AppLocalizedKeys.prayerNotificationsTitle.value,
                                subtitle: prayerNotificationsSummary,
                                iconName: "bell.badge",
                                iconAccent: .qiblaAccent)
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

// MARK: - Prayer Notification Items

struct PrayerNotificationSlotItem: Identifiable {
    let id: String
    let slot: PrayerSlot
    let title: String
    let caption: String
    let iconName: String
    let isOn: Bool
}

struct PrayerNotificationAlertStyleItem: Identifiable {
    let id: String
    let style: PrayerNotificationAlertStyle
    let title: String
    let caption: String
    let iconName: String
    let isSelected: Bool
    let isAvailable: Bool
}

enum PrayerNotificationSettingsSheet: String, Identifiable {
    case calculationMethod
    case jurisprudenceSchool

    var id: String { rawValue }
}

// MARK: - Prayer Notification View Model

@MainActor
final class PrayerNotificationSettingsViewModel: MainViewModel {

    @Published private(set) var isNotificationEnabled: Bool = false
    @Published private(set) var isAuthorizationDenied: Bool = false
    @Published private(set) var isAuthorizationPending: Bool = false
    @Published private(set) var obligatorySlots: [PrayerNotificationSlotItem] = []
    @Published private(set) var voluntarySlots: [PrayerNotificationSlotItem] = []
    @Published private(set) var isReminderEnabled: Bool = false
    @Published private(set) var reminderLeadText: String = ""
    @Published private(set) var canIncreaseReminderLead: Bool = false
    @Published private(set) var canDecreaseReminderLead: Bool = false
    @Published private(set) var alertStyles: [PrayerNotificationAlertStyleItem] = []
    @Published private(set) var isInAppAdhanEnabled: Bool = false
    @Published private(set) var isInAppAdhanAvailable: Bool = false
    @Published private(set) var methodValue: String = ""
    @Published private(set) var schoolValue: String = ""
    @Published private(set) var methodOptions: [SettingsOptionItem] = []
    @Published private(set) var schoolOptions: [SettingsOptionItem] = []
    @Published private(set) var windowFooter: String = ""
    @Published var activeSheet: PrayerNotificationSettingsSheet?

    var isTabBarVisible: Bool { false }

    private let manager = PrayerNotificationManager.shared
    private let localizationManager = LocalizationManager.shared
    private weak var coordinator: PrayerNotificationSettingsCoordinating?
    private var cancellables = Set<AnyCancellable>()

    init(coordinator: PrayerNotificationSettingsCoordinating) {
        self.coordinator = coordinator
        reloadNotificationState()
        observeNotificationManager()
    }

    func onAppear() {
        reloadNotificationState()
        Task { [manager] in
            await manager.refreshAuthorizationStatus()
        }
    }
}

// MARK: - Titles

extension PrayerNotificationSettingsViewModel {

    var screenTitle: String { AppLocalizedKeys.prayerNotificationsTitle.value }
    var masterToggleTitle: String { AppLocalizedKeys.prayerNotificationsMasterToggle.value }
    var masterToggleCaption: String { AppLocalizedKeys.prayerNotificationsMasterCaption.value }
    var authorizationDeniedTitle: String { AppLocalizedKeys.prayerNotificationsAuthorizationDeniedTitle.value }
    var authorizationDeniedBody: String { AppLocalizedKeys.prayerNotificationsAuthorizationDeniedBody.value }
    var openSystemSettingsTitle: String { AppLocalizedKeys.prayerNotificationsOpenSystemSettings.value }
    var enableAuthorizationTitle: String { AppLocalizedKeys.prayerNotificationsEnableAction.value }
    var prayersSectionTitle: String { AppLocalizedKeys.prayerNotificationsPrayersSection.value }
    var voluntarySectionTitle: String { AppLocalizedKeys.prayerNotificationsVoluntarySection.value }
    var reminderSectionTitle: String { AppLocalizedKeys.prayerNotificationsReminderSection.value }
    var reminderToggleTitle: String { AppLocalizedKeys.prayerNotificationsReminderToggle.value }
    var alertSectionTitle: String { AppLocalizedKeys.prayerNotificationsAlertSection.value }
    var inAppSectionTitle: String { AppLocalizedKeys.prayerNotificationsInAppSection.value }
    var inAppAdhanTitle: String { AppLocalizedKeys.prayerNotificationsInAppAdhanTitle.value }
    var inAppAdhanCaption: String { AppLocalizedKeys.prayerNotificationsInAppAdhanCaption.value }
    var inAppAdhanMissing: String { AppLocalizedKeys.prayerNotificationsInAppAdhanMissing.value }
    var calculationSectionTitle: String { AppLocalizedKeys.prayerNotificationsCalculationSection.value }
    var methodRowTitle: String { AppLocalizedKeys.prayerNotificationsMethodTitle.value }
    var schoolRowTitle: String { AppLocalizedKeys.prayerNotificationsSchoolTitle.value }
}

// MARK: - Actions

extension PrayerNotificationSettingsViewModel {

    func onBackTapped() {
        coordinator?.coordinateBack()
    }

    func setNotificationEnabled(_ isEnabled: Bool) {
        manager.updatePreferences { $0.isPrayerNotificationEnabled = isEnabled }
        guard isEnabled else { return }
        requestAuthorization()
    }

    func requestAuthorization() {
        Task { [manager] in
            await manager.requestAuthorization()
        }
    }

    func setSlotEnabled(_ slot: PrayerSlot, isEnabled: Bool) {
        manager.updatePreferences { preferences in
            if isEnabled {
                preferences.enabledSlots.insert(slot)
            } else {
                preferences.enabledSlots.remove(slot)
            }
        }
    }

    func setReminderEnabled(_ isEnabled: Bool) {
        manager.updatePreferences { $0.isPrePrayerReminderEnabled = isEnabled }
    }

    func increaseReminderLead() {
        changeReminderLead(by: PrayerNotificationPreferences.reminderLeadMinutesStep)
    }

    func decreaseReminderLead() {
        changeReminderLead(by: -PrayerNotificationPreferences.reminderLeadMinutesStep)
    }

    func selectAlertStyle(_ style: PrayerNotificationAlertStyle) {
        guard isAlertStyleAvailable(style) else { return }
        manager.updatePreferences { $0.alertStyle = style }
    }

    func setInAppAdhanEnabled(_ isEnabled: Bool) {
        manager.updatePreferences { $0.isInAppAdhanAudioEnabled = isEnabled }
    }

    func onMethodRowTapped() {
        activeSheet = .calculationMethod
    }

    func onSchoolRowTapped() {
        activeSheet = .jurisprudenceSchool
    }

    func selectMethod(_ optionIdentifier: String) {
        activeSheet = nil
        guard let identifier = Int(optionIdentifier),
              let method = PrayerCalculationMethod(rawValue: identifier) else { return }
        manager.updatePreferences { $0.calculationMethod = method }
    }

    func selectSchool(_ optionIdentifier: String) {
        activeSheet = nil
        guard let identifier = Int(optionIdentifier),
              let school = PrayerJurisprudenceSchool(rawValue: identifier) else { return }
        manager.updatePreferences { $0.jurisprudenceSchool = school }
    }

    func onOpenSystemSettingsTapped() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func onSheetDismissed() {
        reloadNotificationState()
    }
}

// MARK: - Sheet Titles

extension PrayerNotificationSettingsViewModel {

    func sheetTitle(for sheet: PrayerNotificationSettingsSheet) -> String {
        switch sheet {
        case .calculationMethod: return methodRowTitle
        case .jurisprudenceSchool: return schoolRowTitle
        }
    }

    func sheetOptions(for sheet: PrayerNotificationSettingsSheet) -> [SettingsOptionItem] {
        switch sheet {
        case .calculationMethod: return methodOptions
        case .jurisprudenceSchool: return schoolOptions
        }
    }

    func onSheetOptionSelected(_ sheet: PrayerNotificationSettingsSheet, optionIdentifier: String) {
        switch sheet {
        case .calculationMethod: selectMethod(optionIdentifier)
        case .jurisprudenceSchool: selectSchool(optionIdentifier)
        }
    }
}

// MARK: - Loading

private extension PrayerNotificationSettingsViewModel {

    func observeNotificationManager() {
        manager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadNotificationState()
            }
            .store(in: &cancellables)
    }

    func reloadNotificationState() {
        let preferences = manager.preferences
        let status = manager.authorizationStatus
        let leadMinutes = preferences.clampedReminderLeadMinutes

        isNotificationEnabled = preferences.isPrayerNotificationEnabled
        isAuthorizationDenied = status.isDenied
        isAuthorizationPending = preferences.isPrayerNotificationEnabled && status == .notDetermined
        obligatorySlots = PrayerSlot.obligatorySlots.map { slotItem(for: $0, preferences: preferences) }
        voluntarySlots = PrayerSlot.voluntarySlots.map { slotItem(for: $0, preferences: preferences) }
        isReminderEnabled = preferences.isPrePrayerReminderEnabled
        reminderLeadText = makeReminderLeadText(leadMinutes)
        canIncreaseReminderLead = leadMinutes < PrayerNotificationPreferences.reminderLeadMinutesRange.upperBound
        canDecreaseReminderLead = leadMinutes > PrayerNotificationPreferences.reminderLeadMinutesRange.lowerBound
        alertStyles = makeAlertStyles()
        isInAppAdhanEnabled = preferences.isInAppAdhanAudioEnabled
        isInAppAdhanAvailable = manager.isFullAdhanAudioAvailable
        methodValue = methodName(for: preferences.calculationMethod)
        schoolValue = schoolName(for: preferences.jurisprudenceSchool)
        methodOptions = makeMethodOptions(selected: preferences.calculationMethod)
        schoolOptions = makeSchoolOptions(selected: preferences.jurisprudenceSchool)
        windowFooter = makeWindowFooter()
    }

    func changeReminderLead(by delta: Int) {
        manager.updatePreferences { preferences in
            preferences.prePrayerReminderLeadMinutes = preferences.clampedReminderLeadMinutes + delta
        }
    }

    func isAlertStyleAvailable(_ style: PrayerNotificationAlertStyle) -> Bool {
        switch style {
        case .standardTone: return true
        case .shortAdhanTone: return manager.isShortAdhanToneAvailable
        }
    }

    func slotItem(for slot: PrayerSlot,
                  preferences: PrayerNotificationPreferences) -> PrayerNotificationSlotItem {
        PrayerNotificationSlotItem(id: slot.rawValue,
                                   slot: slot,
                                   title: slot.localizedName,
                                   caption: slotCaption(for: slot),
                                   iconName: slot.iconName,
                                   isOn: preferences.enabledSlots.contains(slot))
    }

    func slotCaption(for slot: PrayerSlot) -> String {
        switch slot {
        case .duha: return AppLocalizedKeys.prayerNotificationsDuhaCaption.value
        case .jumuah: return AppLocalizedKeys.prayerNotificationsJumuahCaption.value
        default: return ""
        }
    }

    func makeAlertStyles() -> [PrayerNotificationAlertStyleItem] {
        let effective = manager.effectiveAlertStyle
        let isShortToneAvailable = manager.isShortAdhanToneAvailable

        return [
            PrayerNotificationAlertStyleItem(id: PrayerNotificationAlertStyle.standardTone.rawValue,
                                             style: .standardTone,
                                             title: AppLocalizedKeys.prayerNotificationsStandardToneTitle.value,
                                             caption: AppLocalizedKeys.prayerNotificationsStandardToneCaption.value,
                                             iconName: "bell",
                                             isSelected: effective == .standardTone,
                                             isAvailable: true),
            PrayerNotificationAlertStyleItem(id: PrayerNotificationAlertStyle.shortAdhanTone.rawValue,
                                             style: .shortAdhanTone,
                                             title: AppLocalizedKeys.prayerNotificationsShortAdhanTitle.value,
                                             caption: isShortToneAvailable
                                                 ? AppLocalizedKeys.prayerNotificationsShortAdhanCaption.value
                                                 : AppLocalizedKeys.prayerNotificationsShortAdhanMissing.value,
                                             iconName: "speaker.wave.2",
                                             isSelected: effective == .shortAdhanTone,
                                             isAvailable: isShortToneAvailable)
        ]
    }

    func makeReminderLeadText(_ minutes: Int) -> String {
        String(format: AppLocalizedKeys.prayerNotificationsReminderLeadFormat.value,
               localizedNumber(minutes))
    }

    func makeWindowFooter() -> String {
        let count = manager.scheduledRequestCount
        guard count > 0 else { return "" }

        return String(format: AppLocalizedKeys.prayerNotificationsWindowFooterFormat.value,
                      localizedNumber(count),
                      localizedNumber(manager.scheduledWindowInDays))
    }

    func makeMethodOptions(selected: PrayerCalculationMethod) -> [SettingsOptionItem] {
        PrayerCalculationMethod.allCases.map { method in
            SettingsOptionItem(id: "\(method.rawValue)",
                               title: methodName(for: method),
                               iconName: nil,
                               accent: .qiblaAccent,
                               isSelected: method == selected)
        }
    }

    func makeSchoolOptions(selected: PrayerJurisprudenceSchool) -> [SettingsOptionItem] {
        PrayerJurisprudenceSchool.allCases.map { school in
            SettingsOptionItem(id: "\(school.rawValue)",
                               title: schoolName(for: school),
                               iconName: nil,
                               accent: .qiblaAccent,
                               isSelected: school == selected)
        }
    }

    func methodName(for method: PrayerCalculationMethod) -> String {
        AppLocalizedKeys.prayerCalculationMethodKey(forMethodId: method.rawValue)?.value ?? ""
    }

    func schoolName(for school: PrayerJurisprudenceSchool) -> String {
        switch school {
        case .standard: return AppLocalizedKeys.prayerSchoolStandard.value
        case .hanafi: return AppLocalizedKeys.prayerSchoolHanafi.value
        }
    }

    func localizedNumber(_ value: Int) -> String {
        localizationManager.currentLanguage == .Arabic ? value.arabicNumerals : "\(value)"
    }
}
