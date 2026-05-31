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
                    Text("التلاوات المحمّلة")
                        .customStyle(.kitab(size: 14, bold: true))
                        .customForeground(.subtitle)
                        .textCase(nil)
                } footer: {
                    HStack {
                        Text("إجمالي المساحة المستخدمة:")
                        Spacer()
                        Text(String(format: "%.0f MB", downloads.totalStorageUsedMB()))
                            .fontWeight(.semibold)
                    }
                    .customStyle(.kitab(size: 13))                    .customForeground(.subtitle)
                    .padding(.top, 8)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("إدارة التخزين")
        .navigationBarTitleDisplayMode(.inline)
        .alert("حذف التلاوة", isPresented: Binding(
            get: { showDeleteAlert != nil },
            set: { if !$0 { showDeleteAlert = nil } }
        )) {
            Button("حذف", role: .destructive) {
                if let slug = showDeleteAlert {
                    downloads.deleteReciter(slug)
                    showDeleteAlert = nil
                }
            }
            Button("إلغاء", role: .cancel) { showDeleteAlert = nil }
        }
    }

    private func reciterRow(_ reciter: DownloadedReciter) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reciter.arabicName)
                    .customStyle(.kitab(size: 15, bold: true))
                    .customForeground(.onSurface)

                Text("\(reciter.downloadedSurahNumbers.count) سورة محمّلة")
                    .customStyle(.kitab(size: 12))                    .customForeground(.subtitle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.0f MB", Double(reciter.totalSizeBytes) / 1_048_576))
                    .customStyle(.kitab(size: 13))                    .customForeground(.onSurface)

                Button(role: .destructive) {
                    showDeleteAlert = reciter.slug
                } label: {
                    Text("حذف")
                        .customStyle(.kitab(size: 12))                        .foregroundStyle(Color.error)
                }
                .accessibilityLabel("حذف تلاوة \(reciter.arabicName)")
            }
        }
        .padding(.vertical, 4)
        .environment(\.layoutDirection, .rightToLeft)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 44))
                .customForeground(.subtitle)
                .padding(.top, 40)

            Text("لم تحمّل أي تلاوة بعد")
                .customStyle(.kitab(size: 18, bold: true))
                .customForeground(.onSurface)

            Text("اذهب إلى قسم التلاوة وحمّل قارئًا للاستماع بدون إنترنت")
                .customStyle(.kitab(size: 14))                .customForeground(.subtitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }
}
