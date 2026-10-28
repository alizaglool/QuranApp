//
//  HadithGlossSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import SwiftUI
import Core

struct HadithGlossSheet: View {

    let presentation: HadithGlossPresentation
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.hadithBg.ignoresSafeArea()

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .sm) {
                    HStack(alignment: .firstTextBaseline, spacing: .xSm) {
                        Text(presentation.title)
                            .customStyle(.caption2)
                            .tracking(1.1)
                            .customForeground(.hadithMuted)

                        Spacer(minLength: .xSm)

                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .customForeground(.hadithSecondary)
                                .frame(width: 26, height: 26)
                                .background(Circle().fill(Color.hadithCard))
                        }
                        .buttonStyle(.plain)
                    }

                    Text(presentation.headline)
                        .customStyle(.adhkar(size: 22, bold: true))
                        .customForeground(.hadithGreen)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(presentation.text)
                        .customStyle(.adhkar(size: 17))
                        .customForeground(.hadithArabicText)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, .big)
                .padding(.top, .xBig)
                .padding(.bottom, .xxxBig)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .multilineTextAlignment(.trailing)
    }
}
