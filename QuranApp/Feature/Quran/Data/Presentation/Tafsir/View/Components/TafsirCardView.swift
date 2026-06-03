//
//  TafsirCardView.swift
//  QuranApp
//

import SwiftUI
import Core

struct TafsirCardView: View {

    let tafsir: String?
    let isDarkMode: Bool
    var isRTL: Bool = true

    private var textColor: Color { isDarkMode ? .white : .black }

    var body: some View {
        Group {
            if let tafsir {
                if tafsir.isEmpty {
                    Text("لا يوجد تفسير لهذه الآية")
                        .customStyle(.kitab(size: 13))
                        .foregroundColor(textColor.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(14)
                } else {
                    parsedText(tafsir)
                        .lineSpacing(7)
                        .multilineTextAlignment(isRTL ? .leading : .trailing)
                        .frame(maxWidth: .infinity, alignment: isRTL ? .trailing : .leading)
                        .padding(14)
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(20)
            }
        }
        .background(Color.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .environment(\.layoutDirection, isRTL ? .rightToLeft : .leftToRight)
    }

    // MARK: - Text Parser

    private func parsedText(_ raw: String) -> Text {
        let normalFont  = AppTextStyle.kitab(size: 15).directFont
        let quranFont   = AppTextStyle.kitab(size: 15, bold: true).directFont
        let normalColor = textColor.opacity(0.82)
        let quranColor  = ColorStyle.secondary.color

        var result  = Text("")
        var buffer  = ""
        var inQuran = false

        func flush(asQuran: Bool) {
            guard !buffer.isEmpty else { return }
            let seg = Text(buffer)
                .font(asQuran ? quranFont : normalFont)
                .foregroundColor(asQuran ? quranColor : normalColor)
            result = result + seg
            buffer = ""
        }

        for ch in raw {
            // Support Arabic ornamental brackets ﴿﴾ (U+FD3E/FD3F) and ASCII { }
            let isOpen  = (ch == "\u{FD3E}" || ch == "{") && !inQuran
            let isClose = (ch == "\u{FD3F}" || ch == "}") && inQuran

            if isOpen {
                flush(asQuran: false)
                inQuran = true
                buffer.append(ch)
            } else if isClose {
                buffer.append(ch)
                flush(asQuran: true)
                inQuran = false
            } else {
                buffer.append(ch)
            }
        }

        flush(asQuran: inQuran)
        return result
    }
}
