//
//  QuranPageSettingsSheet.swift
//  QuranApp
//

import SwiftUI
import UIKit
import Core

// MARK: - QuranPageSettingsSheet

struct QuranPageSettingsSheet: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var storage = StorageManager.shared

    @State private var mushafType: String = "mushaf"
    @State private var scrollDirection: String = "horizontal"
    @State private var selectedAppearance: String = "system"
    @State private var isBookPickerPresenting = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                    .padding(.bottom, 24)

                sectionLabel(AppLocalizedKeys.mushafOption.value)
                    .padding(.bottom, 10)
                mushafTypeCard
                    .padding(.bottom, 24)

                sectionLabel(AppLocalizedKeys.scrollDirection.value)
                    .padding(.bottom, 10)
                scrollDirectionCard
                    .padding(.bottom, 24)

                themeSectionLabel
                    .padding(.bottom, 10)
                themeCards
                    .padding(.bottom, 24)

                sectionLabel(AppLocalizedKeys.appearance.value)
                    .padding(.bottom, 10)
                appearanceCard
                    .padding(.bottom, 28)

                mushafSettingsLink
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color.surfaceContainerLow.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear { loadSettings() }
        .customSheet(isPresented: $isBookPickerPresenting, fraction: 0.5, detents: [.medium, .large]) {
            MushafBookPickerSheet(mushafType: $mushafType) {
                saveSettings()
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Settings I/O

    private func loadSettings() {
        guard let s = storage.getSettings() else { return }
        mushafType      = s.mushafType
        scrollDirection = s.scrollDirection
        selectedAppearance = s.themeMode
    }

    private func saveSettings() {
        storage.updateSettings {
            $0.mushafType      = mushafType
            $0.scrollDirection = scrollDirection
            $0.themeMode       = selectedAppearance
        }
        if TafsirBook.find(id: mushafType) != nil {
            UserDefaults.standard.set(mushafType, forKey: "selectedTafsirBookId")
        }
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

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color.outlineVariant.opacity(0.5), in: Circle())
            }
            Spacer()
            Text(AppLocalizedKeys.pageSettings.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)
            Spacer()
            Color.clear.frame(width: 30)
        }
        .padding(.top, 16)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .customStyle(.kitab(size: 15, bold: true), .onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Mushaf Type Card

    private var currentTafsirBook: TafsirBook {
        TafsirBook.find(id: mushafType) ?? TafsirBook.arabicTafsirs[2]
    }

    private var mushafTypeCard: some View {
        VStack(spacing: 0) {
            mushafRow(id: "mushaf",
                      title: AppLocalizedKeys.mushafOption.value,
                      subtitle: AppLocalizedKeys.mushafMadinahSubtitle.value)
            rowDivider
            mushafRow(id: "text",
                      title: AppLocalizedKeys.textMushaf.value,
                      subtitle: AppLocalizedKeys.textMushafSubtitle.value)
            rowDivider
            mushafRow(id: currentTafsirBook.id,
                      title: currentTafsirBook.nameArabic,
                      subtitle: currentTafsirBook.author.isEmpty ? nil : currentTafsirBook.author,
                      badge: currentTafsirBook.length?.label)
            rowDivider
            bookPickerRow
        }
        .background(Color.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.outlineVariant.opacity(0.25))
            .frame(height: 0.5)
            .padding(.horizontal, 16)
    }

    private func mushafRow(
        id: String,
        title: String,
        subtitle: String?,
        badge: String? = nil
    ) -> some View {
        let selected = mushafType == id
        return Button {
            mushafType = id
            saveSettings()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(title)
                        .customStyle(.kitab(size: 15), .onSurface)
                        .multilineTextAlignment(.trailing)
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .customStyle(.kitab(size: 12), .subtitle)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                if let badge {
                    Text(badge)
                        .customStyle(.kitab(size: 11), .primary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(ColorStyle.primary.color.opacity(0.12))
                        )
                }

                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(selected ? ColorStyle.primary.color : .clear)
                    .frame(width: 22)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bookPickerRow: some View {
        Button { isBookPickerPresenting = true } label: {
            HStack(spacing: 12) {
                Text(AppLocalizedKeys.chooseBook.value)
                    .customStyle(.kitab(size: 15), .primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.outlineVariant)
                    .frame(width: 22)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scroll Direction Card

    private var scrollDirectionCard: some View {
        HStack(spacing: 6) {
            scrollDirectionButton(direction: "horizontal")
            scrollDirectionButton(direction: "vertical")
        }
        .padding(4)
        .background(Color.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private func scrollDirectionButton(direction: String) -> some View {
        let selected = scrollDirection == direction
        return Button {
            scrollDirection = direction
            saveSettings()
        } label: {
            scrollDirectionIcon(direction: direction, selected: selected)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? Color.mushafPage : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    @ViewBuilder
    private func scrollDirectionIcon(direction: String, selected: Bool) -> some View {
        let pageColor: Color = selected
            ? Color(red: 0.28, green: 0.18, blue: 0.08).opacity(0.55)
            : Color.outlineVariant
        if direction == "horizontal" {
            HStack(spacing: 5) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(pageColor)
                        .frame(width: 22, height: 31)
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 3)
                .fill(pageColor)
                .frame(width: 24, height: 34)
                .overlay(
                    VStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { _ in
                            Capsule()
                                .fill(Color.white.opacity(0.4))
                                .frame(maxWidth: .infinity)
                                .frame(height: 2)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
                )
        }
    }

    // MARK: - Theme Cards (Premium / Locked)

    private var themeSectionLabel: some View {
        HStack(spacing: 6) {
            Text(AppLocalizedKeys.theme.value)
                .customStyle(.kitab(size: 15, bold: true), .onSurface)
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var themeCards: some View {
        HStack(spacing: 12) {
            themeCard(isColorful: true,  label: AppLocalizedKeys.classicTheme.value)
            themeCard(isColorful: false, label: AppLocalizedKeys.coloredTheme.value)
        }
    }

    private func themeCard(isColorful: Bool, label: String) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12)
                .fill(isColorful ? Color.mushafPage : Color.background)
                .frame(height: 90)
                .overlay(
                    VStack(spacing: 0) {
                        Image("newClassicChapterHeader")
                            .resizable()
                            .scaledToFit()
                            .saturation(isColorful ? 1.0 : 0.15)
                            .colorMultiply(isColorful ? .white : Color(red: 0.88, green: 0.83, blue: 0.76))
                            .padding(.horizontal, 10)
                            .padding(.top, 10)
                        Spacer()
                    }
                )
                .overlay(
                    VStack {
                        Spacer()
                        Text(label)
                            .customStyle(.kitab(size: 12))
                            .foregroundColor(Color.black.opacity(0.4))
                            .padding(.bottom, 8)
                    }
                )

            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(width: 22, height: 22)
                .background(Color.secondary.opacity(0.15), in: Circle())
                .padding(8)
        }
        .frame(maxWidth: .infinity)
        .opacity(0.82)
    }

    // MARK: - Appearance Card

    private var appearanceCard: some View {
        HStack(spacing: 0) {
            appearanceOption(value: "system", label: AppLocalizedKeys.systemAppearance.value)
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.25))
                .frame(width: 0.5, height: 26)
            appearanceOption(value: "light", label: AppLocalizedKeys.lightAppearance.value)
            Rectangle()
                .fill(Color.outlineVariant.opacity(0.25))
                .frame(width: 0.5, height: 26)
            appearanceOption(value: "dark", label: AppLocalizedKeys.darkAppearance.value)
        }
        .padding(4)
        .background(Color.background, in: RoundedRectangle(cornerRadius: 14))
    }

    private func appearanceOption(value: String, label: String) -> some View {
        let selected = selectedAppearance == value
        return Button {
            selectedAppearance = value
            applyTheme(value)
            saveSettings()
        } label: {
            Text(label)
                .customStyle(.kitab(size: 14, bold: selected))
                .foregroundColor(selected ? Color(UIColor.label) : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selected ? Color.mushafPage : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    // MARK: - Mushaf Settings Link

    private var mushafSettingsLink: some View {
        Button {
            // Navigate to full mushaf settings
        } label: {
            HStack(spacing: 8) {
                Text(AppLocalizedKeys.mushafSettings.value)
                    .customStyle(.kitab(size: 15), .primary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.outlineVariant)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mushaf Book Picker Sheet

private struct MushafBookPickerSheet: View {

    @Binding var mushafType: String
    let onSelected: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                pickerSection(title: AppLocalizedKeys.arabicTafsirSection.value,
                              books: TafsirBook.arabicTafsirs)
                pickerSection(title: AppLocalizedKeys.translationsSection.value,
                              books: TafsirBook.translations)
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(AppLocalizedKeys.chooseBookTitle.value)
                        .customStyle(.kitab(size: 17, bold: true), .onSurface)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.outlineVariant.opacity(0.5), in: Circle())
                    }
                }
            }
            .environment(\.layoutDirection, .rightToLeft)
        }
    }

    @ViewBuilder
    private func pickerSection(title: String, books: [TafsirBook]) -> some View {
        Section {
            ForEach(books) { book in
                bookRow(book)
            }
        } header: {
            Text(title)
                .customStyle(.kitab(size: 13, bold: true), .onSurface)
                .textCase(nil)
        }
    }

    private func bookRow(_ book: TafsirBook) -> some View {
        Button {
            mushafType = book.id
            onSelected()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(book.nameArabic)
                        .customStyle(.kitab(size: 15, bold: true), .onSurface)
                        .multilineTextAlignment(.trailing)
                    if !book.author.isEmpty {
                        Text(book.author)
                            .customStyle(.kitab(size: 12), .subtitle)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                HStack(spacing: 6) {
                    if let length = book.length {
                        Text(length.label)
                            .customStyle(.kitab(size: 11))
                            .foregroundColor(length == .brief ? ColorStyle.secondary.color : ColorStyle.primary.color)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill((length == .brief ? ColorStyle.secondary.color : ColorStyle.primary.color).opacity(0.12))
                            )
                    }
                    if book.language != .arabic {
                        Text(book.language.displayName)
                            .customStyle(.kitab(size: 17, bold: true), .subtitle)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.surfaceContainerLow))
                            .environment(\.layoutDirection, .leftToRight)
                    }
                }

                Image(systemName: mushafType == book.id ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(mushafType == book.id ? ColorStyle.primary.color : Color.outlineVariant)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
