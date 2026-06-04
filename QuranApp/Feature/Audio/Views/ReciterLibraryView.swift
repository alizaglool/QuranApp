//
//  ReciterLibraryView.swift
//  QuranApp
//

import SwiftUI
import Core

struct ReciterLibraryView: View {

    @EnvironmentObject private var audio: AudioEngine
    @StateObject private var downloads = DownloadManager.shared
    @State private var showDeleteAlert: ReciterInfo? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ReciterLibrary.all) { reciter in
                    ReciterRow(reciter: reciter, onDelete: { showDeleteAlert = reciter })
                        .environmentObject(audio)
                        .environmentObject(downloads)
                }
            }
            .listStyle(.plain)
            .navigationTitle(AppLocalizedKeys.reciters.value)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .customForeground(.onSurface)
                    }
                    .accessibilityLabel(AppLocalizedKeys.close.value)
                }
            }
            .alert(AppLocalizedKeys.deleteRecitation.value, isPresented: Binding(
                get: { showDeleteAlert != nil },
                set: { if !$0 { showDeleteAlert = nil } }
            )) {
                Button(AppLocalizedKeys.deleteButton.value, role: .destructive) {
                    if let r = showDeleteAlert {
                        downloads.deleteReciter(r.id)
                        showDeleteAlert = nil
                    }
                }
                Button(AppLocalizedKeys.cancel.value, role: .cancel) { showDeleteAlert = nil }
            } message: {
                if let r = showDeleteAlert {
                    Text(String(format: AppLocalizedKeys.deleteReciterMessage.value, r.arabicName))
                }
            }
        }
        .appDirection()
    }
}

// MARK: - ReciterRow

private struct ReciterRow: View {

    let reciter: ReciterInfo
    let onDelete: () -> Void
    @EnvironmentObject private var audio: AudioEngine
    @EnvironmentObject private var downloads: DownloadManager
    @State private var storage = StorageManager.shared

    private var isSelected: Bool { audio.currentReciter.id == reciter.id }
    private var isDownloaded: Bool { downloads.completedReciters.contains(reciter.id) }
    private var downloadProgress: DownloadProgress? { downloads.activeDownloads[reciter.id] }
    private var isDownloading: Bool { downloadProgress != nil }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.primaryColor : Color.surfaceContainerLow)
                        .frame(width: 36, height: 36)

                    Image(systemName: isSelected ? "checkmark" : "person.fill")
                        .font(.system(size: isSelected ? 14 : 14, weight: .medium))
                        .foregroundStyle(isSelected ? Color.white : Color.subtitleText)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(reciter.arabicName)
                        .customStyle(.kitab(size: 16, bold: true), .onSurface)

                    Text(reciter.englishName)
                        .customStyle(.kitab(size: 12), .subtitle)
                }

                Spacer()

                trailingView
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture { handleTap() }

            // Download progress bar
            if let progress = downloadProgress {
                ProgressView(value: progress.fractionCompleted)
                    .tint(Color.primaryColor)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 6)
                    .transition(.opacity)
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.background)
    }

    @ViewBuilder
    private var trailingView: some View {
        if isDownloaded {
            if isSelected {
                // Currently selected — show badge only (no delete while active)
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.primaryColor)
                    Text(AppLocalizedKeys.selectedLabel.value)
                        .customStyle(.kitab(size: 12), .subtitle)
                }
            } else {
                // Downloaded but not selected — download button flips to delete
                Button(action: onDelete) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .medium))
                        Text(AppLocalizedKeys.deleteButton.value)
                            .customStyle(.kitab(size: 12))
                    }
                    .foregroundStyle(Color(.systemRed))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemRed).opacity(0.1))
                    )
                }
                .accessibilityLabel(String(format: "%@ %@", AppLocalizedKeys.deleteButton.value, reciter.arabicName))
            }
        } else if isDownloading, let progress = downloadProgress {
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(progress.fractionCompleted * 100))%")
                    .customStyle(.kitab(size: 12), .subtitle)

                Button {
                    downloads.cancelDownload(for: reciter.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.error)
                }
                .accessibilityLabel(AppLocalizedKeys.cancelDownload.value)
            }
        } else {
            // Not downloaded — download button
            Button {
                downloads.downloadAllSurahs(for: reciter)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 14))
                    Text("~\(reciter.estimatedSizeMB) MB")
                        .customStyle(.kitab(size: 12))
                }
                .foregroundStyle(Color.primaryColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.primaryColor.opacity(0.1))
                )
            }
            .accessibilityLabel(reciter.arabicName)
        }
    }

    private func handleTap() {
        if isDownloaded {
            // Select this reciter
            audio.currentReciter = reciter
            storage.updateSettings {
                $0.selectedReciterId = reciter.id
                $0.selectedReciterName = reciter.arabicName
            }
        } else if !isDownloading {
            downloads.downloadAllSurahs(for: reciter)
        }
    }
}
