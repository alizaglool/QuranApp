//
//  StorageManagementView.swift
//  QuranApp
//

import SwiftUI
import Core

struct StorageManagementView: View {

    @StateObject private var downloads = DownloadManager.shared
    @State private var showDeleteAlert: String? = nil  // reciter slug
    private let storage = StorageManager.shared

    var downloadedReciters: [DownloadedReciter] {
        storage.getAllDownloadedReciters()
    }

    var body: some View {
        List {
            if downloadedReciters.isEmpty {
                emptyState
                    .listRowBackground(Color.background)
                    .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(downloadedReciters, id: \.slug) { reciter in
                        reciterRow(reciter)
                    }
                } header: {
                    Text(AppLocalizedKeys.downloadedRecitations.value)
                        .customStyle(.kitab(size: 14, bold: true), .subtitle)
                        .textCase(nil)
                } footer: {
                    HStack {
                        Text(AppLocalizedKeys.totalStorageUsed.value)
                        Spacer()
                        Text(String(format: "%.0f MB", downloads.totalStorageUsedMB()))
                            .fontWeight(.semibold)
                    }
                    .customStyle(.kitab(size: 13), .subtitle)
                    .padding(.top, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(AppLocalizedKeys.storageManagement.value)
        .navigationBarTitleDisplayMode(.inline)
        .appDirection()
        .alert(AppLocalizedKeys.deleteRecitation.value, isPresented: Binding(
            get: { showDeleteAlert != nil },
            set: { if !$0 { showDeleteAlert = nil } }
        )) {
            Button(AppLocalizedKeys.deleteButton.value, role: .destructive) {
                if let slug = showDeleteAlert {
                    downloads.deleteReciter(slug)
                    showDeleteAlert = nil
                }
            }
            Button(AppLocalizedKeys.cancel.value, role: .cancel) { showDeleteAlert = nil }
        }
    }

    private func reciterRow(_ reciter: DownloadedReciter) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reciter.arabicName)
                    .customStyle(.kitab(size: 15, bold: true), .onSurface)

                Text(String(format: AppLocalizedKeys.surahsDownloaded.value, reciter.downloadedSurahNumbers.count))
                    .customStyle(.kitab(size: 12), .subtitle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f MB", Double(reciter.totalSizeBytes) / 1_048_576))
                    .customStyle(.kitab(size: 13), .onSurface)

                Button(role: .destructive) {
                    showDeleteAlert = reciter.slug
                } label: {
                    Text(AppLocalizedKeys.deleteButton.value)
                        .customStyle(.kitab(size: 12))
                        .foregroundStyle(Color.error)
                }
                .accessibilityLabel(String(format: "%@ %@", AppLocalizedKeys.deleteButton.value, reciter.arabicName))
            }
        }
        .padding(.vertical, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image("cloudAndArrowDown")
                .font(.system(size: 44))
                .customForeground(.subtitle)
                .padding(.top, 40)

            Text(AppLocalizedKeys.noDownloadsTitle.value)
                .customStyle(.kitab(size: 18, bold: true), .onSurface)

            Text(AppLocalizedKeys.noDownloadsMessage.value)
                .customStyle(.kitab(size: 14), .subtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }
}
