//
//  GlobalSearchResultRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct GlobalSearchResultRow: View {

    let hit: GlobalSearchHit
    let snippet: AttributedString
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: .sm) {
                icon

                VStack(alignment: .leading, spacing: .xxSm + 2) {
                    header

                    if !hit.snippet.isEmpty {
                        Text(snippet)
                            .customStyle(snippetStyle)
                            .customForeground(.onSurface)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Image(systemName: "chevron.forward")
                    .font(.system(size: 11, weight: .semibold))
                    .customForeground(.onSurfaceVariant)
                    .padding(.top, 3)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Layout

private extension GlobalSearchResultRow {

    var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: .xSm) {
            Text(hit.title)
                .customStyle(.headline, .onSurface)
                .lineLimit(1)

            Spacer(minLength: 0)

            if !hit.detail.isEmpty {
                Text(hit.detail)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
            }
        }
    }

    var icon: some View {
        Image(systemName: iconName)
            .font(.system(size: 13, weight: .semibold))
            .customForeground(.primary)
            .frame(width: 28, height: 28)
            .background(Circle().fill(ColorStyle.primaryContainer.color))
    }

    var iconName: String {
        switch hit.scope {
        case .surah:     return "book.closed"
        case .verse:     return "text.quote"
        case .narration: return "quote.bubble"
        case .dhikr:     return "hands.sparkles"
        case .all:       return "magnifyingglass"
        }
    }

    var snippetStyle: AppTextStyle {
        switch hit.scope {
        case .verse:
            return .uthmanicNaskh(size: 17)
        case .narration:
            return .adhkar(size: 15)
        case .dhikr:
            return hit.isSnippetArabicScript ? .adhkar(size: 15) : .bodySmall
        case .surah, .all:
            return .bodySmall
        }
    }
}
