//
//  SettingsView.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - SettingsView

struct SettingsView: View {

    @ObservedObject private var storage = StorageManager.shared
    @State private var showQuranSettings = false
    @State private var showReciterLibrary = false
    @State private var showStorageManagement = false
    @State private var showAppearancePicker = false
    @State private var showLanguagePicker = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                        .padding(.horizontal, 20)

                    quranSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    generalSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                    aboutSection
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                }
            }
            .customBackground(.background)
            .navigationTitle(AppLocalizedKeys.settings.value)
            .navigationBarTitleDisplayMode(.large)
            .appDirection()
        }
        .sheet(isPresented: $showQuranSettings) {
            QuranPageSettingsSheet()
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showReciterLibrary) {
            NavigationStack {
                ReciterLibraryView()
                    .environmentObject(AudioEngine.shared)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showStorageManagement) {
            NavigationStack {
                StorageManagementView()
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAppearancePicker) {
            AppearancePickerSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Profile Header

extension SettingsView {

    private var profileHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#78C262"), Color(hex: "#5BAA49")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Text("و")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .trailing, spacing: 3) {
                Text("وِرد")
                    .customStyle(.heading3, .onSurface)
                Text("تطبيقك الإسلامي اليومي")
                    .customStyle(.caption1, .subtitle)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// MARK: - Sections

extension SettingsView {

    private var quranSection: some View {
        VStack(spacing: 8) {
            sectionLabel("القرآن والتلاوة")
            settingsGroup {
                settingsRow(
                    image: "quranThumbnail",
                    title: "إعدادات القرآن",
                    subtitle: "المصحف، التمرير، السمة",
                    action: { showQuranSettings = true }
                )
                rowDivider
                settingsRow(
                    image: "fontButton",
                    title: "التلاوة والقرّاء",
                    subtitle: selectedReciterName,
                    action: { showReciterLibrary = true }
                )
                rowDivider
                settingsRow(
                    image: "storageThumbnail",
                    title: "إدارة التخزين",
                    subtitle: storageSummary,
                    action: { showStorageManagement = true }
                )
            }
        }
    }

    private var generalSection: some View {
        VStack(spacing: 8) {
            sectionLabel("عام")
            settingsGroup {
                settingsRow(
                    image: "darkModeThumbnail",
                    title: "المظهر",
                    subtitle: currentAppearanceLabel,
                    action: { showAppearancePicker = true }
                )
                rowDivider
                settingsRow(
                    image: "languageThumbnail",
                    title: "اللغة",
                    subtitle: "العربية",
                    action: {}
                )
                rowDivider
                settingsRow(
                    image: "remindersThumbnail",
                    title: "التذكيرات",
                    subtitle: "إشعارات مواقيت الصلاة",
                    action: {}
                )
                rowDivider
                settingsRow(
                    image: "appIconThumbnail",
                    title: "أيقونة التطبيق",
                    subtitle: "تخصيص أيقونة الشاشة الرئيسية",
                    action: {}
                )
            }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            sectionLabel("المزيد")
            settingsGroup {
                settingsRow(
                    image: "aboutThumbnail",
                    title: "حول التطبيق",
                    subtitle: "الإصدار 1.0.0",
                    action: { showAbout = true }
                )
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .customStyle(.kitab(size: 13, bold: true), .subtitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

// MARK: - Row Builders

extension SettingsView {

    private func settingsGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.surfaceContainer, in: RoundedRectangle(cornerRadius: 16))
    }

    // In RTL env: .leading = right edge, .trailing = left edge.
    // Divider inset from the right (behind the thumbnail).
    private var rowDivider: some View {
        Rectangle()
            .fill(Color.outlineVariant.opacity(0.3))
            .frame(height: 0.5)
            .padding(.leading, 82)
    }

    private func settingsRow(
        image: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            // In RTL: first item is on the RIGHT, last item is on the LEFT.
            HStack(spacing: 14) {
                // Thumbnail — rightmost (leading in RTL)
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                // Text stack fills the middle
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .customStyle(.kitab(size: 15, bold: true), .onSurface)
                    Text(subtitle)
                        .customStyle(.kitab(size: 12), .subtitle)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Chevron — leftmost (trailing in RTL); auto-mirrors to point left
                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.outlineVariant)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Computed Properties

extension SettingsView {

    private var selectedReciterName: String {
        storage.getSettings()?.selectedReciterName ?? "مشاري العفاسي"
    }

    private var storageSummary: String {
        let total = DownloadManager.shared.totalStorageUsedMB()
        if total < 1 {
            return "لا توجد تلاوات محمّلة"
        }
        return String(format: "%.0f MB محمّل", total)
    }

    private var currentAppearanceLabel: String {
        let mode = storage.getSettings()?.themeMode ?? "system"
        switch mode {
        case "light": return "فاتح"
        case "dark":  return "داكن"
        default:      return "تلقائي (النظام)"
        }
    }
}

// MARK: - Appearance Picker Sheet

private struct AppearancePickerSheet: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = StorageManager.shared
    @State private var selected: String = "system"

    var body: some View {
        VStack(spacing: 0) {
            handle

            Text("المظهر")
                .customStyle(.kitab(size: 17, bold: true), .onSurface)
                .padding(.top, 4)
                .padding(.bottom, 20)

            HStack(spacing: 12) {
                appearanceOption(value: "light",  label: "فاتح",   icon: "sun.max.fill",  color: .yellow)
                appearanceOption(value: "dark",   label: "داكن",   icon: "moon.fill",     color: .indigo)
                appearanceOption(value: "system", label: "تلقائي", icon: "circle.lefthalf.filled", color: .gray)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.surfaceContainer)
        .appDirection()
        .onAppear { selected = storage.getSettings()?.themeMode ?? "system" }
    }

    private var handle: some View {
        Capsule()
            .fill(Color.outlineVariant.opacity(0.5))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
            .padding(.bottom, 16)
    }

    private func appearanceOption(value: String, label: String, icon: String, color: Color) -> some View {
        let isSelected = selected == value
        return Button {
            selected = value
            applyTheme(value)
            storage.updateSettings { $0.themeMode = value }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { dismiss() }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? color.opacity(0.15) : Color.background)
                        .frame(width: 70, height: 70)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? color : Color.outlineVariant.opacity(0.3), lineWidth: isSelected ? 2 : 0.5)
                        )

                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(isSelected ? color : Color.outlineVariant)
                }

                Text(label)
                    .customStyle(.kitab(size: 13, bold: isSelected), .onSurface)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private func applyTheme(_ mode: String) {
        let style: UIUserInterfaceStyle
        switch mode {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = style }
    }
}

// MARK: - Color Hex Init (local helper)

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
