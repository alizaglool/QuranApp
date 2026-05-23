//
//  HadithReadingView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-23.
//

import SwiftUI
import Core

struct HadithReadingView: View {

    @StateObject private var vm: HadithReadingViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager

    init(collection: HadithCollection) {
        _vm = StateObject(wrappedValue: HadithReadingViewModel(collection: collection))
    }

    var body: some View {
        MainView(viewModel: vm) {
            ZStack {
                Color.background.ignoresSafeArea()
                ambientGlow
                VStack(spacing: 0) {
                    navBar
                    hadithContent
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Nav Bar

extension HadithReadingView {

    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(10)
            }

            Spacer()

            Text(localizationManager.currentLanguage == .Arabic ? vm.collection.nameAr : vm.collection.nameEn)
                .customStyle(.heading3, .onSurface)

            Spacer()

            Text("\(vm.currentIndex + 1) / \(vm.collection.hadiths.count)")
                .customStyle(.caption2, .onSurfaceVariant)
                .monospacedDigit()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Hadith Content

extension HadithReadingView {

    private var hadithContent: some View {
        VStack(spacing: 0) {
            progressBar

            Spacer()

            if let hadith = vm.currentHadith {
                hadithCard(hadith: hadith)
            }

            Spacer()

            navigationControls
                .padding(.bottom, 40)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.surfaceContainerLow.frame(height: 2)
                ColorStyle.secondary.color
                    .frame(width: geo.size.width * vm.progress, height: 2)
                    .animation(.easeInOut(duration: 0.3), value: vm.progress)
            }
        }
        .frame(height: 2)
    }

    private func hadithCard(hadith: Hadith) -> some View {
        VStack(spacing: 24) {
            Rectangle()
                .fill(ColorStyle.secondary.color)
                .frame(width: 40, height: 3)
                .cornerRadius(2)

            Text(hadith.textAr)
                .font(.custom("HafsSmart_08_fixed", size: 20))
                .foregroundColor(ColorStyle.onSurface.color)
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .environment(\.layoutDirection, .rightToLeft)
                .padding(.horizontal, .big)

            if !hadith.reference.isEmpty {
                Text(hadith.reference)
                    .customStyle(.caption1, .secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 20) {
            Button(action: { vm.previous() }) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(vm.canGoPrevious ? .primary : .onSurfaceVariant)
                    .frame(width: 52, height: 52)
                    .background(
                        vm.canGoPrevious
                        ? ColorStyle.primary.color.opacity(0.08)
                        : Color.surfaceContainerLow
                    )
                    .cornerRadius(14)
            }
            .disabled(!vm.canGoPrevious)

            VStack(spacing: 4) {
                Text("\(vm.currentIndex + 1)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .customForeground(.primary)
                Text("/ \(vm.collection.hadiths.count)")
                    .customStyle(.caption2, .onSurfaceVariant)
            }
            .frame(width: 60)

            Button(action: { vm.next() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(vm.canGoNext ? .primary : .onSurfaceVariant)
                    .frame(width: 52, height: 52)
                    .background(
                        vm.canGoNext
                        ? ColorStyle.primary.color.opacity(0.08)
                        : Color.surfaceContainerLow
                    )
                    .cornerRadius(14)
            }
            .disabled(!vm.canGoNext)
        }
    }
}

// MARK: - Ambient Glow

extension HadithReadingView {

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(ColorStyle.secondary.color.opacity(0.04))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 60, y: -120)

            Circle()
                .fill(ColorStyle.primary.color.opacity(0.03))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -80, y: 200)
        }
        .allowsHitTesting(false)
    }
}
