//
//  TafsirBookPickerView.swift
//  QuranApp
//

import SwiftUI
import Core

struct TafsirBookPickerView: View {

    @Binding var selectedBook: TafsirBook
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var downloader = TafsirDownloadManager.shared

    var body: some View {
        NavigationStack {
            List {
                section(title: "التفسير العربي", books: TafsirBook.arabicTafsirs)
                section(title: "الترجمات",        books: TafsirBook.translations)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("اختر التفسير")
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
        .background(Color.background)
    }

    @ViewBuilder
    private func section(title: String, books: [TafsirBook]) -> some View {
        Section {
            ForEach(books) { book in
                bookRow(book)
                    .listRowBackground(Color.surfaceContainerLow)
            }
        } header: {
            Text(title)
                .customStyle(.kitab(size: 13, bold: true), .onSurface)
                .textCase(nil)
        }
    }

    private func bookRow(_ book: TafsirBook) -> some View {
        let downloadState: TafsirDownloadState = book.canDownload ? downloader.state(for: book.id) : .downloaded

        return Button {
            handleTap(book: book, state: downloadState)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 3) {
                    Text(book.nameArabic)
                        .customStyle(.kitab(size: 16, bold: true), .onSurface)
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
                        lengthBadge(length)
                    }
                    if book.language != .arabic {
                        languageBadge(book.language)
                    }
                }

                statusIcon(book: book, state: downloadState)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func statusIcon(book: TafsirBook, state: TafsirDownloadState) -> some View {
        switch state {
        case .downloaded:
            HStack(spacing: 6) {
                if book.isBundle {
                    Text("مضمّن")
                        .customStyle(.kitab(size: 11))
                        .foregroundColor(ColorStyle.primary.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(ColorStyle.primary.color.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 6))
                }
                Image(systemName: selectedBook == book ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selectedBook == book ? ColorStyle.primary.color : Color.outlineVariant)
            }

        case .downloading(let progress):
            ZStack {
                Circle()
                    .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 2)
                    .frame(width: 22, height: 22)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ColorStyle.primary.color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 22, height: 22)
            }

        case .notDownloaded:
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 20))
                .foregroundColor(ColorStyle.primary.color)

        case .failed:
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 20))
                .foregroundColor(.red)
        }
    }

    private func handleTap(book: TafsirBook, state: TafsirDownloadState) {
        switch state {
        case .downloaded:
            selectedBook = book
            dismiss()

        case .notDownloaded, .failed:
            downloader.download(bookId: book.id)

        case .downloading:
            break
        }
    }

    private func lengthBadge(_ length: TafsirBook.TafsirLength) -> some View {
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

    private func languageBadge(_ language: TafsirBook.TafsirLanguage) -> some View {
        Text(language.displayName)
            .customStyle(.caption1, .subtitle)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.surfaceContainerLow)
            )
            .environment(\.layoutDirection, .leftToRight)
    }
}
