//
//  LessonPlayerView.swift
//  QuranApp
//

import SwiftUI
import YouTubePlayerKit
import Core

struct LessonPlayerView: View {
    @StateObject var viewModel: LessonPlayerViewModel

    init(source: LessonPlayerViewModel.PlayerSource, title: String, sheikhName: String) {
        _viewModel = StateObject(
            wrappedValue: LessonPlayerViewModel(source: source, title: title, sheikhName: sheikhName)
        )
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Main Content

extension LessonPlayerView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar
            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    playerView
                    playerInfo
                }
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension LessonPlayerView {

    var navBar: some View {
        HStack {
            BackButton(foregroundColor: .onSurface)
            Spacer()
            Text(viewModel.sheikhName)
                .customStyle(.subheadline, .onSurface)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Player

extension LessonPlayerView {

    var playerView: some View {
        YouTubePlayerView(viewModel.player)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, .big)
            .padding(.top, 16)
    }

    var playerInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.title)
                .customStyle(.subheadline, .onSurface)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.sheikhName)
                .customStyle(.bodySmall, .subtitle)
        }
        .padding(.horizontal, .big)
    }
}
