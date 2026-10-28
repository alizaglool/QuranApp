//
//  RecitersListView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 12/10/2026
//

import SwiftUI
import Core

// MARK: - RecitersListView

struct RecitersListView: View {

    @StateObject private var viewModel: RecitersListViewModel
    @ObservedObject private var audio = AudioEngine.library

    init(coordinator: any RecitationsCoordinating) {
        _viewModel = StateObject(wrappedValue: RecitersListViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension RecitersListView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionAccent
                    content
                }
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

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.title)
                    .customStyle(.heading3, .onSurface)
                Text(viewModel.subtitle)
                    .customStyle(.caption1, .subtitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    var sectionAccent: some View {
        Rectangle()
            .fill(ColorStyle.secondary.color)
            .frame(width: 48, height: 3)
            .customCornerRadius(2)
            .padding(.horizontal, .big)
    }

    @ViewBuilder
    var content: some View {
        if viewModel.isLoading {
            skeletonList
        } else {
            reciterList
        }
    }

    var reciterList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.reciters) { reciter in
                Button {
                    viewModel.onReciterTapped(reciter)
                } label: {
                    ReciterCardView(
                        reciter: reciter,
                        detail: viewModel.detailText(for: reciter),
                        isActive: audio.currentReciter.id == reciter.id
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .big)
    }

    var skeletonList: some View {
        VStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.surfaceContainerHigh)
                    .frame(height: 88)
                    .withShimmerOverlay()
                    .redacted(reason: .placeholder)
            }
        }
        .padding(.horizontal, .big)
    }
}
