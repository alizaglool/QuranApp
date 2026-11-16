//
//  GuideTextBlockView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct GuideTextBlockView: View {

    let block: GuideTextBlock

    var body: some View {
        switch block.segment {
        case .heading(let text):
            heading(text)
        case .instruction(let text):
            instruction(text)
        case .supplication(let text):
            supplication(text)
        case .narration(let text):
            narration(text)
        case .revelation(let text, let reference):
            revelation(text, reference: reference)
        }
    }

    // MARK: - Heading

    private func heading(_ text: String) -> some View {
        Text(GuideTextParser.attributed(text))
            .customStyle(.subheadline, .onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, .xSm)
    }

    // MARK: - Instruction

    private func instruction(_ text: String) -> some View {
        Text(GuideTextParser.attributed(text))
            .customStyle(.bodyMedium, .onSurface)
            .lineSpacing(7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Supplication

    private func supplication(_ text: String) -> some View {
        HStack(alignment: .top, spacing: .sm) {
            Capsule()
                .fill(ColorStyle.primary.color)
                .frame(width: 3)
            Text(GuideTextParser.attributed(text))
                .customStyle(.adhkar(size: 19), .onSurface)
                .lineSpacing(9)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, .sm)
        .padding(.horizontal, .sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.washPrimary)
        .clipShape(RoundedRectangle(cornerRadius: .cornerMd, style: .continuous))
    }

    // MARK: - Narration

    private func narration(_ text: String) -> some View {
        HStack(alignment: .top, spacing: .sm) {
            Capsule()
                .fill(ColorStyle.secondary.color)
                .frame(width: 3)
            Text(GuideTextParser.attributed(text))
                .customStyle(.adhkar(size: 17), .onSurfaceVariant)
                .lineSpacing(8)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, .xSm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Revelation

    private func revelation(_ text: String, reference: String) -> some View {
        VStack(spacing: .xSm) {
            Text(GuideTextParser.attributed(text))
                .customStyle(.quranPageFixed(size: 21), .quranText)
                .lineSpacing(10)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if !reference.isEmpty {
                Text(reference)
                    .customStyle(.caption2, .outline)
            }
        }
        .padding(.vertical, .md)
        .padding(.horizontal, .sm)
        .frame(maxWidth: .infinity)
        .background(Color.washSecondarySubtle)
        .clipShape(RoundedRectangle(cornerRadius: .cornerMd, style: .continuous))
    }
}

// MARK: - GuideTextBlocksView

struct GuideTextBlocksView: View {

    let blocks: [GuideTextBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: .sm) {
            ForEach(blocks) { block in
                GuideTextBlockView(block: block)
            }
        }
    }
}
