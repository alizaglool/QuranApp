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
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    bookSection(
                        title: AppLocalizedKeys.arabicTafsirSection.value,
                        books: TafsirBook.arabicTafsirs
                    )
                    bookSection(
                        title: AppLocalizedKeys.translationsSection.value,
                        books: TafsirBook.translations
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.background)
        .appDirection()
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text(AppLocalizedKeys.chooseBookTitle.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

            HStack {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ColorStyle.primary.color)
                        Text(AppLocalizedKeys.back.value)
                            .customStyle(.kitab(size: 15))
                            .foregroundColor(ColorStyle.primary.color)
                    }
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Color.outlineVariant.opacity(0.5), in: Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Section

    private func bookSection(title: String, books: [TafsirBook]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                    if index > 0 {
                        Divider()
                            .padding(.trailing, 20)
                            .padding(.leading, 20)
                    }
                    bookRow(book)
                }
            }
            .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Row

    private func bookRow(_ book: TafsirBook) -> some View {
        let state: TafsirDownloadState = book.canDownload ? downloader.state(for: book.id) : .downloaded
        let isSelected = selectedBook == book

        return Button {
            handleTap(book: book, state: state)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.nameArabic)
                        .customStyle(.kitab(size: 16, bold: true), .onSurface)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !book.author.isEmpty {
                        Text(book.author)
                            .customStyle(.kitab(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                statusIcon(book: book, state: state, isSelected: isSelected)
                    .frame(width: 28, height: 28)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Icon

    @ViewBuilder
    private func statusIcon(book: TafsirBook, state: TafsirDownloadState, isSelected: Bool) -> some View {
        switch state {
        case .downloaded:
            Color.clear
            
        case .downloading(let progress):
            ZStack {
                Circle()
                    .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ColorStyle.primary.color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

        case .notDownloaded, .failed:
            Image("cloudAndArrowDown")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(ColorStyle.primary.color)
        }
    }

    // MARK: - Actions

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
}
