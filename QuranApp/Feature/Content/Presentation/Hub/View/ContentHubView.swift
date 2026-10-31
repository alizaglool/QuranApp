//
//  ContentHubView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 31/10/2026.
//

import SwiftUI
import Core

struct ContentHubView: View {

    @StateObject private var viewModel: ContentHubViewModel

    init(coordinator: any ContentCoordinating) {
        _viewModel = StateObject(wrappedValue: ContentHubViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension ContentHubView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .sm) {
                    if viewModel.hasEntries {
                        ForEach(viewModel.entries) { entry in
                            entryCard(entry)
                        }
                    } else {
                        emptyCard
                    }
                }
                .padding(.horizontal, .big)
                .padding(.top, .sm)
                .padding(.bottom, .xxxBig)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel(viewModel.backAccessibilityLabel)

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.screenTitle)
                    .customStyle(.heading3, .onSurface)
                Text(viewModel.screenSubtitle)
                    .customStyle(.caption1, .subtitle)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Entries

private extension ContentHubView {

    func entryCard(_ entry: ContentHubEntry) -> some View {
        Button {
            viewModel.onEntryTapped(entry)
        } label: {
            HStack(alignment: .top, spacing: .sm) {
                AccentIconTile(icon: entry.icon, accent: entry.accent)

                VStack(alignment: .leading, spacing: .xxSm) {
                    Text(entry.title)
                        .customStyle(.headline, .onSurface)
                        .multilineTextAlignment(.leading)

                    Text(entry.subtitle)
                        .customStyle(.bodySmall, .subtitle)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(entry.topicsText)
                        .customStyle(.caption2, .outline)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .customForeground(.outline)
                    .padding(.top, .xxSm)
            }
            .padding(.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contentCardChrome()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    var emptyCard: some View {
        Text(viewModel.emptyMessage)
            .customStyle(.bodySmall, .subtitle)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.md)
            .contentCardChrome()
    }
}

// MARK: - ContentCardChrome

struct ContentCardChrome: ViewModifier {

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: .cornerXxl)
                    .fill(Color.cardSurface)
            )
            .clipShape(RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerXxl)
                    .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
            )
    }
}

extension View {

    func contentCardChrome() -> some View {
        modifier(ContentCardChrome())
    }
}
