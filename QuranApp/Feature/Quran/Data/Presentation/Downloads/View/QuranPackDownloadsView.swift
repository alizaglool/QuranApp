//
//  QuranPackDownloadsView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 29/10/2026.
//

import SwiftUI
import Core

struct QuranPackDownloadsView: View {

    @StateObject private var viewModel: QuranPackDownloadsViewModel

    init(coordinator: any QuranPackDownloadsCoordinating) {
        _viewModel = StateObject(wrappedValue: QuranPackDownloadsViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension QuranPackDownloadsView {

    var mainContent: some View {
        VStack(spacing: 0) {
            navBar

            if viewModel.isCatalogEmpty {
                emptyState
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .customBackground(.background)
        .alert(viewModel.confirmation?.title ?? "",
               isPresented: Binding(get: { viewModel.confirmation != nil },
                                    set: { if !$0 { viewModel.cancelConfirmation() } }),
               presenting: viewModel.confirmation) { request in
            Button(request.confirmTitle) {
                viewModel.confirmDownload(request)
            }
            Button(request.cancelTitle, role: .cancel) {
                viewModel.cancelConfirmation()
            }
        } message: { request in
            Text(request.message)
        }
    }

    var navBar: some View {
        HStack(spacing: 10) {
            Button(action: viewModel.onBackTapped) {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .customForeground(.primary)
                    .frame(width: 32, height: 32)
            }

            Text(viewModel.screenTitle)
                .customStyle(.heading3, .onSurface)

            Spacer(minLength: 0)

            if viewModel.isRefreshing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.7)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }
}

// MARK: - Content

private extension QuranPackDownloadsView {

    var content: some View {
        NoIndicatorsScrollView {
            VStack(alignment: .leading, spacing: .big) {
                headerCard

                includedContentCard

                packsCard

                Text(viewModel.offlineNoteTitle)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, .big)
            .padding(.top, .sm)
            .padding(.bottom, .xxxBig)
        }
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            Text(viewModel.headerCaption)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(viewModel.captionTracking)

            HStack(alignment: .firstTextBaseline, spacing: .xSm) {
                Text(viewModel.fullDownloadTitle)
                    .customStyle(.kitab(size: 17, bold: true), .onSurface)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: .xSm)

                stageBadge
            }

            Text(viewModel.fullDownloadDetail)
                .customStyle(.caption1, .onSurfaceVariant)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            progressTrack

            HStack(alignment: .firstTextBaseline, spacing: .xSm) {
                Text(viewModel.progressLabel)
                    .customStyle(.caption2, .onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: .xSm)

                if !viewModel.installedSizeLabel.isEmpty {
                    Text(viewModel.installedSizeLabel)
                        .customStyle(.caption2, .outline)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }

            fullDownloadAction
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .md)
        .padding(.vertical, .md)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }

    @ViewBuilder
    var stageBadge: some View {
        switch viewModel.fullStatus.stage {
        case .notDownloaded:
            EmptyView()

        case .downloading:
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.6)
                .frame(height: 16)

        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .customForeground(.success)

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .customForeground(.error)
        }
    }

    var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ColorStyle.outlineVariant.color.opacity(0.25))

                Capsule()
                    .fill(progressFill)
                    .frame(width: max(0, geo.size.width * viewModel.fullStatus.fraction))
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.25), value: viewModel.fullStatus.fraction)
    }

    var progressFill: Color {
        viewModel.fullStatus.hasFailed ? ColorStyle.error.color : ColorStyle.quickAccentQuran.color
    }

    var fullDownloadAction: some View {
        Button(action: viewModel.onFullDownloadTapped) {
            Text(viewModel.fullDownloadActionTitle)
                .customStyle(.buttonText, viewModel.isFullDownloadActionEnabled ? .onPrimary : .onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .sm)
                .background(
                    Capsule().fill(fullDownloadActionFill)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isFullDownloadActionEnabled)
        .padding(.top, .xxSm)
    }

    var fullDownloadActionFill: Color {
        guard viewModel.isFullDownloadActionEnabled else {
            return ColorStyle.outlineVariant.color.opacity(0.25)
        }

        return ColorStyle.primary.color
    }

    var includedContentCard: some View {
        VStack(alignment: .leading, spacing: .xSm) {
            Text(viewModel.includedContentTitle)
                .customStyle(.caption2, .onSurfaceVariant)
                .tracking(viewModel.captionTracking)

            contentNote(symbol: "checkmark.circle", text: viewModel.includedContentBody, tint: .success)

            contentNote(symbol: "minus.circle", text: viewModel.excludedContentBody, tint: .outline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, .md)
        .padding(.vertical, .md)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }

    func contentNote(symbol: String, text: String, tint: ColorStyle) -> some View {
        HStack(alignment: .top, spacing: .xSm) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .customForeground(tint)
                .frame(width: 16, height: 18)

            Text(text)
                .customStyle(.caption1, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    var packsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Rectangle()
                        .fill(ColorStyle.outlineVariant.color.opacity(0.3))
                        .frame(height: 1)
                }

                QuranPackRow(item: row,
                             state: viewModel.state(for: row),
                             bundledLabel: viewModel.bundledLabel,
                             isWaitingForNetwork: viewModel.isWaitingForNetwork(row),
                             waitingLabel: viewModel.waitingNetworkLabel,
                             onAction: { viewModel.onRowActionTapped(row) })
            }
        }
        .padding(.horizontal, .md)
        .padding(.vertical, .xSm)
        .background(Color.cardSurface)
        .customCornerRadius(.cornerCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerCard)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }
}

// MARK: - States

private extension QuranPackDownloadsView {

    var emptyState: some View {
        VStack(spacing: .sm) {
            Image(systemName: "book.pages")
                .font(.system(size: 42, weight: .light))
                .customForeground(.onSurfaceVariant)

            Text(viewModel.emptyTitle)
                .customStyle(.headline, .onSurface)
                .multilineTextAlignment(.center)

            Text(viewModel.emptyMessage)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, .xxxBig)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
