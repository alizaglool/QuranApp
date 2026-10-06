//
//  MyAdhkarCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 26/09/2026
//

import SwiftUI
import Core

struct MyAdhkarCard: View {
    let dhikr: MyDhikr
    let index: Int
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ColorStyle.washPrimary.color)
                        .frame(width: 36, height: 36)
                    Text("\(index)")
                        .customStyle(.adhkar(size: 13, bold: true), .primary)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text(dhikr.textAr)
                        .customStyle(.quranPageFixed(size: 17), .onSurface)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    Text("\(dhikr.count) مرة")
                        .customStyle(.caption2, .onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .customForeground(.onSurfaceVariant)
                        .padding(8)
                }
            }
            .padding(14)
            .background(Color.cardSurface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
