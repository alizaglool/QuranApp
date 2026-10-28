//
//  ReciterSurahsView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core
import SDWebImageSwiftUI

// MARK: - ReciterSurahsView

struct ReciterSurahsView: View {

    @StateObject private var viewModel: ReciterSurahsViewModel
    @ObservedObject private var audio = AudioEngine.library

    init(coordinator: any RecitationsCoordinating, reciter: ReciterInfo) {
        _viewModel = StateObject(
            wrappedValue: ReciterSurahsViewModel(coordinator: coordinator, reciter: reciter)
        )
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension ReciterSurahsView {

    var mainContent: some View {
        VStack(spacing: 0) {
            header
            NoIndicatorsScrollView {
                surahList
                    .padding(.top, .sm)
                    .padding(.bottom, 32)
            }
            if audio.hasActiveVerse {
                RecitationsPlayerBar()
                    .environmentObject(AudioEngine.library)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .animation(.easeInOut(duration: 0.22), value: audio.hasActiveVerse)
    }

    var header: some View {
        HStack(spacing: 12) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            avatar

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.reciterName)
                    .customStyle(.kitab(size: 17, bold: true), .onSurface)
                    .lineLimit(1)
                Text(viewModel.reciterSubtitle)
                    .customStyle(.caption1, .subtitle)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    var avatar: some View {
        WebImage(url: URL(string: viewModel.reciter.imageURL ?? "")) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .fill(Color.surfaceContainerHigh)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .customForeground(.onSurfaceVariant)
                )
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(ColorStyle.secondary.color.opacity(0.2), lineWidth: 2)
        )
    }

    var surahList: some View {
        LazyVStack(spacing: 10) {
            ForEach(viewModel.surahs) { surah in
                Button {
                    viewModel.onSurahTapped(surah)
                } label: {
                    ReciterSurahRowView(
                        surah: surah,
                        versesText: viewModel.versesText(for: surah),
                        originText: viewModel.originText(for: surah),
                        isActive: viewModel.isActive(surah),
                        isPlaying: audio.isPlaying
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .big)
    }
}
