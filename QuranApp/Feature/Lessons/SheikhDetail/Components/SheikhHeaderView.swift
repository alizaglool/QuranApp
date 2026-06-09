//
//  SheikhHeaderView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct SheikhHeaderView: View {
    let sheikh: Sheikh

    private var heroUrl: URL? {
        let raw = sheikh.bannerImageUrl.isEmpty ? sheikh.thumbnailUrl : sheikh.bannerImageUrl
        return URL(string: raw)
    }

    var body: some View {
        VStack(spacing: 0) {
            heroWithAvatar
            infoSection
        }
    }
}

// MARK: - Hero + Avatar

extension SheikhHeaderView {

    var heroWithAvatar: some View {
        ZStack(alignment: .bottom) {
            heroBackground
            avatarView
                .offset(y: 48)
        }
    }

    var heroBackground: some View {
        WebImage(url: heroUrl) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Rectangle().customFill(.container)
        }
        .frame(maxWidth: .infinity, minHeight: 160, maxHeight: 160)
        .clipped()
        .overlay(Color.black.opacity(0.42))
    }

    var avatarView: some View {
        WebImage(url: URL(string: sheikh.thumbnailUrl)) { image in
            image.resizable()
        } placeholder: {
            Circle()
                .customFill(.container)
                .withShimmerOverlay().redacted(reason: .placeholder)
        }
        .frame(width: 92, height: 92)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 2))
    }
}

// MARK: - Info Section

extension SheikhHeaderView {

    var infoSection: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 56)

            Text(sheikh.name)
                .font(.system(size: 22, weight: .bold))
                .customForeground(.onSurface)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            statsRow

            if !sheikh.channelDescription.isEmpty {
                Text(sheikh.channelDescription)
                    .font(.system(size: 13))
                    .customForeground(.subtitle)
                    .multilineTextAlignment(.center)
//                    .lineLimit(3)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 16)
    }

    var statsRow: some View {
        HStack(spacing: 16) {
            Label(sheikh.formattedSubscriberCount, systemImage: "person.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.hadithGold)

            Label {
                HStack(spacing: 3) {
                    Text("\(sheikh.videoCount)")
                    Text(AppLocalizedKeys.lessonsCount.value)
                }
            } icon: {
                Image(systemName: "play.fill")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color.hadithGold)
            .environment(\.layoutDirection, .leftToRight)
        }
    }
}
