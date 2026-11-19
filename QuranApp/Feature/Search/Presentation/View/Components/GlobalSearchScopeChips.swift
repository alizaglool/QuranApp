//
//  GlobalSearchScopeChips.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 17/11/2026.
//

import SwiftUI
import Core

struct GlobalSearchScopeChips: View {

    let scopes: [GlobalSearchScope]
    let selectedScope: GlobalSearchScope
    let title: (GlobalSearchScope) -> String
    let onSelect: (GlobalSearchScope) -> Void

    var body: some View {
        NoIndicatorsScrollView(.horizontal) {
            HStack(spacing: .xSm) {
                ForEach(scopes) { scope in
                    chip(scope)
                }
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - Chip

private extension GlobalSearchScopeChips {

    func chip(_ scope: GlobalSearchScope) -> some View {
        let isSelected = scope == selectedScope
        return Button { onSelect(scope) } label: {
            Text(title(scope))
                .customStyle(.caption1, isSelected ? .onPrimaryContainer : .onSurfaceVariant)
                .padding(.horizontal, .md)
                .padding(.vertical, .xSm)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? ColorStyle.primaryContainer.color
                              : ColorStyle.surfaceContainerLow.color)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(Color.outlineVariant.opacity(isSelected ? 0 : 0.18),
                                      lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }
}
