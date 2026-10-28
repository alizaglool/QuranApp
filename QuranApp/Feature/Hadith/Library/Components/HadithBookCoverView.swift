//
//  HadithBookCoverView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 19/10/2026.
//

import SwiftUI
import Core

struct HadithBookCoverView: View {

    let book: HadithBook

    var body: some View {
        GeometryReader { proxy in
            coverContent(size: proxy.size)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .environment(\.layoutDirection, .leftToRight)
        }
    }
}

// MARK: - Content

private extension HadithBookCoverView {

    var artworkImage: UIImage? {
        UIImage(named: "hadithBookCover\(book.id)")
    }

    var fieldColor: Color {
        Color(hex: book.colorHex)
    }

    @ViewBuilder
    func coverContent(size: CGSize) -> some View {
        if let artworkImage {
            Image(uiImage: artworkImage)
                .resizable()
                .scaledToFill()
        } else {
            generatedCover(size: size)
        }
    }

    func generatedCover(size: CGSize) -> some View {
        ZStack(alignment: .trailing) {
            fieldColor

            LinearGradient(colors: [Color.white.opacity(0.12),
                                    Color.clear,
                                    Color.black.opacity(0.14)],
                           startPoint: .top,
                           endPoint: .bottom)

            VStack(spacing: size.height * 0.05) {
                Text(book.titleAr)
                    .customStyle(.adhkar(size: size.width * 0.21, bold: true))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)

                Rectangle()
                    .fill(Color.white.opacity(0.42))
                    .frame(width: size.width * 0.46, height: 1)

                Text(book.titleAr)
                    .customStyle(.adhkar(size: size.width * 0.115, bold: false))
                    .foregroundColor(Color.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.horizontal, size.width * 0.16)
            .frame(width: size.width)

            Rectangle()
                .fill(Color.black.opacity(0.2))
                .frame(width: max(3, size.width * 0.075))
        }
    }
}
