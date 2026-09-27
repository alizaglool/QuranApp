//
//  HomeFeaturedLessonsSection.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

// MARK: - Section

extension HomeView {

    var featuredLessonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(AppLocalizedKeys.featuredLessons.value)
                    .customStyle(.heading3, .onSurface)

                Spacer()

                Button(AppLocalizedKeys.seeAll.value) {
                    viewModel.onSeeAllLessonsTapped()
                }
                .customStyle(.kitab(size: 12, bold: true), .secondary)
                .tracking(1)
            }
            .padding(.horizontal, .big)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.featuredSheikhs.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            FeaturedSheikhCardSkeleton()
                        }
                    } else {
                        ForEach(viewModel.featuredSheikhs) { sheikh in
                            Button {
                                viewModel.onSeeAllLessonsTapped()
                            } label: {
                                FeaturedSheikhCard(sheikh: sheikh)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, .big)
            }
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
