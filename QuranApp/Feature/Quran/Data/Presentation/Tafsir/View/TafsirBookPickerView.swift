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
                VStack(alignment: .trailing, spacing: 24) {
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
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Header
    // RTL: leading = right | trailing = left
    // "رجوع" on the right (leading), X on the left (trailing)

    private var header: some View {
        ZStack {
            Text(AppLocalizedKeys.chooseBookTitle.value)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)

            HStack {
                // Leading (right in RTL): back button
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ColorStyle.primary.color)
                        Text(AppLocalizedKeys.back.value)
                            .customStyle(.kitab(size: 15))
                            .foregroundColor(ColorStyle.primary.color)
                    }
                }
                Spacer()
                // Trailing (left in RTL): close button
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
        VStack(alignment: .trailing, spacing: 10) {
            Text(title)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)
                .frame(maxWidth: .infinity, alignment: .leading) // leading = right in RTL

            VStack(spacing: 0) {
                ForEach(Array(books.enumerated()), id: \.element.id) { index, book in
                    if index > 0 {
                        Divider()
                            .padding(.trailing, 52)
                    }
                    bookRow(book)
                }
            }
            .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Row
    // HStack in RTL: first item appears on RIGHT, last item appears on LEFT
    // → text first (right/leading), icon last (left/trailing)

    private func bookRow(_ book: TafsirBook) -> some View {
        let state: TafsirDownloadState = book.canDownload ? downloader.state(for: book.id) : .downloaded
        let isSelected = selectedBook == book

        return Button {
            handleTap(book: book, state: state)
        } label: {
            HStack(spacing: 12) {
                // Text block — leading (right side in RTL)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(book.nameArabic)
                        .customStyle(.kitab(size: 16, bold: true), .onSurface)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    if !book.author.isEmpty {
                        Text(book.author)
                            .customStyle(.kitab(size: 13))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                // Status icon — trailing (left side in RTL), fixed 28pt column
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
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ColorStyle.primary.color)
            } else {
                Color.clear
            }

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
