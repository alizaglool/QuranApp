//
//  HadithBookRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 19/10/2026.
//

import SwiftUI
import Core

struct HadithBookRow<Accessory: View>: View {

    let book: HadithBook
    let metaText: String
    let isDownloaded: Bool
    let onSelect: () -> Void
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(spacing: .sm) {
            coverArtwork
            bookDetails
            Spacer(minLength: .xSm)
            accessory()
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .sm)
        .frame(maxWidth: .infinity)
        .background(Color.hadithCardWash)
        .customCornerRadius(.cornerXl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXl)
                .strokeBorder(ColorStyle.outlineVariant.color.opacity(0.18), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(book.title)
    }
}

// MARK: - Parts

private extension HadithBookRow {

    var coverArtwork: some View {
        HadithBookCoverView(book: book)
            .frame(width: 52, height: 72)
            .customCornerRadius(.cornerXxSm)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXxSm)
                    .strokeBorder(ColorStyle.outlineVariant.color.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
            .opacity(isDownloaded ? 1 : 0.5)
            .grayscale(isDownloaded ? 0 : 0.55)
    }

    var bookDetails: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(book.title)
                .customStyle(.adhkar(size: 17, bold: true))
                .foregroundColor(Color.hadithBookTitle)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(book.author)
                .customStyle(.caption1)
                .foregroundColor(Color.hadithBookMeta)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text(metaText)
                .customStyle(.caption2, .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
}
