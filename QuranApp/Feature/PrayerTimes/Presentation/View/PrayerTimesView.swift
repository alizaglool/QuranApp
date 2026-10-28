//
//  PrayerTimesView.swift
//  QuranApp
//
//  Created by Ali Zaghloul on 20/10/2026.
//

import SwiftUI
import Combine
import Core

struct PrayerTimesView: View {

    @StateObject private var viewModel: PrayerTimesViewModel
    @StateObject private var qiblaViewModel = QiblaCompassViewModel()

    init(coordinator: any PrayerTimesCoordinating) {
        _viewModel = StateObject(wrappedValue: PrayerTimesViewModel(coordinator: coordinator))
    }

    var body: some View {
        MainView(viewModel: viewModel) {
            mainContent
        }
    }
}

// MARK: - Layout

private extension PrayerTimesView {

    var mainContent: some View {
        VStack(spacing: .no) {
            navBar

            NoIndicatorsScrollView {
                VStack(alignment: .leading, spacing: .big) {
                    if viewModel.hasFailedToLoadPrayerTimes {
                        errorCard
                    } else {
                        compassSection
                        dateBlock
                        scheduleSection
                        otherTimesSection
                        prayedSummaryRow
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
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.screenTitle)

            locationTitleButton

            Spacer(minLength: 0)
        }
        .padding(.horizontal, .big)
        .padding(.vertical, .sm)
    }

    var locationTitleButton: some View {
        Button(action: viewModel.onChangeLocationTapped) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: .xxSm) {
                    Text(viewModel.locationLabel)
                        .customStyle(.heading3, .onSurface)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .customForeground(.onSurfaceVariant)
                }

                Text(viewModel.calculationMethodText)
                    .customStyle(.caption1, .subtitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(viewModel.changeLocationTitle)
    }
}

// MARK: - Compass

private extension PrayerTimesView {

    var compassSection: some View {
        QiblaCompassRing(viewModel: qiblaViewModel)
            .frame(maxWidth: .infinity)
            .onAppear { qiblaViewModel.onAppear() }
            .onDisappear { qiblaViewModel.onDisappear() }
    }
}

// MARK: - Dates

private extension PrayerTimesView {

    var dateBlock: some View {
        VStack(spacing: 2) {
            Text(viewModel.gregorianDateText)
                .customStyle(.kitab(size: 17, bold: true), .onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(viewModel.hijriDateText)
                .customStyle(.caption1, .onSurfaceVariant)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Schedule

private extension PrayerTimesView {

    var scheduleSection: some View {
        Group {
            if viewModel.hasLoadedPrayerTimes {
                PrayerSchedule(viewModel: viewModel)
            } else {
                scheduleSkeleton
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.hasLoadedPrayerTimes)
    }

    var scheduleSkeleton: some View {
        VStack(spacing: .xxSm) {
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: .sm) {
                    RoundedRectangle(cornerRadius: .cornerXxSm)
                        .fill(ColorStyle.outlineVariant.color.opacity(0.5))
                        .frame(width: 90, height: 14)

                    Spacer(minLength: 0)

                    RoundedRectangle(cornerRadius: .cornerXxSm)
                        .fill(ColorStyle.outlineVariant.color.opacity(0.5))
                        .frame(width: 48, height: 14)
                }
                .padding(.horizontal, .md)
                .padding(.vertical, 14)
            }
        }
        .modifier(PrayerListContainer())
    }

    var prayedSummaryRow: some View {
        HStack(spacing: .xxSm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .semibold))
                .customForeground(.primary)

            Text(viewModel.prayedSummary)
                .customStyle(.caption1, .onSurfaceVariant)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - Other Times

private extension PrayerTimesView {

    var otherTimesSection: some View {
        VStack(spacing: .xxSm) {
            otherTimesHeader

            if viewModel.isOtherTimesExpanded {
                ForEach(viewModel.otherRows) { item in
                    PrayerTimeRow(item: item,
                                  nextPrayerCaption: viewModel.nextPrayerLabel,
                                  countdownText: nil,
                                  toggleAccessibilityLabel: "") { }
                }
            }
        }
        .modifier(PrayerListContainer())
        .animation(.easeInOut(duration: 0.22), value: viewModel.isOtherTimesExpanded)
    }

    var otherTimesHeader: some View {
        Button(action: viewModel.toggleOtherTimes) {
            HStack(spacing: .xSm) {
                Text(viewModel.otherTimesTitle)
                    .customStyle(.subheadline, .onSurface)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: viewModel.isOtherTimesExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .customForeground(.onSurfaceVariant)
            }
            .padding(.horizontal, .md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Error

private extension PrayerTimesView {

    var errorCard: some View {
        VStack(alignment: .leading, spacing: .sm) {
            HStack(spacing: .xSm) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 20))
                    .customForeground(.error)

                Text(viewModel.errorTitle)
                    .customStyle(.bodySmall, .onSurfaceVariant)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: viewModel.onRetryTapped) {
                Text(viewModel.retryTitle)
                    .customStyle(.buttonText, .primary)
                    .padding(.vertical, .xSm)
                    .padding(.horizontal, .md)
                    .background(ColorStyle.primary.color.opacity(0.08))
                    .customCornerRadius(.cornerMd)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.big)
        .background(ColorStyle.surfaceContainerLow.color)
        .customCornerRadius(.cornerXxl)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl, style: .continuous)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - List Container

private struct PrayerListContainer: ViewModifier {

    func body(content: Content) -> some View {
        content
            .padding(.xSm)
            .frame(maxWidth: .infinity)
            .background(ColorStyle.surfaceContainerLow.color)
            .customCornerRadius(.cornerLg)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerLg, style: .continuous)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
    }
}

// MARK: - Schedule List

private struct PrayerSchedule: View {

    @ObservedObject var viewModel: PrayerTimesViewModel

    @State private var now = Date()
    @State private var ticker = Timer.publish(every: 1, on: .main, in: .common)
    @State private var tickerConnection: Cancellable?

    var body: some View {
        VStack(spacing: .xxSm) {
            ForEach(viewModel.rows) { item in
                PrayerTimeRow(item: item,
                              nextPrayerCaption: viewModel.nextPrayerLabel,
                              countdownText: countdownText(for: item),
                              toggleAccessibilityLabel: viewModel.prayerToggleAccessibilityLabel(for: item)) {
                    viewModel.togglePrayed(for: item)
                }
            }
        }
        .modifier(PrayerListContainer())
        .onReceive(ticker) { date in
            now = date
            viewModel.onCountdownTick()
        }
        .onAppear {
            now = Date()
            viewModel.onCountdownTick()
            tickerConnection = ticker.connect()
        }
        .onDisappear {
            tickerConnection?.cancel()
            tickerConnection = nil
        }
    }

    private func countdownText(for item: PrayerTimeRowItem) -> String? {
        guard item.isNextPrayer else { return nil }
        return viewModel.countdownText(at: now)
    }
}
