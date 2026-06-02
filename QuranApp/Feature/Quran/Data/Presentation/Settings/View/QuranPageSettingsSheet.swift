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

    @State private var mushafType: MushafType = .mushaf
    @State private var scrollDirection: ScrollDirection = .horizontal
    @State private var selectedTheme: Theme = .classic
    @State private var selectedAppearance: AppearanceMode = .system
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

                sectionLabel(AppLocalizedKeys.theme.value)
                    .padding(.bottom, 10)
                themeCards
                    .padding(.bottom, 24)

                sectionLabel(AppLocalizedKeys.appearance.value)
                    .padding(.bottom, 10)
                appearanceCard
                    .padding(.bottom, 28)

            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .background(Color.surfaceContainerLow.ignoresSafeArea())
        .environment(\.layoutDirection, .rightToLeft)
        .onAppear { loadSettings() }
        .customSheet(isPresented: $isBookPickerPresenting, detents: [.medium, .large]) {
            MushafBookPickerSheet(selectedType: $mushafType) {
                saveSettings()
            }
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Settings I/O

    private func loadSettings() {
        guard let s = storage.getSettings() else { return }
        mushafType         = s.mushafDisplayType
        scrollDirection    = s.scrollDirection
        selectedAppearance = AppearanceMode(rawValue: s.themeMode) ?? .system
        selectedTheme      = s.selectedTheme
    }

    private func saveSettings() {
        storage.updateSettings {
            $0.mushafDisplayType = mushafType
            $0.scrollDirection   = scrollDirection
            $0.themeMode         = selectedAppearance.rawValue
            $0.selectedTheme     = selectedTheme
        }
        if case .tafsir(let id) = mushafType {
            UserDefaults.standard.set(id, forKey: "selectedTafsirBookId")
        }
    }

    private func applyTheme(_ mode: AppearanceMode) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .forEach { $0.overrideUserInterfaceStyle = mode.uiStyle }
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
        if case .tafsir(let id) = mushafType {
            return TafsirBook.find(id: id) ?? TafsirBook.arabicTafsirs[2]
        }
        return TafsirBook.arabicTafsirs[2]
    }

    private var mushafTypeCard: some View {
        VStack(spacing: 0) {
            mushafRow(.mushaf,
                      title: AppLocalizedKeys.mushafOption.value,
                      subtitle: AppLocalizedKeys.mushafMadinahSubtitle.value)
            rowDivider
            mushafRow(.text,
                      title: AppLocalizedKeys.textMushaf.value,
                      subtitle: AppLocalizedKeys.textMushafSubtitle.value)
            rowDivider
            mushafRow(.tafsir(id: currentTafsirBook.id),
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
    }

    private func mushafRow(
        _ type: MushafType,
        title: String,
        subtitle: String?,
        badge: String? = nil
    ) -> some View {
        let selected = mushafType == type
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                mushafType = type
            }
            saveSettings()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { dismiss() }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                // Checkmark — renders on LEFT in RTL
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selected ? ColorStyle.primary.color : .clear)
                    .frame(width: 24)

                Spacer()

                // Text block — renders on RIGHT in RTL
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .customStyle(.kitab(size: 17, bold: true), .onSurface)
                            .multilineTextAlignment(.trailing)
                    }
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .customStyle(.kitab(size: 14), .secondary)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bookPickerRow: some View {
        Button { isBookPickerPresenting = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.outlineVariant)
                    .frame(width: 24)

                Spacer()

                Text(AppLocalizedKeys.chooseBook.value)
                    .customStyle(.kitab(size: 15, bold: true), .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Scroll Direction Card

    private var scrollDirectionCard: some View {
        HStack(spacing: 4) {
            scrollDirectionButton(direction: .horizontal)
            scrollDirectionButton(direction: .vertical)
        }
        .padding(4)
        .background(Color.pickerContainer, in: RoundedRectangle(cornerRadius: 14))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: scrollDirection)
    }

    private func animationType(for direction: ScrollDirection) -> ScrollAnimationType {
        let isSkeuomorphic = mushafType.isSkeuomorphic
        return direction == .horizontal
            ? .horizontal(isSkeuomorphic: isSkeuomorphic)
            : .vertical(isSkeuomorphic: isSkeuomorphic)
    }

    private func scrollDirectionButton(direction: ScrollDirection) -> some View {
        let selected = scrollDirection == direction
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                scrollDirection = direction
            }
            saveSettings()
            dismiss()
        } label: {
            ScrollDirectionAnimationView(animationType: animationType(for: direction))
                .frame(width: 24, height: 30)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(selected ? Color.pickerSelection : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }

    // MARK: - Theme Cards

    private var themeCards: some View {
        HStack(spacing: 4) {
            themeCard(theme: .tinted,  image: "newTintedThumbnail")
            themeCard(theme: .classic, image: "newClassicThumbnail")
        }
        .padding(4)
        .background(Color.pickerContainer, in: RoundedRectangle(cornerRadius: 14))
    }

    private func themeCard(theme: Theme, image: String) -> some View {
        let selected = selectedTheme == theme
        return Button {
            selectedTheme = theme
            saveSettings()
            dismiss()
        } label: {
            Image(image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(selected ? Color.pickerSelection : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }

    // MARK: - Appearance Card

    private var appearanceCard: some View {
        HStack(spacing: 4) {
            ForEach(AppearanceMode.allCases, id: \.self) { mode in
                appearanceOption(mode)
            }
        }
        .padding(4)
        .background(Color.pickerContainer, in: RoundedRectangle(cornerRadius: 14))
    }

    private func appearanceOption(_ mode: AppearanceMode) -> some View {
        let selected = selectedAppearance == mode
        return Button {
            selectedAppearance = mode
            applyTheme(mode)
            saveSettings()
            dismiss()
        } label: {
            Text(mode.label)
                .customStyle(.kitab(size: 14, bold: selected))
                .foregroundColor(
                    selected
                        ? Color.pickerSelectedLabel
                        : Color.pickerUnselectedLabel.opacity(0.5)
                )
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 11)
                        .fill(selected ? Color.pickerSelection : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selected)
    }
}

// MARK: - Mushaf Book Picker Sheet

private struct MushafBookPickerSheet: View {

    @Binding var selectedType: MushafType
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
            selectedType = .tafsir(id: book.id)
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

                Image(systemName: selectedType == .tafsir(id: book.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selectedType == .tafsir(id: book.id) ? ColorStyle.primary.color : Color.outlineVariant)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AppearanceMode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return AppLocalizedKeys.systemAppearance.value
        case .light:  return AppLocalizedKeys.lightAppearance.value
        case .dark:   return AppLocalizedKeys.darkAppearance.value
        }
    }

    var uiStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}
