//
//  HadithDetailTabStrip.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 25/10/2026.
//

import SwiftUI
import Core

struct HadithDetailTabStrip: View {
    let tabs: [HadithDetailTabItem]
    let selection: HadithDetailTab
    let onSelect: (HadithDetailTab) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .xSm) {
                ForEach(tabs) { item in
                    pill(item)
                }
            }
            .padding(.horizontal, .big)
            .padding(.vertical, .xxSm)
        }
    }

    private func pill(_ item: HadithDetailTabItem) -> some View {
        let isSelected = item.tab == selection

        return Button {
            onSelect(item.tab)
        } label: {
            HStack(spacing: .xxSm + 2) {
                Image(systemName: item.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(item.title)
                    .customStyle(.kitab(size: 13, bold: true))
                    .lineLimit(1)
                if item.count > 1 {
                    Text("\(item.count)")
                        .customStyle(.kitab(size: 10, bold: true))
                        .padding(.horizontal, .xxSm + 1)
                        .padding(.vertical, 1)
                        .background(
                            Capsule().fill(isSelected ? Color.hadithBg.opacity(0.25)
                                                      : Color.hadithSeparator)
                        )
                }
            }
            .foregroundColor(isSelected ? Color.hadithBg : Color.hadithSecondary)
            .padding(.horizontal, .sm + 2)
            .padding(.vertical, .xSm)
            .background(
                Capsule().fill(isSelected ? Color.hadithGold : Color.hadithCard)
            )
            .overlay(
                Capsule().strokeBorder(isSelected ? Color.clear : Color.hadithSeparator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}
