//
//  HadithReadingView.swift
//  QuranApp
//
//  Created by Ali M. Zaghloul on 2026-05-25.
//

import SwiftUI
import Core

struct HadithReadingView: View {

    @StateObject private var viewModel: HadithReadingViewModel
    @EnvironmentObject private var localizationManager: LocalizationManager
    @Environment(\.colorScheme) var colorScheme
    @State private var showShareSheet: Bool = false

    private var accentColor: Color {
        let hex = viewModel.book.colorHex
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        return Color(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue: Double(int         & 0xFF) / 255
        )
    }

    private var isArabic: Bool { localizationManager.currentLanguage == .Arabic }

    init(coordinator: HadithCoordinating, hadiths: [HadithEntry], startIndex: Int, book: HadithBook) {
        _viewModel = StateObject(
            wrappedValue: HadithReadingViewModel(
                coordinator: coordinator,
                hadiths: hadiths,
                startIndex: startIndex,
                book: book
            )
        )
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            ZStack {
                Color.background.ignoresSafeArea()
                ambientGlow
                VStack(spacing: 0) {
                    navBar
                    progressBar
                    hadithPager
                    Spacer(minLength: 0)
                    actionBar
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let hadith = viewModel.currentHadith {
                ShareSheet(items: ["\(hadith.arabicText)\n\n\(hadith.translation)\n\n— \(hadith.narrator)"])
            }
        }
    }
}

// MARK: - Nav Bar

extension HadithReadingView {

    private var navBar: some View {
        HStack {
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .medium))
                    .customForeground(.onSurface)
                    .frame(width: 36, height: 36)
                    .background(Color.surfaceContainerLow)
                    .cornerRadius(10)
            }

            Spacer()

            Text(isArabic ? viewModel.book.titleAr : viewModel.book.titleEn)
                .customStyle(.heading3, .onSurface)
                .lineLimit(1)

            Spacer()

            Text("\(String(format: "%d", viewModel.currentIndex + 1)) / \(String(format: "%d", viewModel.hadiths.count))")
                .customStyle(.caption2, .onSurfaceVariant)
                .monospacedDigit()
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.surfaceContainerLow.frame(height: 2)
                accentColor
                    .frame(width: geo.size.width * viewModel.progress, height: 2)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 2)
    }
}

// MARK: - Hadith Pager

extension HadithReadingView {

    private var hadithPager: some View {
        TabView(selection: Binding(
            get: { viewModel.currentIndex },
            set: { viewModel.currentIndex = $0 }
        )) {
            ForEach(viewModel.hadiths.indices, id: \.self) { index in
                HadithPageView(
                    hadith: viewModel.hadiths[index],
                    accentColor: accentColor,
                    colorScheme: colorScheme
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: viewModel.currentIndex)
    }
}

// MARK: - Action Bar

extension HadithReadingView {

    private var actionBar: some View {
        HStack(spacing: 0) {
            navButton(
                icon: "arrow.right",
                enabled: viewModel.canGoPrevious,
                action: { viewModel.previous() }
            )

            Spacer()

            HStack(spacing: 20) {
                actionButton(icon: "play.circle", label: AppLocalizedKeys.play.value, enabled: false) {}

                actionButton(
                    icon: viewModel.isFavorite ? "bookmark.fill" : "bookmark",
                    label: AppLocalizedKeys.bookmark.value,
                    enabled: true,
                    tint: viewModel.isFavorite ? accentColor : nil
                ) { viewModel.toggleFavorite() }

                actionButton(icon: "square.and.arrow.up", label: AppLocalizedKeys.share.value, enabled: true) {
                    showShareSheet = true
                }
            }

            Spacer()

            navButton(
                icon: "arrow.left",
                enabled: viewModel.canGoNext,
                action: { viewModel.next() }
            )
        }
        .padding(.horizontal, .big)
    }

    private func navButton(icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .customForeground(enabled ? .primary : .onSurfaceVariant)
                .frame(width: 48, height: 48)
                .background(
                    enabled ? ColorStyle.primary.color.opacity(0.08) : Color.surfaceContainerLow
                )
                .cornerRadius(14)
        }
        .disabled(!enabled)
    }

    private func actionButton(icon: String, label: String, enabled: Bool, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(tint ?? (enabled ? ColorStyle.onSurface.color : ColorStyle.onSurfaceVariant.color))
                Text(label)
                    .customStyle(.caption2, enabled ? .onSurface : .onSurfaceVariant)
            }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }
}

// MARK: - Ambient Glow

extension HadithReadingView {

    private var ambientGlow: some View {
        ZStack {
            Circle()
                .fill(accentColor.opacity(0.04))
                .frame(width: 280, height: 280)
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

// MARK: - Hadith Page

struct HadithPageView: View {
    let hadith: HadithEntry
    let accentColor: Color
    let colorScheme: ColorScheme

    var body: some View {
        NoIndicatorsScrollView {
            VStack(spacing: 28) {
                accentLine

                Text(hadith.arabicText)
                    .font(.custom("HafsSmart_08_fixed", size: 20))
                    .foregroundColor(ColorStyle.onSurface.color)
                    .multilineTextAlignment(.center)
                    .lineSpacing(14)
                    .environment(\.layoutDirection, .rightToLeft)
                    .padding(.horizontal, .big)

                Divider()
                    .padding(.horizontal, .big)

                Text(hadith.translation)
                    .customStyle(.bodySmall, .onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, .big)

                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .customForeground(.onSurfaceVariant)
                    Text(hadith.narrator)
                        .customStyle(.caption1, .onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }

                if !hadith.grade.isEmpty {
                    Text(hadith.grade)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.10))
                        .cornerRadius(6)
                }

                Spacer(minLength: 60)
            }
            .padding(.top, 28)
        }
    }

    private var accentLine: some View {
        Rectangle()
            .fill(accentColor)
            .frame(width: 48, height: 3)
            .cornerRadius(2)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
