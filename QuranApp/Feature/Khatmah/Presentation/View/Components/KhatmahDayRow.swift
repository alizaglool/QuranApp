//
//  KhatmahDayRow.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct KhatmahDayRow: View {

    let item: KhatmahDayItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .sm) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .customForeground(item.isCompleted ? .success : .outline)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .customStyle(.bodyMedium, .onSurface)
                    Text(item.pageRange)
                        .customStyle(.caption1, .subtitle)
                }

                Spacer(minLength: 0)

                Text(item.statusTitle)
                    .customStyle(.caption2, item.statusAccent)
                    .padding(.horizontal, .xSm)
                    .padding(.vertical, .xxSm)
                    .background(item.statusAccent.color.opacity(0.12))
                    .customCornerRadius(.cornerXxSm)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, .sm)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
