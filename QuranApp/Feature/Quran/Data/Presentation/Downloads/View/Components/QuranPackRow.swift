//
//  QuranPackRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import SwiftUI
import Core

struct QuranPackRow: View {

    let item: QuranPackRowItem
    let state: ContentDownloadState
    let bundledLabel: String
    let isWaitingForNetwork: Bool
    let waitingLabel: String
    let onAction: () -> Void

    var body: some View {
        HStack(spacing: .sm) {
            juzTile

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .customStyle(.bodyMedium, .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(detailLabel)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)

            Spacer(minLength: .xSm)

            trailing
        }
        .padding(.vertical, .xSm)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.title)
        .accessibilityValue(detailLabel)
    }
}

// MARK: - Pieces

private extension QuranPackRow {

    var detailLabel: String {
        if isWaitingForNetwork { return waitingLabel }
        return item.isBundled ? item.pagesLabel : "\(item.pagesLabel) · \(item.sizeLabel)"
    }

    var juzTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: .cornerXSm)
                .fill(ColorStyle.quickAccentQuran.color.opacity(isAvailable ? 0.16 : 0.08))
                .frame(width: 40, height: 40)

            Image(systemName: "book.pages")
                .font(.system(size: 16))
                .customForeground(isAvailable ? .quickAccentQuran : .onSurfaceVariant)
        }
    }

    var isAvailable: Bool {
        if item.isBundled { return true }
        if case .downloaded = state { return true }
        return false
    }

    @ViewBuilder
    var trailing: some View {
        if item.isBundled {
            bundledBadge
        } else if case .downloaded = state {
            installedBadge
        } else {
            AthkarDownloadControl(state: state, action: onAction)
        }
    }

    var bundledBadge: some View {
        Text(bundledLabel)
            .customStyle(.caption2, .onSurfaceVariant)
            .lineLimit(1)
            .padding(.horizontal, .xSm)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(ColorStyle.outlineVariant.color.opacity(0.18))
            )
    }

    var installedBadge: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 19))
            .customForeground(.quickAccentQuran)
            .frame(width: 36, height: 36)
    }
}
