//
//  HadithNarratorSheet.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import SwiftUI
import Core

struct HadithNarratorSheet: View {

    let presentation: HadithNarratorPresentation
    let onClose: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.hadithBg.ignoresSafeArea()

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .md) {
                    header
                    if presentation.isEmpty {
                        empty
                    } else {
                        if !presentation.rows.isEmpty { facts }
                        if !presentation.verdicts.isEmpty { verdicts }
                        if !presentation.sources.isEmpty { sources }
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, .xBig)
                .padding(.bottom, .xxxBig)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: .sm) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 34))
                .customForeground(.hadithGold)

            VStack(alignment: .leading, spacing: .xxSm) {
                Text(presentation.title)
                    .customStyle(.adhkar(size: 20, bold: true))
                    .customForeground(.hadithArabicText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if !presentation.subtitle.isEmpty {
                    Text(presentation.subtitle)
                        .customStyle(.adhkar(size: 15))
                        .customForeground(.hadithSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: .xSm)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .customForeground(.hadithSecondary)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.hadithCard))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Sections

    private var facts: some View {
        card {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(presentation.rows.enumerated()), id: \.element.id) { index, row in
                    VStack(alignment: .leading, spacing: 2) {
                        caption(row.label)
                        Text(row.value)
                            .customStyle(.adhkar(size: 15))
                            .customForeground(.hadithArabicText)
                            .lineSpacing(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if index < presentation.rows.count - 1 { separator }
                }
            }
        }
    }

    private var verdicts: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            caption(presentation.verdictsTitle)
            card {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(presentation.verdicts.enumerated()), id: \.element.id) { index, verdict in
                        VStack(alignment: .leading, spacing: 2) {
                            if !verdict.scholar.isEmpty {
                                Text(verdict.scholar)
                                    .customStyle(.adhkar(size: 15, bold: true))
                                    .customForeground(.hadithGold)
                            }
                            Text(verdict.text)
                                .customStyle(.adhkar(size: 15))
                                .customForeground(.hadithSecondary)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if index < presentation.verdicts.count - 1 { separator }
                    }
                }
            }
        }
    }

    private var sources: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            caption(presentation.sourcesTitle)
            card {
                VStack(alignment: .leading, spacing: .xSm) {
                    ForEach(presentation.sources, id: \.self) { source in
                        HStack(alignment: .firstTextBaseline, spacing: .xSm) {
                            Circle()
                                .fill(Color.hadithGold)
                                .frame(width: 4, height: 4)
                            Text(source)
                                .customStyle(.adhkar(size: 15))
                                .customForeground(.hadithArabicText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private var empty: some View {
        card {
            Text(presentation.emptyMessage)
                .customStyle(.adhkar(size: 15))
                .customForeground(.hadithMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: Building blocks

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: .cornerLg).fill(Color.hadithCard))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerLg)
                    .strokeBorder(Color.hadithSeparator, lineWidth: 1)
            )
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .customStyle(.caption2)
            .tracking(1.1)
            .customForeground(.hadithMuted)
    }

    private var separator: some View {
        Color.hadithSeparator
            .frame(height: 1)
            .padding(.vertical, .sm)
    }
}
