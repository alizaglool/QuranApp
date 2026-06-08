//
//  SheikhCardView.swift
//  QuranApp
//

import SwiftUI
import Core
import SDWebImageSwiftUI

struct SheikhCardView: View {
    let sheikh: Sheikh

    var body: some View {
        HStack(spacing: 14) {
            avatarView
            infoView
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .customForeground(.subtitle)
                .flipsForRightToLeftLayoutDirection(true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .customFill(.surface)
        )
    }

    private var avatarView: some View {
        WebImage(url: URL(string: sheikh.thumbnailUrl)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Circle()
                .customFill(.container)
                .withShimmerOverlay().redacted(reason: .placeholder)
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
    }

    private var infoView: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(sheikh.name)
                .font(.system(size: 16, weight: .bold))
                .customForeground(.onSurface)
                .lineLimit(1)

            Text(sheikh.channelHandle
                .trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                .uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.hadithGold)
                .lineLimit(1)

            HStack(spacing: 14) {
                Label {
                    Text("\(sheikh.videoCount) \("lessons.lessonsCount".localized)")
                        .font(.system(size: 12))
                        .customForeground(.subtitle)
                } icon: {
                    Image(systemName: "play.circle")
                        .font(.system(size: 12))
                        .customForeground(.subtitle)
                }

                Label {
                    Text(sheikh.formattedSubscriberCount)
                        .font(.system(size: 12))
                        .customForeground(.subtitle)
                } icon: {
                    Image(systemName: "person.2")
                        .font(.system(size: 12))
                        .customForeground(.subtitle)
                }
            }
        }
    }
}
