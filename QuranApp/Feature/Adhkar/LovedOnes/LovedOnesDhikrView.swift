//
//  LovedOnesDhikrView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-24.
//

import SwiftUI
import Core

struct LovedOnesDhikrView: View {

    let coordinator: AdhkarCoordinating
    let category: DhikrCategory
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    @State private var personName: String = ""
    @FocusState private var isNameFocused: Bool

    private var adhkar: [Dhikr] { category.adhkar }

    private func substitute(_ text: String) -> String {
        let name = personName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return text }
        return text.replacingOccurrences(of: "{الاسم}", with: name)
    }

    var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                nameInputSection
                adhkarScrollList
            }
        }
        .navigationBarHidden(true)
        .onTapGesture { isNameFocused = false }
    }
}

// MARK: - Nav Bar

extension LovedOnesDhikrView {

    private var navBar: some View {
        HStack {
            Button(action: { coordinator.coordinateBack() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(10)
            }
            Spacer()
            Text(category.titleAr)
                .customStyle(.heading3, .onSurface)
            Spacer()
            Text("\(adhkar.count)")
                .customStyle(.caption2, .onSurfaceVariant)
                .frame(width: 36)
                .monospacedDigit()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Name Input

extension LovedOnesDhikrView {

    private var nameInputSection: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(ColorStyle.secondary.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.fill")
                        .font(.system(size: 15))
                        .foregroundColor(ColorStyle.secondary.color)
                }

                TextField("اكتب الاسم هنا…", text: $personName)
                    .font(.custom("HafsSmart_08_fixed", size: 18))
                    .multilineTextAlignment(.trailing)
                    .environment(\.layoutDirection, .rightToLeft)
                    .focused($isNameFocused)

                if !personName.isEmpty {
                    Button(action: { personName = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ColorStyle.onSurfaceVariant.color)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isNameFocused
                            ? ColorStyle.secondary.color.opacity(0.5)
                            : ColorStyle.outlineVariant.color.opacity(0.15),
                        lineWidth: 1
                    )
            )

            if personName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("أدخل اسم من تدعو له لتظهر أدعية مخصصة")
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, .big)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .animation(.easeOut(duration: 0.2), value: isNameFocused)
    }
}

// MARK: - Adhkar List

extension LovedOnesDhikrView {

    private var adhkarScrollList: some View {
        NoIndicatorsScrollView {
            LazyVStack(spacing: 14) {
                ForEach(adhkar) { dhikr in
                    dhikrCard(dhikr)
                }
            }
            .padding(.horizontal, .big)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .onTapGesture { isNameFocused = false }
    }

    private func dhikrCard(_ dhikr: Dhikr) -> some View {
        VStack(spacing: 14) {
            Text(substitute(dhikr.textAr))
                .font(.custom("HafsSmart_08_fixed", size: 24))
                .foregroundColor(ColorStyle.onSurface.color)
                .multilineTextAlignment(.center)
                .lineSpacing(10)
                .environment(\.layoutDirection, .rightToLeft)
                .frame(maxWidth: .infinity)
                .animation(.easeOut(duration: 0.15), value: personName)

            if let title = dhikr.title, !title.isEmpty {
                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.25))
                    .frame(height: 0.5)

                Text(title)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(colorScheme == .dark ? Color.surfaceContainerLow : Color.surfaceContainerLowest)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ColorStyle.outlineVariant.color.opacity(0.1), lineWidth: 1)
        )
    }
}
