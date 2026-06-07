//
//  HomeFeaturedLessonsSection.swift
//  QuranApp
//

import SwiftUI
import Core

// MARK: - Section

extension HomeView {

    var featuredLessonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(AppLocalizedKeys.featuredLessons.value)
                    .customStyle(.heading3, .onSurface)

                Spacer()

                Button(AppLocalizedKeys.seeAll.value) {}
                    .customStyle(.kitab(size: 12, bold: true), .secondary)
                    .tracking(1)
            }
            .padding(.horizontal, .big)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.featuredLessons) { lesson in
                        FeaturedLessonCard(lesson: lesson)
                    }
                }
                .padding(.horizontal, .big)
            }
        }
    }
}

// MARK: - Card

struct FeaturedLessonCard: View {
    let lesson: FeaturedLesson

    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Color.surfaceContainerHigh)
                .frame(width: 72, height: 72)
                .overlay(
                    Circle()
                        .stroke(ColorStyle.secondary.color.opacity(0.2), lineWidth: 2)
                )
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .customForeground(.onSurfaceVariant)
                )

            Text(lesson.name)
                .customStyle(.kitab(size: 11, bold: true), .onSurface)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
    }
}
