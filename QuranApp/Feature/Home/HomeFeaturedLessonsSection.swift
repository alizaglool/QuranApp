//
//  HomeFeaturedLessonsSection.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

// MARK: - Section

struct HomeFeaturedLessonsSection: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader

            if viewModel.featuredSheikhsLoading {
                FeaturedSheikhSkeletonRow()
            } else if viewModel.featuredSheikhs.isEmpty {
                HomeFeaturedEmptyRow(message: viewModel.featuredLessonsErrorTitle,
                                     retryTitle: viewModel.retryTitle,
                                     onRetry: { viewModel.onRetryFeaturedSheikhs() })
                    .padding(.horizontal, .big)
            } else {
                lessonsRow
            }
        }
    }
}

// MARK: - Layout

private extension HomeFeaturedLessonsSection {

    var sectionHeader: some View {
        HStack {
            Text(viewModel.featuredLessonsTitle)
                .customStyle(.heading3, .onSurface)

            Spacer()

            Button(viewModel.seeAllTitle) {
                viewModel.onSeeAllLessonsTapped()
            }
            .customStyle(.kitab(size: 12, bold: true), .secondary)
            .tracking(viewModel.seeAllTracking)
        }
        .padding(.horizontal, .big)
    }

    var lessonsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.featuredSheikhs) { sheikh in
                    Button {
                        viewModel.onSheikhTapped(sheikh)
                    } label: {
                        FeaturedSheikhCard(sheikh: sheikh)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - Card

struct FeaturedSheikhCard: View {
    let sheikh: Sheikh

    var body: some View {
        VStack(spacing: 10) {
            WebImage(url: URL(string: sheikh.thumbnailUrl)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.surfaceContainerHigh)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .customForeground(.onSurfaceVariant)
                    )
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(ColorStyle.secondary.color.opacity(0.2), lineWidth: 2)
            )

            Text(sheikh.name)
                .customStyle(.kitab(size: 11, bold: true), .onSurface)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
    }
}

// MARK: - Skeleton

struct FeaturedSheikhCardSkeleton: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.surfaceContainerHigh)
                .frame(width: 72, height: 72)
                .opacity(pulse ? 0.4 : 0.7)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.surfaceContainerHigh)
                .frame(width: 60, height: 10)
                .opacity(pulse ? 0.4 : 0.7)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Skeleton Row

struct FeaturedSheikhSkeletonRow: View {

    private static let placeholderCount = 5

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<Self.placeholderCount, id: \.self) { _ in
                    FeaturedSheikhCardSkeleton()
                }
            }
            .padding(.horizontal, .big)
        }
    }
}

// MARK: - Empty Row

struct HomeFeaturedEmptyRow: View {

    let message: String
    let retryTitle: String
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: .sm) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 20))
                .customForeground(.onSurfaceVariant)

            Text(message)
                .customStyle(.bodySmall, .onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: .xSm)

            Button(action: onRetry) {
                Text(retryTitle)
                    .customStyle(.buttonText, .primary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.big)
        .background(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .fill(Color.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerXxl)
                .stroke(ColorStyle.cardBorder.color, lineWidth: 1)
        )
    }
}
