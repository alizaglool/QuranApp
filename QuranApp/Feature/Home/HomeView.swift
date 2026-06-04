//
//  HomeView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 2026-03-23.
//

import SwiftUI
import Core

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme

    init(coordinator: HomeCoordinating) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Main Content

extension HomeView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(spacing: 24) {
                    welcomeSection
                    prayerTimesSection
                    quickAccessGrid
                    if viewModel.lastReadPage != nil {
                        continueReadingCard
                    }
                    hadithOfTheDayCard
                    featuredLessonsSection
                }
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }
}

// MARK: - Nav Bar

extension HomeView {

    var navBar: some View {
        HStack {
            Text("Wird")
                .customStyle(.heading3, .primary)

            Spacer()

            Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .medium))
                    .customForeground(.primary)
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}
