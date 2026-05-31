//
//  AllahNameReadingView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-24.
//

import SwiftUI
import Core

struct AllahNameReadingView: View {

    let coordinator: AdhkarCoordinating
    let names: [AllahName]

    @State private var currentIndex: Int
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) private var colorScheme

    private var isRTL: Bool { localizationManager.currentLanguage == .Arabic }
    private var current: AllahName { names[currentIndex] }

    init(coordinator: AdhkarCoordinating, names: [AllahName], startIndex: Int) {
        self.coordinator = coordinator
        self.names = names
        _currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.background.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar
                pageContent
                pageIndicator
                bottomBar
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Nav Bar

extension AllahNameReadingView {

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
            Text(String(format: "%d/%d", currentIndex + 1, names.count))
                .customStyle(.caption2, .onSurfaceVariant)
                .frame(minWidth: 36)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Page Content

extension AllahNameReadingView {

    private var pageContent: some View {
        TabView(selection: $currentIndex) {
            ForEach(names.indices, id: \.self) { index in
                NamePageView(
                    name: names[index],
                    colorScheme: colorScheme,
                    isRTL: isRTL
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.25), value: currentIndex)
    }
}

// MARK: - Page Indicator

extension AllahNameReadingView {

    private var pageIndicator: some View {
        HStack(spacing: 5) {
            let visibleRange = indicatorRange()
            ForEach(visibleRange, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex
                          ? ColorStyle.primary.color
                          : ColorStyle.outlineVariant.color.opacity(0.5))
                    .frame(width: index == currentIndex ? 8 : 5,
                           height: index == currentIndex ? 8 : 5)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
        .padding(.vertical, 8)
    }

    private func indicatorRange() -> [Int] {
        let total = names.count
        let half = 4
        let start = max(0, min(currentIndex - half, total - (half * 2 + 1)))
        let end = min(total - 1, start + half * 2)
        return Array(start...end)
    }
}

// MARK: - Bottom Bar

extension AllahNameReadingView {

    private var bottomBar: some View {
        HStack(spacing: 0) {
            Button(action: previous) {
                VStack(spacing: 2) {
                    Image(systemName: isRTL ? "chevron.right" : "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .customForeground(currentIndex > 0 ? .primary : .onSurfaceVariant)
                    if currentIndex > 0 {
                        Text(names[currentIndex - 1].nameAr.trimmingCharacters(in: .whitespaces))
                            .customStyle(.adhkar(size: 11, bold: true), .onSurfaceVariant)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(currentIndex == 0)

            Spacer()

            ZStack {
                Circle()
                    .fill(ColorStyle.secondary.color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .frame(width: 44, height: 44)
                Text(String(format: "%d", current.id))
                    .customStyle(.adhkar(size: 16, bold: true), .secondary)
            }

            Spacer()

            Button(action: share) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18))
                    .customForeground(.onSurface)
                    .frame(width: 40, height: 40)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Button(action: next) {
                VStack(spacing: 2) {
                    Image(systemName: isRTL ? "chevron.left" : "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .customForeground(currentIndex < names.count - 1 ? .primary : .onSurfaceVariant)
                    if currentIndex < names.count - 1 {
                        Text(names[currentIndex + 1].nameAr.trimmingCharacters(in: .whitespaces))
                            .customStyle(.adhkar(size: 11, bold: true), .onSurfaceVariant)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .disabled(currentIndex == names.count - 1)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, 12)
        .background(Color.surfaceContainerLow)
    }

    private func previous() {
        guard currentIndex > 0 else { return }
        withAnimation { currentIndex -= 1 }
    }

    private func next() {
        guard currentIndex < names.count - 1 else { return }
        withAnimation { currentIndex += 1 }
    }

    private func share() {
        let text = "\(current.nameAr.trimmingCharacters(in: .whitespaces)) — \(current.transliteration)"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
    }
}

// MARK: - Name Page View

struct NamePageView: View {
    let name: AllahName
    let colorScheme: ColorScheme
    let isRTL: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Spacer(minLength: 16)

                Text(name.nameAr.trimmingCharacters(in: .whitespaces))
                    .customStyle(.adhkar(size: 52, bold: true), .primary)
                    .multilineTextAlignment(.center)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, .big)

                Text(name.transliteration)
                    .customStyle(.heading3, .onSurfaceVariant)
                    .multilineTextAlignment(.center)

                if let meaning = name.meaning {
                    Text(meaning)
                        .customStyle(.bodySmall, .onSurfaceVariant)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .big)
                }

                Rectangle()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                    .frame(height: 1)
                    .padding(.horizontal, 40)

                if let desc = name.descriptionAr {
                    Text(desc)
                        .customStyle(.adhkar(size: 17), .onSurface)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(6)
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.horizontal, .big)
                }

                Spacer(minLength: 40)
            }
        }
    }
}
