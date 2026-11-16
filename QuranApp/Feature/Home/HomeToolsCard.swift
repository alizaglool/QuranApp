//
//  HomeToolsCard.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026
//

import SwiftUI
import Core

struct HomeToolsCard: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        HStack(alignment: .top, spacing: .xxSm) {
            ForEach(viewModel.quickAccessItems) { item in
                QuickAccessCard(item: item) {
                    viewModel.onQuickAccessTapped(item)
                }
            }
        }
        .padding(.horizontal, .xSm)
        .padding(.vertical, .sm)
        .background(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .fill(Color.cardSurface)
        )
        .clipShape(RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
        .padding(.horizontal, .big)
    }
}
