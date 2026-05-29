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
                .font(.system(size: 17, weight: .semibold))
                .customForeground(.onSurface)

            Spacer()

            Button(AppLocalizedKeys.edit.value) {}
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(ColorStyle.primary.color)
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
                .font(.system(size: 15))
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
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
            .cornerRadius(12)
        }
    }

    private var tafsirRow: some View {
        HStack(spacing: 12) {
            // Info placeholder — far left
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 32, height: 32)
                Image(systemName: "info")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            // Disabled play icon
            Image(systemName: "play")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.systemGray3))

            Spacer()

            // Name + subtitle — right-aligned
            VStack(alignment: .trailing, spacing: 2) {
                Text("المختصر الصوتي")
                    .font(.custom("Kitab-Regular", size: 16))
                    .customForeground(.onSurface)
                Text("عبدالله الأسمري وصابر عبدالحكم")
                    .font(.system(size: 12))
                    .customForeground(.subtitle)
            }
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
                    .font(.system(size: 15))
                    .customForeground(.subtitle)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredReciters.enumerated()), id: \.element.id) { idx, reciter in
                        reciterRow(reciter)
                        if idx < filteredReciters.count - 1 {
                            Divider().padding(.leading, 88)
                        }
                    }
                }
                .background(Color.surfaceContainerLow)
                .cornerRadius(12)
            }
        }
    }

    @ViewBuilder
    private func reciterRow(_ reciter: ReciterInfo) -> some View {
        let isSelected = audio.currentReciter.id == reciter.id

        HStack(spacing: 12) {
            // Info button — taps only the circle, not the whole row
            Button(action: { showDownloadSheet = reciter }) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 32, height: 32)
                    Image(systemName: "info")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)

            // Play / checkmark indicator (not a button — row tap handles selection)
            Group {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ColorStyle.primary.color)
                } else {
                    Image(systemName: "play")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ColorStyle.primary.color)
                }
            }
            .frame(width: 24, height: 24)

            Spacer()

            // Reciter name — right-aligned
            VStack(alignment: .trailing, spacing: 2) {
                Text(reciter.arabicName)
                    .font(.custom("Kitab-Regular", size: 16))
                    .customForeground(isSelected ? .primary : .onSurface)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
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
                .font(.system(size: 17, weight: .bold))
                .customForeground(.onSurface)
        }
    }
}
