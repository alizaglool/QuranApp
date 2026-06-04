//
//  ReciterSelectionSheet.swift
//  QuranApp
//

import SwiftUI
import Core

struct ReciterSelectionSheet: View {
    @ObservedObject private var audio = AudioEngine.shared
    @ObservedObject private var downloads = DownloadManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var showDownloadSheet: ReciterInfo? = nil

    private var filteredReciters: [ReciterInfo] {
        if searchText.isEmpty { return ReciterLibrary.all }
        let q = searchText.lowercased()
        return ReciterLibrary.all.filter {
            $0.arabicName.contains(searchText) ||
            $0.englishName.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            ScrollView {
                VStack(spacing: 16) {
                    tafsirSection
                    recitationsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color.background)
        .appDirection()
        .sheet(item: $showDownloadSheet) { reciter in
            SurahDownloadSheet(reciter: reciter, onBack: { showDownloadSheet = nil })
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }

    // MARK: - Grab Handle

    private var grabHandle: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(Color(.systemGray4))
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    // MARK: - Header
    // Layout (LTR): [×  dismiss] — title — [تعديل]

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 30, height: 30)
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }

            Spacer()

            Text(AppLocalizedKeys.reciterSelection.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

            Spacer()

            Button(AppLocalizedKeys.edit.value) {}
                .customStyle(.kitab(size: 16), .primary)
                .frame(minWidth: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.background)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            TextField(AppLocalizedKeys.search.value, text: $searchText)
                .customStyle(.kitab(size: 15))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .customCornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Tafsir Section

    private var tafsirSection: some View {
        VStack(alignment: .trailing, spacing: 10) {
            sectionHeader(AppLocalizedKeys.tafsirAudio.value)

            VStack(spacing: 0) {
                tafsirRow
            }
            .background(Color.surfaceContainerLow)
            .customCornerRadius(12)
        }
    }

    private var tafsirRow: some View {
        HStack(spacing: 12) {
            // Info icon — green outline, no action (placeholder)
            Image(systemName: "info.circle")
                .font(.system(size: 24))
                .foregroundColor(ColorStyle.primary.color)
                .frame(width: 32, height: 32)

            Spacer()

            // Name + subtitle — right-aligned
            VStack(alignment: .trailing, spacing: 2) {
                Text(AppLocalizedKeys.tafsirAudioTitle.value)
                    .customStyle(.kitab(size: 16), .onSurface)
                Text(AppLocalizedKeys.tafsirAudioSubtitle.value)
                    .customStyle(.kitab(size: 12), .subtitle)
            }

            // ▶ always visible, gray
            Image(systemName: "play.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    // MARK: - Recitations Section

    private var recitationsSection: some View {
        VStack(alignment: .trailing, spacing: 10) {
            sectionHeader(AppLocalizedKeys.recitations.value)

            if filteredReciters.isEmpty {
                Text(AppLocalizedKeys.noResults.value)
                    .customStyle(.kitab(size: 15), .subtitle)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredReciters.enumerated()), id: \.element.id) { idx, reciter in
                        reciterRow(reciter)
                        if idx < filteredReciters.count - 1 {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color.surfaceContainerLow)
                .customCornerRadius(12)
            }
        }
    }

    @ViewBuilder
    private func reciterRow(_ reciter: ReciterInfo) -> some View {
        let isSelected = audio.currentReciter.id == reciter.id

        HStack(spacing: 12) {
            // ⓘ info button — green outline icon
            Button(action: { showDownloadSheet = reciter }) {
                Image(systemName: "info.circle")
                    .font(.system(size: 24))
                    .foregroundColor(ColorStyle.primary.color)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)

            // ✓ checkmark — only when selected
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ColorStyle.primary.color)
                    .frame(width: 20)
            }

            Spacer()

            // Reciter name — right-aligned
            Text(reciter.arabicName)
                .customStyle(.kitab(size: 16), isSelected ? .primary : .onSurface)
                .fontWeight(isSelected ? .semibold : .regular)

            // ▶ always visible, gray
            Image(systemName: "play.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(.systemGray3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            audio.switchReciter(reciter)
            dismiss()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Spacer()
            Text(title)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)
        }
    }
}
