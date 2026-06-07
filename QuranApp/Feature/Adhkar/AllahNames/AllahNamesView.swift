//
//  AllahNamesView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-24.
//

import SwiftUI
import Core

struct AllahNamesView: View {

    let coordinator: AdhkarCoordinating
    let names: [AllahName]
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme

    private var isRTL: Bool { localizationManager.currentLanguage == .Arabic }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                NoIndicatorsScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerAccent
                        namesGrid
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Nav Bar

extension AllahNamesView {

    private var navBar: some View {
        HStack {
            Button(action: { coordinator.coordinateBack() }) {
                Image(systemName: isRTL ? "arrow.right" : "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .customCornerRadius(10)
            }
            Spacer()
            Text(AppLocalizedKeys.allahNamesTitle.value)
                .customStyle(.heading3, .onSurface)
            Spacer()
            Text("٩٩")
                .customStyle(.caption2, .onSurfaceVariant)
                .frame(width: 36)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    private var headerAccent: some View {
        Rectangle()
            .fill(ColorStyle.secondary.color)
            .frame(width: 48, height: 3)
            .customCornerRadius(2)
            .padding(.horizontal, .big)
            .padding(.top, .sm)
    }
}

// MARK: - Grid

extension AllahNamesView {

    private var namesGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(names.indices, id: \.self) { index in
                Button {
                    coordinator.coordinateToAllahNameDetail(names: names, startIndex: index)
                } label: {
                    AllahNameCard(name: names[index], colorScheme: colorScheme, isRTL: isRTL)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .big)
    }
}

// MARK: - Name Card

struct AllahNameCard: View {
    let name: AllahName
    let colorScheme: ColorScheme
    let isRTL: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(String(format: "%d", name.id))
                .customStyle(.adhkar(size: 10), .onSurfaceVariant)

            Text(name.nameAr.trimmingCharacters(in: .whitespaces))
                .customStyle(.adhkar(size: 17, bold: true), .primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.layoutDirection, .rightToLeft)

            if isRTL {
                Text(name.nameAr.trimmingCharacters(in: .whitespaces))
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let meaning = name.meaning {
                Text(meaning)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(name.transliteration)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ColorStyle.outlineVariant.color.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
        )
    }
}

