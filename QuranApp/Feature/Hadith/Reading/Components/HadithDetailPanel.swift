//
//  HadithDetailPanel.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import SwiftUI
import Core

struct HadithDetailPanel: View {
    let presentation: HadithDetailPresentation
    let tab: HadithDetailTab
    let onLink: (HadithBodyLink) -> Void

    var body: some View {
        card {
            switch tab {
            case .commentary:  prose(presentation.commentary)
            case .rulings:     rulings
            case .narrators:   narrators
            case .takhrij:     takhrij
            case .ghareeb:     ghareeb
            case .notes:       notes
            case .subjects:    subjects
            case .translation: translation
            case .info:        info
            }
        }
    }

    // MARK: Panels

    private var rulings: some View {
        stack(presentation.rulings) { ruling in
            VStack(alignment: .leading, spacing: .xxSm + 1) {
                HStack(alignment: .firstTextBaseline, spacing: .xSm) {
                    Circle()
                        .fill(ruling.tone.color)
                        .frame(width: 7, height: 7)
                        .padding(.top, 5)
                    Text(ruling.text)
                        .customStyle(.adhkar(size: 16, bold: true))
                        .foregroundColor(ruling.tone.color)
                        .fixedSize(horizontal: false, vertical: true)
                }
                caption([ruling.scholar, ruling.source])
            }
            .rtlRow()
        }
    }

    private var narrators: some View {
        stack(presentation.narrators) { row in
            Button {
                onLink(.narrator(row.id))
            } label: {
                HStack(spacing: .sm) {
                    Text("\(row.order)")
                        .customStyle(.kitab(size: 11, bold: true))
                        .customForeground(.hadithGold)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.hadithGold.opacity(0.15)))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .customStyle(.adhkar(size: 16))
                            .customForeground(.hadithArabicText)
                            .fixedSize(horizontal: false, vertical: true)
                        if !row.layerLabel.isEmpty {
                            Text(row.layerLabel)
                                .customStyle(.caption2)
                                .customForeground(.hadithMuted)
                        }
                    }
                    Spacer(minLength: .xSm)
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 11, weight: .semibold))
                        .customForeground(.hadithMuted)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .rtlRow()
        }
    }

    private var takhrij: some View {
        VStack(alignment: .leading, spacing: .md) {
            ForEach(presentation.takhrij) { section in
                VStack(alignment: .leading, spacing: .xSm) {
                    heading(section.title)
                    ForEach(section.groups) { group in
                        HStack(alignment: .firstTextBaseline, spacing: .xSm) {
                            Text(group.bookName)
                                .customStyle(.adhkar(size: 15))
                                .customForeground(.hadithArabicText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: .xSm)
                            Text(group.numbersLabel)
                                .customStyle(.kitab(size: 13, bold: true))
                                .customForeground(.hadithGold)
                                .multilineTextAlignment(.trailing)
                        }
                        .rtlRow()
                    }
                }
            }
        }
    }

    private var ghareeb: some View {
        stack(presentation.ghareeb) { meaning in
            Button {
                onLink(.ghareeb(meaning.id))
            } label: {
                VStack(alignment: .leading, spacing: .xxSm) {
                    Text(meaning.word)
                        .customStyle(.adhkar(size: 16, bold: true))
                        .customForeground(.hadithGreen)
                    Text(meaning.meaning)
                        .customStyle(.adhkar(size: 15))
                        .customForeground(.hadithSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .rtlRow()
        }
    }

    private var notes: some View {
        stack(presentation.notes) { note in
            Button {
                onLink(.note(note.id))
            } label: {
                HStack(alignment: .top, spacing: .xSm) {
                    Text(note.marker)
                        .customStyle(.kitab(size: 13, bold: true))
                        .customForeground(.hadithGold)
                    Text(note.text)
                        .customStyle(.adhkar(size: 15))
                        .customForeground(.hadithSecondary)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .rtlRow()
        }
    }

    private var subjects: some View {
        stack(presentation.subjects) { path in
            Text(path.label)
                .customStyle(.adhkar(size: 15))
                .customForeground(.hadithArabicText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .rtlRow()
        }
    }

    private var translation: some View {
        Text(presentation.translation)
            .customStyle(.bodyMedium, .hadithSecondary)
            .lineSpacing(6)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, .leftToRight)
    }

    private var info: some View {
        stack(presentation.info) { row in
            VStack(alignment: .leading, spacing: 2) {
                heading(row.label)
                Text(row.value)
                    .customStyle(.adhkar(size: 15))
                    .customForeground(.hadithArabicText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .rtlRow()
        }
    }

    // MARK: Building blocks

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: .cornerLg).fill(Color.hadithCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerLg)
                    .strokeBorder(Color.hadithSeparator, lineWidth: 1)
            )
    }

    private func prose(_ text: String) -> some View {
        Text(text)
            .customStyle(.adhkar(size: 16))
            .customForeground(.hadithArabicText)
            .lineSpacing(8)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .rtlRow()
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .customStyle(.caption2)
            .tracking(1.1)
            .customForeground(.hadithMuted)
    }

    @ViewBuilder
    private func caption(_ parts: [String]) -> some View {
        let text = parts.filter { !$0.isEmpty }.joined(separator: " · ")
        if !text.isEmpty {
            Text(text)
                .customStyle(.caption1)
                .customForeground(.hadithMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func stack<Item: Identifiable, Row: View>(
        _ items: [Item],
        @ViewBuilder row: @escaping (Item) -> Row
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                row(item)
                if index < items.count - 1 {
                    Color.hadithSeparator
                        .frame(height: 1)
                        .padding(.vertical, .sm)
                }
            }
        }
    }
}

private extension View {
    func rtlRow() -> some View {
        environment(\.layoutDirection, .rightToLeft)
            .multilineTextAlignment(.trailing)
    }
}
