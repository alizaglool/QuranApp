//
//  AthkarSectionHeaderView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 27/10/2026.
//

import SwiftUI
import Core

struct AthkarSectionHeaderView: View {
    let title: String
    let subtitle: String
    let downloadTitle: String?
    let onDownloadAll: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: .sm) {
            VStack(alignment: .leading, spacing: .xxSm) {
                Text(title)
                    .customStyle(.heading3, .onSurface)
                    .multilineTextAlignment(.leading)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .customStyle(.caption2, .onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer(minLength: .xSm)

            if let downloadTitle {
                Button(action: onDownloadAll) {
                    HStack(spacing: .xxSm) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12, weight: .semibold))

                        Text(downloadTitle)
                            .customStyle(.caption1)
                            .lineLimit(1)
                    }
                    .customForeground(.primary)
                    .padding(.horizontal, .xSm)
                    .padding(.vertical, 6)
                    .background(ColorStyle.washPrimary.color)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
